import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..db.base import Base, TimestampMixin, UUIDPkMixin


class ChatThread(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "chat_threads"

    customer_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    hotel_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("hotels.id"), nullable=False)

    messages = relationship(
        "ChatMessage", back_populates="thread", cascade="all, delete-orphan", order_by="ChatMessage.created_at"
    )
    hotel = relationship("Hotel")
    customer = relationship("User")


class ChatMessage(UUIDPkMixin, TimestampMixin, Base):
    __tablename__ = "chat_messages"

    thread_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("chat_threads.id"), nullable=False)
    sender_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    thread = relationship("ChatThread", back_populates="messages")
