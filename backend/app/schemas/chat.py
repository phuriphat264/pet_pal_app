import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict


class ChatThreadCreate(BaseModel):
    hotel_id: uuid.UUID


class CallTokenRequest(BaseModel):
    call_type: Literal["audio", "video"] = "video"
    # True when the callee is accepting an existing invite -- suppresses
    # sending another "invite" push (the caller already sent one).
    is_accept: bool = False


class CallTokenResponse(BaseModel):
    room: str
    token: str
    livekit_url: str
    call_type: Literal["audio", "video"]


class ChatMessageCreate(BaseModel):
    body: str


class ChatMessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    thread_id: uuid.UUID
    sender_id: uuid.UUID
    body: str
    read_at: datetime | None
    created_at: datetime


class ChatThreadResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    customer_id: uuid.UUID
    hotel_id: uuid.UUID
    hotel_name: str
    customer_name: str
    last_message: str | None
    last_message_at: datetime | None
    unread_count: int
    created_at: datetime
