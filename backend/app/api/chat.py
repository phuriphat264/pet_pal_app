import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from livekit import api as livekit_api
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..core.config import get_settings
from ..core.deps import get_current_user, get_current_user_ws
from ..db.session import AsyncSessionLocal, get_db
from ..models.chat import ChatMessage, ChatThread
from ..models.hotel import Hotel
from ..models.notification import Notification, NotificationType
from ..models.partner import PartnerProfile
from ..models.user import User, UserRole
from ..schemas.chat import (
    CallTokenRequest,
    CallTokenResponse,
    ChatMessageCreate,
    ChatMessageResponse,
    ChatThreadCreate,
    ChatThreadResponse,
)
from ..ws.connection_manager import manager

settings = get_settings()

router = APIRouter(prefix="/chat", tags=["chat"])


async def _thread_with_relations(thread_id: uuid.UUID, db: AsyncSession) -> ChatThread | None:
    return await db.scalar(
        select(ChatThread)
        .where(ChatThread.id == thread_id)
        .options(selectinload(ChatThread.messages), selectinload(ChatThread.hotel))
    )


async def _other_party_id(thread: ChatThread, db: AsyncSession) -> uuid.UUID | None:
    hotel = await db.get(Hotel, thread.hotel_id)
    if hotel is None or hotel.partner_id is None:
        return None
    partner = await db.get(PartnerProfile, hotel.partner_id)
    return partner.user_id if partner else None


async def _recipient_id(thread: ChatThread, sender: User, db: AsyncSession) -> uuid.UUID | None:
    return thread.customer_id if sender.id != thread.customer_id else await _other_party_id(thread, db)


async def _authorize_thread(thread: ChatThread, user: User, db: AsyncSession) -> None:
    if user.role == UserRole.admin or thread.customer_id == user.id:
        return
    other_id = await _other_party_id(thread, db)
    if other_id == user.id:
        return
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not part of this conversation")


def _to_thread_response(thread: ChatThread, hotel_name: str, customer_name: str, unread_count: int) -> ChatThreadResponse:
    last = thread.messages[-1] if thread.messages else None
    return ChatThreadResponse(
        id=thread.id,
        customer_id=thread.customer_id,
        hotel_id=thread.hotel_id,
        hotel_name=hotel_name,
        customer_name=customer_name,
        last_message=last.body if last else None,
        last_message_at=last.created_at if last else None,
        unread_count=unread_count,
        created_at=thread.created_at,
    )


@router.get("/threads", response_model=list[ChatThreadResponse])
async def list_threads(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)) -> list[ChatThreadResponse]:
    if user.role == UserRole.admin:
        stmt = select(ChatThread)
    else:
        partner = await db.scalar(select(PartnerProfile).where(PartnerProfile.user_id == user.id))
        hotel_ids = []
        if partner is not None:
            hotel_ids = list((await db.scalars(select(Hotel.id).where(Hotel.partner_id == partner.id))).all())
        if hotel_ids:
            stmt = select(ChatThread).where((ChatThread.customer_id == user.id) | (ChatThread.hotel_id.in_(hotel_ids)))
        else:
            stmt = select(ChatThread).where(ChatThread.customer_id == user.id)

    stmt = stmt.options(
        selectinload(ChatThread.messages), selectinload(ChatThread.hotel), selectinload(ChatThread.customer)
    ).order_by(ChatThread.created_at.desc())
    threads = list((await db.scalars(stmt)).all())

    responses = []
    for thread in threads:
        unread = await db.scalar(
            select(func.count())
            .select_from(ChatMessage)
            .where(ChatMessage.thread_id == thread.id, ChatMessage.sender_id != user.id, ChatMessage.read_at.is_(None))
        )
        responses.append(
            _to_thread_response(
                thread,
                hotel_name=thread.hotel.name if thread.hotel else "",
                customer_name=thread.customer.name if thread.customer else "",
                unread_count=unread or 0,
            )
        )
    return responses


async def _get_or_create_thread(customer_id: uuid.UUID, hotel_id: uuid.UUID, db: AsyncSession) -> ChatThread:
    thread = await db.scalar(select(ChatThread).where(ChatThread.customer_id == customer_id, ChatThread.hotel_id == hotel_id))
    if thread is None:
        thread = ChatThread(customer_id=customer_id, hotel_id=hotel_id)
        db.add(thread)
        await db.commit()
        await db.refresh(thread)
    return thread


