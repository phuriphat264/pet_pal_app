import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from ..models.notification import NotificationType


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    type: NotificationType
    title: str
    body: str | None
    data: dict | None
    read: bool
    created_at: datetime
