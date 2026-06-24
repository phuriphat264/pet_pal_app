import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..core.deps import get_current_user
from ..db.session import get_db
from ..models.booking import Booking
from ..models.hotel import Hotel, HotelRoom
from ..models.partner import PartnerProfile
from ..models.user import User, UserRole
from ..schemas.booking import BookingCreate, BookingResponse, BookingStatusUpdate, HotelBookingResponse

router = APIRouter(prefix="/bookings", tags=["bookings"])


@router.post("", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
async def create_booking(
    payload: BookingCreate, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> Booking:
    hotel = await db.get(Hotel, payload.hotel_id)
    if hotel is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hotel not found")

    nights = max((payload.check_out - payload.check_in).days, 1)
    surcharge = 0
    if payload.room_id is not None:
        room = await db.scalar(
            select(HotelRoom).where(HotelRoom.id == payload.room_id, HotelRoom.hotel_id == hotel.id)
        )
        if room is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")
        surcharge = room.price_surcharge

    total_price = (hotel.base_price + surcharge) * nights

    booking = Booking(
        customer_id=user.id,
        hotel_id=hotel.id,
        room_id=payload.room_id,
        pet_id=payload.pet_id,
        check_in=payload.check_in,
        check_out=payload.check_out,
        nights=nights,
        total_price=total_price,
        payment_method=payload.payment_method,
        matching_prompt=payload.matching_prompt,
    )
    db.add(booking)
    await db.commit()
    await db.refresh(booking)
    return booking


@router.get("/me", response_model=list[BookingResponse])
async def list_my_bookings(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)) -> list[Booking]:
    result = await db.scalars(
        select(Booking).where(Booking.customer_id == user.id).order_by(Booking.created_at.desc())
    )
    return list(result.all())


async def _assert_partner_owns_hotel(hotel_id: uuid.UUID, user: User, db: AsyncSession) -> None:
    if user.role == UserRole.admin:
        return
    partner = await db.scalar(select(PartnerProfile).where(PartnerProfile.user_id == user.id))
    hotel = await db.get(Hotel, hotel_id)
    if partner is None or hotel is None or hotel.partner_id != partner.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your hotel")


@router.get("/hotel/{hotel_id}", response_model=list[HotelBookingResponse])
async def list_hotel_bookings(
    hotel_id: uuid.UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> list[HotelBookingResponse]:
    await _assert_partner_owns_hotel(hotel_id, user, db)
    result = await db.scalars(
        select(Booking)
        .where(Booking.hotel_id == hotel_id)
        .options(selectinload(Booking.customer), selectinload(Booking.pet))
        .order_by(Booking.created_at.desc())
    )
    return [
        HotelBookingResponse(
            **BookingResponse.model_validate(b).model_dump(),
            customer_name=b.customer.name if b.customer else None,
            pet_name=b.pet.name if b.pet else None,
        )
        for b in result.all()
    ]


@router.patch("/{booking_id}/status", response_model=BookingResponse)
async def update_booking_status(
    booking_id: uuid.UUID,
    payload: BookingStatusUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Booking:
    booking = await db.get(Booking, booking_id)
    if booking is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    await _assert_partner_owns_hotel(booking.hotel_id, user, db)
    booking.status = payload.status
    await db.commit()
    await db.refresh(booking)
    return booking
