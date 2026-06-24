import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..db.base import Base, TimestampMixin, UUIDPkMixin


class PartnerStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"


class PartnerProfile(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "partner_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), unique=True, nullable=False
    )
    shop_name: Mapped[str] = mapped_column(String(255), nullable=False)
    service_type: Mapped[str] = mapped_column(String(64), nullable=False)
    address: Mapped[str] = mapped_column(Text, nullable=False)
    phone: Mapped[str] = mapped_column(String(32), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    status: Mapped[PartnerStatus] = mapped_column(
        Enum(PartnerStatus, name="partner_status"), default=PartnerStatus.pending, nullable=False
    )
    doc_id_card_url: Mapped[str | None] = mapped_column(String(512))
    doc_business_license_url: Mapped[str | None] = mapped_column(String(512))
    doc_shop_photo_url: Mapped[str | None] = mapped_column(String(512))
    reviewed_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    rejection_reason: Mapped[str | None] = mapped_column(Text)

    user = relationship("User", back_populates="partner_profile", foreign_keys=[user_id])
    hotels = relationship("Hotel", back_populates="partner", cascade="all, delete-orphan")
