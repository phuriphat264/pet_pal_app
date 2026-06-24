import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..core.deps import get_current_user
from ..db.session import get_db
from ..models.hotel import Hotel, HotelRoom
from ..models.partner import PartnerProfile, PartnerStatus
from ..models.user import User, UserRole
from ..schemas.hotel import (
    HotelCreate,
    HotelListItem,
    HotelResponse,
    HotelRoomCreate,
    HotelRoomResponse,
    HotelRoomUpdate,
    HotelUpdate,
)
from ..services.embedding_service import embed_hotel_text

router = APIRouter(prefix="/hotels", tags=["hotels"])

_HOTEL_LOAD_OPTS = (selectinload(Hotel.images), selectinload(Hotel.rooms))


async def _get_or_create_partner_profile(user: User, db: AsyncSession) -> PartnerProfile:
    partner = await db.scalar(select(PartnerProfile).where(PartnerProfile.user_id == user.id))
    if partner is None or partner.status != PartnerStatus.approved:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You need an approved partner profile to manage hotels",
        )
    return partner


async def _get_hotel_for_management(hotel_id: uuid.UUID, user: User, db: AsyncSession) -> Hotel:
    hotel = await db.scalar(select(Hotel).where(Hotel.id == hotel_id).options(*_HOTEL_LOAD_OPTS))
    if hotel is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hotel not found")
    if user.role == UserRole.admin:
        return hotel
    partner = await _get_or_create_partner_profile(user, db)
    if hotel.partner_id != partner.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your hotel")
    return hotel


def _set_embedding(hotel: Hotel) -> None:
    hotel.embedding = embed_hotel_text(
        name=hotel.name,
        description=hotel.description or "",
        tags=hotel.tags,
        ai_tags=hotel.ai_tags,
    )


@router.get("", response_model=list[HotelListItem])
async def list_hotels(
    available_only: bool = Query(default=True),
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> list[Hotel]:
    stmt = select(Hotel).options(selectinload(Hotel.images)).order_by(Hotel.rating.desc())
    if available_only:
        stmt = stmt.where(Hotel.available.is_(True))
    stmt = stmt.offset(offset).limit(limit)
    result = await db.scalars(stmt)
    return list(result.all())


@router.get("/mine", response_model=HotelResponse)
async def get_my_hotel(
    user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> Hotel:
    partner = await _get_or_create_partner_profile(user, db)
    hotel = await db.scalar(select(Hotel).where(Hotel.partner_id == partner.id).options(*_HOTEL_LOAD_OPTS))
    if hotel is not None:
        return hotel

    hotel = Hotel(
        partner_id=partner.id,
        name=partner.shop_name,
        location=partner.address,
        service_type=partner.service_type,
        description=partner.description,
        available=True,
    )
    _set_embedding(hotel)
    db.add(hotel)
    await db.commit()
    await db.refresh(hotel, attribute_names=["images", "rooms"])
    return hotel


@router.get("/{hotel_id}", response_model=HotelResponse)
async def get_hotel(hotel_id: uuid.UUID, db: AsyncSession = Depends(get_db)) -> Hotel:
    hotel = await db.scalar(select(Hotel).where(Hotel.id == hotel_id).options(*_HOTEL_LOAD_OPTS))
    if hotel is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hotel not found")
    return hotel


@router.post("", response_model=HotelResponse, status_code=status.HTTP_201_CREATED)
async def create_hotel(
    payload: HotelCreate, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> Hotel:
    partner_id = None
    if user.role != UserRole.admin:
        partner = await _get_or_create_partner_profile(user, db)
        partner_id = partner.id
    hotel = Hotel(partner_id=partner_id, **payload.model_dump())
    _set_embedding(hotel)
    db.add(hotel)
    await db.commit()
    await db.refresh(hotel, attribute_names=["images", "rooms"])
    return hotel


@router.patch("/{hotel_id}", response_model=HotelResponse)
async def update_hotel(
    hotel_id: uuid.UUID,
    payload: HotelUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Hotel:
    hotel = await _get_hotel_for_management(hotel_id, user, db)
    changed_text = False
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(hotel, field, value)
        if field in {"name", "description", "tags", "ai_tags"}:
            changed_text = True
    if changed_text:
        _set_embedding(hotel)
    await db.commit()
    await db.refresh(hotel, attribute_names=["images", "rooms"])
    return hotel


@router.post("/{hotel_id}/rooms", response_model=HotelRoomResponse, status_code=status.HTTP_201_CREATED)
async def add_room(
    hotel_id: uuid.UUID,
    payload: HotelRoomCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> HotelRoom:
    await _get_hotel_for_management(hotel_id, user, db)
    room = HotelRoom(hotel_id=hotel_id, **payload.model_dump())
    db.add(room)
    await db.commit()
    await db.refresh(room)
    return room


@router.patch("/{hotel_id}/rooms/{room_id}", response_model=HotelRoomResponse)
async def update_room(
    hotel_id: uuid.UUID,
    room_id: uuid.UUID,
    payload: HotelRoomUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> HotelRoom:
    await _get_hotel_for_management(hotel_id, user, db)
    room = await db.scalar(select(HotelRoom).where(HotelRoom.id == room_id, HotelRoom.hotel_id == hotel_id))
    if room is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(room, field, value)
    await db.commit()
    await db.refresh(room)
    return room
