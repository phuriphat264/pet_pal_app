import uuid

from pgvector.sqlalchemy import Vector
from sqlalchemy import ARRAY, Boolean, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.config import get_settings
from ..db.base import Base, TimestampMixin, UUIDPkMixin

EMBEDDING_DIM = get_settings().embedding_dim


class Hotel(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "hotels"

    partner_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("partner_profiles.id"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    location: Mapped[str | None] = mapped_column(String(255))
    distance_text: Mapped[str | None] = mapped_column(String(64))
    rating: Mapped[float] = mapped_column(Numeric(2, 1), default=0)
    reviews_count: Mapped[int] = mapped_column(Integer, default=0)
    base_price: Mapped[int] = mapped_column(Integer, default=0)
    icon_name: Mapped[str | None] = mapped_column(String(64))
    color_hex: Mapped[str | None] = mapped_column(String(16))
    description: Mapped[str | None] = mapped_column(Text)
    service_type: Mapped[str | None] = mapped_column(String(64))
    available: Mapped[bool] = mapped_column(Boolean, default=True)
    tags: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    ai_tags: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    pet_types: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    embedding: Mapped[list[float] | None] = mapped_column(Vector(EMBEDDING_DIM), nullable=True)

    partner = relationship("PartnerProfile", back_populates="hotels")
    images = relationship(
        "HotelImage", back_populates="hotel", cascade="all, delete-orphan", order_by="HotelImage.sort_order"
    )
    rooms = relationship("HotelRoom", back_populates="hotel", cascade="all, delete-orphan")
    bookings = relationship("Booking", back_populates="hotel")
    cameras = relationship("Camera", back_populates="hotel", cascade="all, delete-orphan")


class HotelImage(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "hotel_images"

    hotel_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("hotels.id"), nullable=False)
    url: Mapped[str] = mapped_column(String(512), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

    hotel = relationship("Hotel", back_populates="images")


class HotelRoom(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "hotel_rooms"

    hotel_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("hotels.id"), nullable=False)
    room_type: Mapped[str] = mapped_column(String(120), nullable=False)
    price_surcharge: Mapped[int] = mapped_column(Integer, default=0)
    description: Mapped[str | None] = mapped_column(String(255))
    available: Mapped[bool] = mapped_column(Boolean, default=True)

    hotel = relationship("Hotel", back_populates="rooms")
    bookings = relationship("Booking", back_populates="room")
