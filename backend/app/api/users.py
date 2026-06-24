from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.deps import get_current_user, require_admin
from ..db.session import get_db
from ..models.user import User, UserRole
from ..schemas.auth import UserResponse

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
async def get_me(user: User = Depends(get_current_user)) -> User:
    return user


@router.get("", response_model=list[UserResponse], dependencies=[Depends(require_admin)])
async def list_users(
    role: UserRole | None = Query(default=None), db: AsyncSession = Depends(get_db)
) -> list[User]:
    stmt = select(User).order_by(User.created_at.desc())
    if role is not None:
        stmt = stmt.where(User.role == role)
    result = await db.scalars(stmt)
    return list(result.all())
