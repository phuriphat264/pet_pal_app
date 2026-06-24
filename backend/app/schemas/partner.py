import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict

from ..models.partner import PartnerStatus

DocType = Literal["id_card", "business_license", "shop_photo"]


class PartnerApplicationCreate(BaseModel):
    shop_name: str
    service_type: str
    address: str
    phone: str
    description: str | None = None


class PartnerApplicationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    shop_name: str
    service_type: str
    address: str
    phone: str
    description: str | None
    status: PartnerStatus
    doc_id_card_url: str | None
    doc_business_license_url: str | None
    doc_shop_photo_url: str | None
    reviewed_at: datetime | None
    rejection_reason: str | None


class UploadUrlRequest(BaseModel):
    doc_type: DocType
    filename: str
    content_type: str = "application/octet-stream"


class UploadUrlResponse(BaseModel):
    upload_url: str
    public_url: str


class RejectRequest(BaseModel):
    reason: str
