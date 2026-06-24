from collections.abc import Callable

from fastapi import Depends, HTTPException, WebSocket, WebSocketException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.session import get_db
from ..models.user import User, UserRole
from .security import InvalidTokenError, decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)


async def get_current_user(
    token: str | None = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if token is None:
        raise credentials_exception

    try:
        user_id = decode_token(token, expected_type="access")
    except InvalidTokenError as exc:
        raise credentials_exception from exc

    user = await db.get(User, user_id)
    if user is None:
        raise credentials_exception
    return user


async def get_current_user_ws(websocket: WebSocket, db: AsyncSession = Depends(get_db)) -> User:
    """WebSocket equivalent of get_current_user. Browsers/clients can't always
    set custom headers on the WS upgrade request, so the access token travels
    as a query param instead (?token=...).
    """
    token = websocket.query_params.get("token")
    if token is None:
        raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Missing token")
    try:
        user_id = decode_token(token, expected_type="access")
    except InvalidTokenError as exc:
        raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token") from exc

    user = await db.get(User, user_id)
    if user is None:
        raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
    return user


def require_roles(*roles: UserRole) -> Callable:
    async def _checker(user: User = Depends(get_current_user)) -> User:
        if user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
        return user

    return _checker


require_admin = require_roles(UserRole.admin)
require_technician = require_roles(UserRole.technician, UserRole.admin)
