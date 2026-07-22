import uuid

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.deps import get_current_user
from ..db.session import get_db
from ..models.booking import Booking, BookingPaymentStatus
from ..models.payment import Payment, PaymentMethod, PaymentStatus
from ..models.user import User
from ..schemas.payment import PaymentCreateRequest, PaymentResponse
from ..services import omise_client

router = APIRouter(tags=["payments"])

# Omise's charge.status values that map onto our own PaymentStatus enum.
_OMISE_STATUS_MAP = {
    "successful": PaymentStatus.successful,
    "failed": PaymentStatus.failed,
    "expired": PaymentStatus.expired,
    "pending": PaymentStatus.pending,
    "reversed": PaymentStatus.refunded,
}

# Booking.payment_status only cares about the customer-facing outcome, not
# every intermediate Omise charge state.
_BOOKING_PAYMENT_STATUS_MAP = {
    PaymentStatus.successful: BookingPaymentStatus.paid,
    PaymentStatus.failed: BookingPaymentStatus.failed,
    PaymentStatus.expired: BookingPaymentStatus.failed,
    PaymentStatus.pending: BookingPaymentStatus.pending,
    PaymentStatus.refunded: BookingPaymentStatus.failed,
}


async def _get_owned_booking(booking_id: uuid.UUID, user: User, db: AsyncSession) -> Booking:
    booking = await db.get(Booking, booking_id)
    if booking is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    if booking.customer_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your booking")
    return booking


@router.post(
    "/bookings/{booking_id}/payments", response_model=PaymentResponse, status_code=status.HTTP_201_CREATED
)
async def create_payment(
    booking_id: uuid.UUID,
    payload: PaymentCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Payment:
    booking = await _get_owned_booking(booking_id, user, db)
    if booking.payment_status == BookingPaymentStatus.paid:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Booking is already paid")

    amount = int(round(float(booking.total_price) * 100))
    description = f"PetPal booking {booking.id}"

    if payload.method == "card":
        if not payload.card_token:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="card_token is required")
        charge = await omise_client.create_card_charge(amount, "thb", payload.card_token, description)
    else:
        charge = await omise_client.create_promptpay_charge(amount, "thb", description)

    charge_status = _OMISE_STATUS_MAP.get(charge["status"], PaymentStatus.pending)
    payment = Payment(
        booking_id=booking.id,
        amount=amount,
        currency="thb",
        method=PaymentMethod.card if payload.method == "card" else PaymentMethod.promptpay,
        status=charge_status,
        provider_charge_id=charge["id"],
        qr_image_url=(charge.get("source") or {}).get("scannable_code", {}).get("image", {}).get("download_uri"),
        failure_message=charge.get("failure_message"),
        raw_response=charge,
    )
    db.add(payment)
    booking.payment_status = _BOOKING_PAYMENT_STATUS_MAP[charge_status]
    await db.commit()
    await db.refresh(payment)
    return payment


@router.get("/bookings/{booking_id}/payments/latest", response_model=PaymentResponse)
async def get_latest_payment(
    booking_id: uuid.UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> Payment:
    await _get_owned_booking(booking_id, user, db)
    payment = await db.scalar(
        select(Payment).where(Payment.booking_id == booking_id).order_by(Payment.created_at.desc())
    )
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No payment found for this booking")
    return payment


@router.post("/payments/webhook/omise", status_code=status.HTTP_200_OK)
async def omise_webhook(request: Request, db: AsyncSession = Depends(get_db)) -> dict:
    # Omise doesn't sign webhook payloads, so the body can't be trusted as-is --
    # pull out the charge id and re-fetch the authoritative state directly from
    # Omise's API before touching anything.
    body = await request.json()
    charge_id = (body.get("data") or {}).get("id")
    if not charge_id:
        return {"status": "ignored"}

    payment = await db.scalar(select(Payment).where(Payment.provider_charge_id == charge_id))
    if payment is None:
        return {"status": "ignored"}

    charge = await omise_client.retrieve_charge(charge_id)
    charge_status = _OMISE_STATUS_MAP.get(charge["status"], payment.status)

    payment.status = charge_status
    payment.failure_message = charge.get("failure_message")
    payment.raw_response = charge
    booking = await db.get(Booking, payment.booking_id)
    if booking is not None:
        booking.payment_status = _BOOKING_PAYMENT_STATUS_MAP[charge_status]
    await db.commit()
    return {"status": "ok"}
