from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.deps import get_current_user
from ..db.session import get_db
from ..models.partner import PartnerProfile, PartnerStatus
from ..models.user import User
from ..schemas.partner import (
    PartnerApplicationCreate,
    PartnerApplicationResponse,
    UploadUrlRequest,
    UploadUrlResponse,
)
from ..services.storage_service import build_object_key, presigned_get_url, presigned_put_url

router = APIRouter(prefix="/partners", tags=["partners"])

_DOC_FIELD = {
    "id_card": "doc_id_card_url",
    "business_license": "doc_business_license_url",
    "shop_photo": "doc_shop_photo_url",
}


async def application_to_response(application: PartnerProfile) -> PartnerApplicationResponse:
    """The doc_*_url columns actually hold storage *keys*, not public URLs
    (the bucket is private since these are real ID documents) -- this
    signs a fresh short-lived GET URL for each one at read time.
    """
    data = PartnerApplicationResponse.model_validate(application).model_dump()
    for field in ("doc_id_card_url", "doc_business_license_url", "doc_shop_photo_url"):
        key = getattr(application, field)
        if key:
            data[field] = await presigned_get_url(key)
    return PartnerApplicationResponse(**data)


@router.get("/applications/me", response_model=PartnerApplicationResponse)
async def get_my_application(
    user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> PartnerApplicationResponse:
    application = await db.scalar(select(PartnerProfile).where(PartnerProfile.user_id == user.id))
    if application is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No partner application on file")
    return await application_to_response(application)


@router.post("/applications", response_model=PartnerApplicationResponse, status_code=status.HTTP_201_CREATED)
async def submit_application(
    payload: PartnerApplicationCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> PartnerApplicationResponse:
    existing = await db.scalar(select(PartnerProfile).where(PartnerProfile.user_id == user.id))
    if existing is not None and existing.status != PartnerStatus.rejected:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You already have a partner application in progress",
        )

    if existing is not None:
        for field, value in payload.model_dump().items():
            setattr(existing, field, value)
        existing.status = PartnerStatus.pending
        existing.reviewed_by = None
        existing.reviewed_at = None
        existing.rejection_reason = None
        application = existing
    else:
        application = PartnerProfile(user_id=user.id, **payload.model_dump())
        db.add(application)

    await db.commit()
    await db.refresh(application)
    return await application_to_response(application)


@router.post("/applications/me/upload-url", response_model=UploadUrlResponse)
async def create_upload_url(
    payload: UploadUrlRequest, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> UploadUrlResponse:
    application = await db.scalar(select(PartnerProfile).where(PartnerProfile.user_id == user.id))
    if application is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Submit your application first")

    key = build_object_key(f"partner-docs/{payload.doc_type}", user.id, payload.filename)
    upload_url = await presigned_put_url(key, content_type=payload.content_type)

    setattr(application, _DOC_FIELD[payload.doc_type], key)
    await db.commit()

    return UploadUrlResponse(upload_url=upload_url, public_url=await presigned_get_url(key))
