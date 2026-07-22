import enum
import uuid

from sqlalchemy import Enum, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..db.base import Base, TimestampMixin, UUIDPkMixin


class PaymentMethod(str, enum.Enum):
    card = "card"
    promptpay = "promptpay"


class PaymentStatus(str, enum.Enum):
    pending = "pending"
    successful = "successful"
    failed = "failed"
    expired = "expired"
    refunded = "refunded"


class Payment(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "payments"

    booking_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("bookings.id"), nullable=False)
    # Smallest currency unit (satang), matching Omise's amount convention.
    amount: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(8), default="thb", nullable=False)
    method: Mapped[PaymentMethod] = mapped_column(Enum(PaymentMethod, name="payment_method"), nullable=False)
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, name="payment_status"), default=PaymentStatus.pending, nullable=False
    )
    provider_charge_id: Mapped[str | None] = mapped_column(String(64), index=True, nullable=True)
    # PromptPay QR code image, shown to the customer while the charge is
    # still "pending" -- populated from Omise's source.scannable_code.
    qr_image_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    failure_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Full Omise charge object, kept for support/debugging -- Omise's own
    # dashboard is the source of truth for the ledger, this is just a cache.
    raw_response: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    booking = relationship("Booking", back_populates="payments")
