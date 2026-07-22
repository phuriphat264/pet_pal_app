import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, Field

from ..models.booking import BookingPaymentStatus, BookingStatus


class BookingCreate(BaseModel):
    hotel_id: uuid.UUID
    room_id: uuid.UUID | None = None
    pet_id: uuid.UUID | None = None
    check_in: date
    check_out: date
    payment_method: str | None = None
    matching_prompt: str | None = None


class BookingStatusUpdate(BaseModel):
    status: BookingStatus


class BookingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    customer_id: uuid.UUID
    hotel_id: uuid.UUID
    room_id: uuid.UUID | None
    pet_id: uuid.UUID | None
    check_in: date
    check_out: date
    nights: int
    total_price: float = Field(..., description="Total price for the stay")
    payment_method: str | None
    matching_prompt: str | None
    status: BookingStatus
    payment_status: BookingPaymentStatus


class HotelBookingResponse(BookingResponse):
    customer_name: str | None = None
    pet_name: str | None = None
