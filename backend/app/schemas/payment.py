import uuid
from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict

from ..models.payment import PaymentMethod, PaymentStatus


class PaymentCreateRequest(BaseModel):
    method: Literal["card", "promptpay"]
    card_token: str | None = None


class PaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    booking_id: uuid.UUID
    amount: int
    currency: str
    method: PaymentMethod
    status: PaymentStatus
    qr_image_url: str | None
    failure_message: str | None


class AdminPaymentResponse(PaymentResponse):
    created_at: datetime
    customer_name: str | None = None
    hotel_name: str | None = None


class FinanceReportDay(BaseModel):
    day: date
    revenue_thb: float
    successful_count: int


class FinanceReportResponse(BaseModel):
    period_days: int
    total_revenue_thb: float
    successful_count: int
    pending_count: int
    failed_count: int
    refunded_count: int
    daily: list[FinanceReportDay]
