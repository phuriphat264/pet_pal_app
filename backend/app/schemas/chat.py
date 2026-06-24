import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ChatThreadCreate(BaseModel):
    hotel_id: uuid.UUID


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
