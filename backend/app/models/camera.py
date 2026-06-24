import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..db.base import Base, TimestampMixin, UUIDPkMixin


class CameraProtocol(str, enum.Enum):
    rtsp = "rtsp"
    http = "http"
    onvif = "onvif"


class CameraStatus(str, enum.Enum):
    unregistered = "unregistered"
    online = "online"
    offline = "offline"
    error = "error"


class Camera(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "cameras"

    hotel_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("hotels.id"), nullable=False)
    room_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("hotel_rooms.id"), nullable=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    ip_address: Mapped[str] = mapped_column(String(64), nullable=False)
    port: Mapped[int] = mapped_column(Integer, default=554)
    protocol: Mapped[CameraProtocol] = mapped_column(
        Enum(CameraProtocol, name="camera_protocol"), default=CameraProtocol.rtsp, nullable=False
    )
    stream_path: Mapped[str | None] = mapped_column(String(255))
    username: Mapped[str | None] = mapped_column(String(120))
    encrypted_password: Mapped[str | None] = mapped_column(String(512))
    status: Mapped[CameraStatus] = mapped_column(
        Enum(CameraStatus, name="camera_status"), default=CameraStatus.unregistered, nullable=False
    )
    last_checked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_error: Mapped[str | None] = mapped_column(Text)
    assigned_technician_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True
    )
    notes: Mapped[str | None] = mapped_column(Text)

    hotel = relationship("Hotel", back_populates="cameras")
    room = relationship("HotelRoom")
    assigned_technician = relationship("User", back_populates="assigned_cameras", foreign_keys=[assigned_technician_id])
