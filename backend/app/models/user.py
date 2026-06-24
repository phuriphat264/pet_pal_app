import enum
import uuid

from sqlalchemy import Enum, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..db.base import Base, TimestampMixin, UUIDPkMixin


class UserRole(str, enum.Enum):
    customer = "customer"
    technician = "technician"
    admin = "admin"


class User(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    oauth_provider: Mapped[str | None] = mapped_column(String(32), nullable=True)
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role"), default=UserRole.customer, nullable=False
    )

    pets = relationship("Pet", back_populates="owner", cascade="all, delete-orphan")
    bookings = relationship("Booking", back_populates="customer", cascade="all, delete-orphan")
    partner_profile = relationship(
        "PartnerProfile", back_populates="user", uselist=False, cascade="all, delete-orphan",
        foreign_keys="PartnerProfile.user_id",
    )
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    assigned_cameras: Mapped[list["uuid.UUID"]] = relationship(
        "Camera", back_populates="assigned_technician", foreign_keys="Camera.assigned_technician_id"
    )
