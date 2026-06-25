from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.deps import get_current_user
from ..core.rate_limit import auth_rate_limit
from ..core.security import (
    PASSWORD_RESET_TOKEN_EXPIRE_MINUTES,
    InvalidTokenError,
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_password_reset_token,
    hash_password,
    hash_reset_token,
    verify_password,
)
from ..db.session import get_db
from ..models.user import User
from ..schemas.auth import (
    FacebookLoginRequest,
    ForgotPasswordRequest,
    GoogleLoginRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    SetPasswordRequest,
    TokenResponse,
)
from ..services.email_service import send_password_reset_email
from ..services.oauth_service import (
    OAuthVerificationError,
    verify_facebook_access_token,
    verify_google_id_token,
)

router = APIRouter(prefix="/auth", tags=["auth"], dependencies=[Depends(auth_rate_limit)])


def _tokens_for(user: User) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


async def _get_or_create_oauth_user(db: AsyncSession, *, email: str, name: str, provider: str) -> User:
    user = await db.scalar(select(User).where(User.email == email))
    if user is not None:
        return user

    user = User(email=email, name=name, password_hash=None, oauth_provider=provider)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    existing = await db.scalar(select(User).where(User.email == payload.email))
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email is already registered")

    user = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        name=payload.name,
        phone=payload.phone,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return _tokens_for(user)


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    user = await db.scalar(select(User).where(User.email == payload.email))
    if user is None or user.password_hash is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    return _tokens_for(user)


@router.post("/google", response_model=TokenResponse)
async def login_with_google(payload: GoogleLoginRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    try:
        profile = verify_google_id_token(payload.id_token)
    except OAuthVerificationError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc

    user = await _get_or_create_oauth_user(db, email=profile["email"], name=profile["name"], provider="google")
    return _tokens_for(user)


@router.post("/facebook", response_model=TokenResponse)
async def login_with_facebook(payload: FacebookLoginRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    try:
        profile = await verify_facebook_access_token(payload.access_token)
    except OAuthVerificationError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc

    user = await _get_or_create_oauth_user(db, email=profile["email"], name=profile["name"], provider="facebook")
    return _tokens_for(user)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(payload: RefreshRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    try:
        user_id = decode_token(payload.refresh_token, expected_type="refresh")
    except InvalidTokenError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token") from exc

    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")
    return _tokens_for(user)


_GENERIC_FORGOT_PASSWORD_MESSAGE = "If an account with that email exists, we've sent a password reset code to it."


@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)) -> dict:
    # Always returns the same generic message whether or not the account
    # exists -- otherwise this endpoint becomes a way to check which emails
    # are registered.
    user = await db.scalar(select(User).where(User.email == payload.email))
    if user is not None:
        raw_token, token_hash = generate_password_reset_token()
        user.password_reset_token_hash = token_hash
        user.password_reset_expires_at = datetime.now(timezone.utc) + timedelta(
            minutes=PASSWORD_RESET_TOKEN_EXPIRE_MINUTES
        )
        await db.commit()
        await send_password_reset_email(user.email, raw_token)
    return {"message": _GENERIC_FORGOT_PASSWORD_MESSAGE}


@router.post("/reset-password", status_code=status.HTTP_200_OK)
async def reset_password(payload: ResetPasswordRequest, db: AsyncSession = Depends(get_db)) -> dict:
    token_hash = hash_reset_token(payload.token)
    user = await db.scalar(select(User).where(User.password_reset_token_hash == token_hash))
    now = datetime.now(timezone.utc)
    if user is None or user.password_reset_expires_at is None or user.password_reset_expires_at < now:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired reset code")

    user.password_hash = hash_password(payload.new_password)
    user.password_reset_token_hash = None
    user.password_reset_expires_at = None
    await db.commit()
    return {"message": "Password has been reset. You can now log in."}


@router.post("/set-password", status_code=status.HTTP_200_OK)
async def set_password(
    payload: SetPasswordRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    # Accounts created via Google/Facebook start with password_hash=None, so
    # they have no current password to confirm yet -- this is how those
    # users opt into also using the email/password form.
    if user.password_hash is not None:
        if payload.current_password is None or not verify_password(payload.current_password, user.password_hash):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Current password is incorrect")

    user.password_hash = hash_password(payload.new_password)
    await db.commit()
    return {"message": "Password has been set."}
