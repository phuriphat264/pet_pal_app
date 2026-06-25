import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from ..models.camera import CameraProtocol, CameraStatus


class CameraCreate(BaseModel):
    hotel_id: uuid.UUID
    room_id: uuid.UUID | None = None
    name: str
    ip_address: str
    port: int = 554
    protocol: CameraProtocol = CameraProtocol.rtsp
    stream_path: str | None = None
    username: str | None = None
    password: str | None = None
    notes: str | None = None


class CameraUpdate(BaseModel):
    name: str | None = None
    room_id: uuid.UUID | None = None
    ip_address: str | None = None
    port: int | None = None
    protocol: CameraProtocol | None = None
    stream_path: str | None = None
    username: str | None = None
    password: str | None = None
    notes: str | None = None
    assigned_technician_id: uuid.UUID | None = None


class CameraResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    hotel_id: uuid.UUID
    room_id: uuid.UUID | None
    name: str
    ip_address: str
    port: int
    protocol: CameraProtocol
    stream_path: str | None
    username: str | None
    status: CameraStatus
    last_checked_at: datetime | None
    last_error: str | None
    assigned_technician_id: uuid.UUID | None
    notes: str | None


class CameraTestResult(BaseModel):
    success: bool
    message: str | None
    camera: CameraResponse


class CameraStreamResponse(BaseModel):
    stream_url: str
    protocol: CameraProtocol
