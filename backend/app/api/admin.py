import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.deps import require_admin
from ..core.security import hash_password
from ..db.session import get_db
from ..models.partner import PartnerProfile, PartnerStatus
from ..models.user import User, UserRole
from ..schemas.auth import RoleUpdateRequest, TechnicianCreateRequest, UserResponse
from ..schemas.partner import PartnerApplicationResponse, RejectRequest
from .partners import application_to_response

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])

# Roles an admin may assign via /admin/users/{id}/role. Deliberately excludes
# "admin" -- promoting someone to admin through this generic endpoint would
# be a privilege-escalation footgun; that should stay a deliberate, separate
# action (currently: direct DB/seed only).
_ASSIGNABLE_ROLES = {UserRole.customer, UserRole.technician}


@router.post("/technicians", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_technician(
    payload: TechnicianCreateRequest, db: AsyncSession = Depends(get_db)
) -> User:
    existing = await db.scalar(select(User).where(User.email == payload.email))
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email is already registered")

    technician = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        name=payload.name,
        phone=payload.phone,
        role=UserRole.technician,
    )
    db.add(technician)
    await db.commit()
    await db.refresh(technician)
    return technician


@router.patch("/users/{user_id}/role", response_model=UserResponse)
async def update_user_role(
    user_id: uuid.UUID, payload: RoleUpdateRequest, db: AsyncSession = Depends(get_db)
) -> User:
    if payload.role not in _ASSIGNABLE_ROLES:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Role cannot be assigned via this endpoint")

    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.role == UserRole.admin:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot change an admin's role here")

    user.role = payload.role
    await db.commit()
    await db.refresh(user)
    return user


@router.get("/partner-applications", response_model=list[PartnerApplicationResponse])
async def list_partner_applications(
    status_filter: PartnerStatus | None = Query(default=None, alias="status"),
    db: AsyncSession = Depends(get_db),
) -> list[PartnerApplicationResponse]:
    stmt = select(PartnerProfile).order_by(PartnerProfile.created_at.desc())
    if status_filter is not None:
        stmt = stmt.where(PartnerProfile.status == status_filter)
    result = await db.scalars(stmt)
    return [await application_to_response(a) for a in result.all()]


async def _get_application(application_id: uuid.UUID, db: AsyncSession) -> PartnerProfile:
    application = await db.get(PartnerProfile, application_id)
    if application is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found")
    return application


@router.post("/partner-applications/{application_id}/approve", response_model=PartnerApplicationResponse)
async def approve_application(
    application_id: uuid.UUID,
    admin_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> PartnerApplicationResponse:
    application = await _get_application(application_id, db)
    application.status = PartnerStatus.approved
    application.reviewed_by = admin_user.id
    application.reviewed_at = datetime.now(timezone.utc)
    application.rejection_reason = None
    await db.commit()
    await db.refresh(application)
    return await application_to_response(application)


@router.post("/partner-applications/{application_id}/reject", response_model=PartnerApplicationResponse)
async def reject_application(
    application_id: uuid.UUID,
    payload: RejectRequest,
    admin_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> PartnerApplicationResponse:
    application = await _get_application(application_id, db)
    application.status = PartnerStatus.rejected
    application.reviewed_by = admin_user.id
    application.reviewed_at = datetime.now(timezone.utc)
    application.rejection_reason = payload.reason
    await db.commit()
    await db.refresh(application)
    return await application_to_response(application)
