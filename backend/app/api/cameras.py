import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.config import get_settings
from ..core.deps import get_current_user, require_technician
from ..db.session import get_db
from ..models.booking import Booking, BookingStatus
from ..models.camera import Camera, CameraProtocol, CameraStatus
from ..models.user import User, UserRole
from ..schemas.camera import CameraCreate, CameraResponse, CameraStreamResponse, CameraTestResult, CameraUpdate
from ..services.camera_crypto import decrypt_camera_password, encrypt_camera_password
from ..services.camera_probe import probe_camera

# Least-privilege scoping: an admin manages every camera, but a technician
# (who may be an external contractor hired just to repair/replace one
# hotel's cameras) only sees/edits cameras already assigned to them, or
# unassigned ones they can pick up -- never another technician's hotels.
router = APIRouter(prefix="/cameras", tags=["cameras"], dependencies=[Depends(require_technician)])

# Separate router (no blanket technician-only dependency) for the one route
# customers also need: fetching a playable stream URL for a camera tied to
# a hotel/room they've actually booked.
stream_router = APIRouter(prefix="/cameras", tags=["cameras"])


def _visibility_filter(user: User):
    if user.role == UserRole.admin:
        return None
    return or_(Camera.assigned_technician_id == user.id, Camera.assigned_technician_id.is_(None))


async def _get_camera_for_user(camera_id: uuid.UUID, user: User, db: AsyncSession) -> Camera:
    camera = await db.get(Camera, camera_id)
    if camera is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camera not found")
    if user.role != UserRole.admin and camera.assigned_technician_id not in (None, user.id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This camera is assigned to another technician")
    return camera


@router.get("", response_model=list[CameraResponse])
async def list_cameras(
    hotel_id: uuid.UUID | None = Query(default=None),
    user: User = Depends(require_technician),
    db: AsyncSession = Depends(get_db),
) -> list[Camera]:
    stmt = select(Camera).order_by(Camera.created_at.desc())
    if hotel_id is not None:
        stmt = stmt.where(Camera.hotel_id == hotel_id)
    visibility = _visibility_filter(user)
    if visibility is not None:
        stmt = stmt.where(visibility)
    result = await db.scalars(stmt)
    return list(result.all())


@router.get("/{camera_id}", response_model=CameraResponse)
async def get_camera(
    camera_id: uuid.UUID, user: User = Depends(require_technician), db: AsyncSession = Depends(get_db)
) -> Camera:
    return await _get_camera_for_user(camera_id, user, db)


@router.post("", response_model=CameraResponse, status_code=status.HTTP_201_CREATED)
async def create_camera(
    payload: CameraCreate, user: User = Depends(require_technician), db: AsyncSession = Depends(get_db)
) -> Camera:
    data = payload.model_dump(exclude={"password"})
    if not data.get("username"):
        data["username"] = get_settings().camera_default_username
    camera = Camera(
        **data,
        encrypted_password=encrypt_camera_password(payload.password) if payload.password else None,
        assigned_technician_id=user.id,
    )
    db.add(camera)
    await db.commit()
    await db.refresh(camera)
    return camera


@router.patch("/{camera_id}", response_model=CameraResponse)
async def update_camera(
    camera_id: uuid.UUID,
    payload: CameraUpdate,
    user: User = Depends(require_technician),
    db: AsyncSession = Depends(get_db),
) -> Camera:
    camera = await _get_camera_for_user(camera_id, user, db)

    updates = payload.model_dump(exclude_unset=True, exclude={"password"})
    if "assigned_technician_id" in updates and user.role != UserRole.admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Only an admin can reassign a camera"
        )
    for field, value in updates.items():
        setattr(camera, field, value)
    if payload.password:
        camera.encrypted_password = encrypt_camera_password(payload.password)
    await db.commit()
    await db.refresh(camera)
    return camera


@router.delete("/{camera_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_camera(
    camera_id: uuid.UUID, user: User = Depends(require_technician), db: AsyncSession = Depends(get_db)
) -> None:
    camera = await _get_camera_for_user(camera_id, user, db)
    await db.delete(camera)
    await db.commit()


@router.post("/{camera_id}/test-connection", response_model=CameraTestResult)
async def test_camera_connection(
    camera_id: uuid.UUID, user: User = Depends(require_technician), db: AsyncSession = Depends(get_db)
) -> CameraTestResult:
    camera = await _get_camera_for_user(camera_id, user, db)
    success, error = await probe_camera(camera.ip_address, camera.port)

    camera.status = CameraStatus.online if success else CameraStatus.error
    camera.last_checked_at = datetime.now(timezone.utc)
    camera.last_error = error
    await db.commit()
    await db.refresh(camera)

    return CameraTestResult(success=success, message=error, camera=camera)


def _build_stream_url(camera: Camera) -> str:
    if camera.protocol == CameraProtocol.onvif:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ONVIF cameras are not directly playable -- set protocol to rtsp/http with the stream path instead",
        )
    auth = ""
    if camera.username:
        password = decrypt_camera_password(camera.encrypted_password) if camera.encrypted_password else ""
        auth = f"{camera.username}:{password}@"
    path = camera.stream_path or ""
    scheme = camera.protocol.value
    return f"{scheme}://{auth}{camera.ip_address}:{camera.port}{path}"


async def _authorize_stream_access(camera: Camera, user: User, db: AsyncSession) -> None:
    if user.role in (UserRole.admin, UserRole.technician):
        return
    booking = await db.scalar(
        select(Booking).where(
            Booking.customer_id == user.id,
            Booking.hotel_id == camera.hotel_id,
            Booking.status != BookingStatus.cancelled,
        )
    )
    if booking is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No booking at this camera's hotel")


@stream_router.get("/by-hotel/{hotel_id}", response_model=list[CameraResponse])
async def list_cameras_for_hotel(
    hotel_id: uuid.UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> list[Camera]:
    if user.role not in (UserRole.admin, UserRole.technician):
        booking = await db.scalar(
            select(Booking).where(
                Booking.customer_id == user.id,
                Booking.hotel_id == hotel_id,
                Booking.status != BookingStatus.cancelled,
            )
        )
        if booking is None:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No booking at this hotel")

    result = await db.scalars(select(Camera).where(Camera.hotel_id == hotel_id).order_by(Camera.created_at))
    return list(result.all())


@stream_router.get("/{camera_id}/stream", response_model=CameraStreamResponse)
async def get_camera_stream(
    camera_id: uuid.UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> CameraStreamResponse:
    camera = await db.get(Camera, camera_id)
    if camera is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camera not found")
    await _authorize_stream_access(camera, user, db)
    return CameraStreamResponse(stream_url=_build_stream_url(camera), protocol=camera.protocol)
