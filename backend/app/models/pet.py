import uuid
from datetime import date

from sqlalchemy import ARRAY, Date, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..db.base import Base, TimestampMixin, UUIDPkMixin


class Pet(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "pets"

    owner_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    breed: Mapped[str | None] = mapped_column(String(120))
    age: Mapped[str | None] = mapped_column(String(32))
    weight: Mapped[str | None] = mapped_column(String(32))
    height: Mapped[str | None] = mapped_column(String(32))
    temp: Mapped[str | None] = mapped_column(String(32))
    heart_rate: Mapped[str | None] = mapped_column(String(32))
    gender: Mapped[str | None] = mapped_column(String(16))
    dob: Mapped[date | None] = mapped_column(Date, nullable=True)
    color_desc: Mapped[str | None] = mapped_column(String(120))
    vaccine: Mapped[str | None] = mapped_column(String(255))
    next_vet: Mapped[str | None] = mapped_column(String(120))
    last_vet: Mapped[str | None] = mapped_column(String(120))
    chip_id: Mapped[str | None] = mapped_column(String(64))
    allergies: Mapped[str | None] = mapped_column(Text)
    food: Mapped[str | None] = mapped_column(String(255))
    feeding_times: Mapped[str | None] = mapped_column(String(255))
    neutered: Mapped[str | None] = mapped_column(String(64))
    traits: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    icon_name: Mapped[str | None] = mapped_column(String(64))
    color_hex: Mapped[str | None] = mapped_column(String(16))

    owner = relationship("User", back_populates="pets")
    medical_history = relationship(
        "PetMedicalHistory", back_populates="pet", cascade="all, delete-orphan", order_by="PetMedicalHistory.date.desc()"
    )
    bookings = relationship("Booking", back_populates="pet")


class PetMedicalHistory(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "pet_medical_history"

    pet_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("pets.id"), nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False)
    event: Mapped[str] = mapped_column(String(255), nullable=False)
    vet: Mapped[str | None] = mapped_column(String(120))

    pet = relationship("Pet", back_populates="medical_history")