@router.post("/threads", response_model=ChatThreadResponse, status_code=status.HTTP_201_CREATED)
async def create_or_get_thread(
    payload: ChatThreadCreate, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> ChatThreadResponse:
    hotel = await db.get(Hotel, payload.hotel_id)
    if hotel is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hotel not found")

    thread = await _get_or_create_thread(user.id, payload.hotel_id, db)
    thread = await _thread_with_relations(thread.id, db)
    return _to_thread_response(thread, hotel_name=hotel.name, customer_name=user.name, unread_count=0)


@router.get("/threads/{thread_id}/messages", response_model=list[ChatMessageResponse])
async def list_messages(
    thread_id: uuid.UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> list[ChatMessage]:
    thread = await db.get(ChatThread, thread_id)
    if thread is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Thread not found")
    await _authorize_thread(thread, user, db)
    result = await db.scalars(
        select(ChatMessage).where(ChatMessage.thread_id == thread_id).order_by(ChatMessage.created_at)
    )
    return list(result.all())


@router.post("/threads/{thread_id}/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_thread_read(
    thread_id: uuid.UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> None:
    thread = await db.get(ChatThread, thread_id)
    if thread is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Thread not found")
    await _authorize_thread(thread, user, db)

    result = await db.scalars(
        select(ChatMessage).where(
            ChatMessage.thread_id == thread_id, ChatMessage.sender_id != user.id, ChatMessage.read_at.is_(None)
        )
    )
    now = datetime.now(timezone.utc)
    for message in result.all():
        message.read_at = now
    await db.commit()


async def _create_message(thread_id: uuid.UUID, sender: User, body: str, db: AsyncSession) -> ChatMessage:
    thread = await db.get(ChatThread, thread_id)
    if thread is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Thread not found")
    await _authorize_thread(thread, sender, db)

    message = ChatMessage(thread_id=thread_id, sender_id=sender.id, body=body)
    db.add(message)
    await db.commit()
    await db.refresh(message)

    recipient_id = await _recipient_id(thread, sender, db)
    if recipient_id is not None:
        notification = Notification(
            user_id=recipient_id,
            type=NotificationType.chat,
            title=f"ข้อความใหม่จาก {sender.name}",
            body=body[:200],
            data={"thread_id": str(thread_id)},
        )
        db.add(notification)
        await db.commit()
        await db.refresh(notification)

        await manager.send_to_user(
            recipient_id,
            {
                "type": "chat_message",
                "thread_id": str(thread_id),
                "message": ChatMessageResponse.model_validate(message).model_dump(mode="json"),
            },
        )
        await manager.send_to_user(
            recipient_id,
            {
                "type": "notification",
                "notification": {
                    "id": str(notification.id),
                    "type": notification.type.value,
                    "title": notification.title,
                    "body": notification.body,
                    "data": notification.data,
                    "read": notification.read,
                    "created_at": notification.created_at.isoformat(),
                },
            },
        )

    return message


@router.post("/threads/{thread_id}/messages", response_model=ChatMessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    thread_id: uuid.UUID,
    payload: ChatMessageCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ChatMessage:
    return await _create_message(thread_id, user, payload.body, db)


@router.post("/threads/{thread_id}/call-token", response_model=CallTokenResponse)
async def get_call_token(
    thread_id: uuid.UUID,
    payload: CallTokenRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CallTokenResponse:
    thread = await db.get(ChatThread, thread_id)
    if thread is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Thread not found")
    await _authorize_thread(thread, user, db)

    room = f"call-{thread_id}"
    grants = livekit_api.VideoGrants(room_join=True, room=room, can_publish=True, can_subscribe=True)
    token = (
        livekit_api.AccessToken(settings.livekit_api_key, settings.livekit_api_secret)
        .with_identity(str(user.id))
        .with_name(user.name)
        .with_grants(grants)
        .to_jwt()
    )

    if not payload.is_accept:
        recipient_id = await _recipient_id(thread, user, db)
        if recipient_id is not None:
            await manager.send_to_user(
                recipient_id,
                {
                    "type": "call_signal",
                    "signal": "invite",
                    "thread_id": str(thread_id),
                    "room": room,
                    "call_type": payload.call_type,
                    "caller_id": str(user.id),
                    "caller_name": user.name,
                },
            )

    return CallTokenResponse(room=room, token=token, livekit_url=settings.livekit_public_url, call_type=payload.call_type)


@router.websocket("/ws")
async def chat_websocket(websocket: WebSocket, user: User = Depends(get_current_user_ws)) -> None:
    await websocket.accept()
    manager.connect(user.id, websocket)
    try:
        while True:
            data = await websocket.receive_json()

            if data.get("type") == "call_signal":
                thread_id = data.get("thread_id")
                if not thread_id:
                    continue
                async with AsyncSessionLocal() as db:
                    thread = await db.get(ChatThread, uuid.UUID(thread_id))
                    if thread is None:
                        continue
                    fresh_user = await db.get(User, user.id)
                    recipient_id = await _recipient_id(thread, fresh_user, db)
                    if recipient_id is not None:
                        await manager.send_to_user(recipient_id, {**data, "from_user_id": str(user.id)})
                continue

            thread_id = data.get("thread_id")
            body = data.get("body")
            if not thread_id or not body:
                continue
            async with AsyncSessionLocal() as db:
                fresh_user = await db.get(User, user.id)
                try:
                    message = await _create_message(uuid.UUID(thread_id), fresh_user, body, db)
                except HTTPException as exc:
                    await websocket.send_json({"type": "error", "detail": exc.detail})
                    continue
                await websocket.send_json(
                    {
                        "type": "chat_message",
                        "thread_id": thread_id,
                        "message": ChatMessageResponse.model_validate(message).model_dump(mode="json"),
                    }
                )
    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(user.id, websocket)
