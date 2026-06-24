import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.deps import require_admin
from ..db.session import get_db
from ..models.partner import PartnerProfile, PartnerStatus
from ..models.user import User
from ..schemas.partner import PartnerApplicationResponse, RejectRequest
from .partners import application_to_response

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])


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
