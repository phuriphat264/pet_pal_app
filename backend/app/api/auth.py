from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.rate_limit import auth_rate_limit
from ..core.security import (
    InvalidTokenError,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from ..db.session import get_db
from ..models.user import User
from ..schemas.auth import (
    FacebookLoginRequest,
    GoogleLoginRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
)
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
