import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..core.deps import require_admin
from ..core.security import hash_password
from ..db.session import get_db
from ..models.booking import Booking
from ..models.camera import Camera
from ..models.partner import PartnerProfile, PartnerStatus
from ..models.payment import Payment, PaymentStatus
from ..models.user import User, UserRole
from ..schemas.auth import RoleUpdateRequest, TechnicianCreateRequest, UserResponse
from ..schemas.partner import PartnerApplicationResponse, RejectRequest
from ..schemas.payment import AdminPaymentResponse, FinanceReportDay, FinanceReportResponse, PaymentResponse
from ..services import omise_client
from .partners import application_to_response
from .payments import _BOOKING_PAYMENT_STATUS_MAP

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])

# Roles an admin may assign via /admin/users/{id}/role. Deliberately excludes
# "admin" -- promoting someone to admin through this generic endpoint would
# be a privilege-escalation footgun; that should stay a deliberate, separate
# action (currently: direct DB/seed only).
_ASSIGNABLE_ROLES = {UserRole.customer, UserRole.technician}


@router.post("/technicians", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_technician(
    payload: TechnicianCreateRequest, db: AsyncSession = Depends(get_db)
) -> User:
    existing = await db.scalar(select(User).where(User.email == payload.email))
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email is already registered")

    technician = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        name=payload.name,
        phone=payload.phone,
        role=UserRole.technician,
    )
    db.add(technician)
    await db.commit()
    await db.refresh(technician)
    return technician


@router.patch("/users/{user_id}/role", response_model=UserResponse)
async def update_user_role(
    user_id: uuid.UUID, payload: RoleUpdateRequest, db: AsyncSession = Depends(get_db)
) -> User:
    if payload.role not in _ASSIGNABLE_ROLES:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Role cannot be assigned via this endpoint")

    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.role == UserRole.admin:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot change an admin's role here")

    # A technician losing the role shouldn't leave their cameras stuck --
    # unassigning puts them back in the "unassigned" pool any other
    # technician can immediately pick up (same visibility rule already used
    # for newly-created, not-yet-claimed cameras in cameras.py).
    if user.role == UserRole.technician and payload.role != UserRole.technician:
        await db.execute(
            update(Camera).where(Camera.assigned_technician_id == user.id).values(assigned_technician_id=None)
        )

    user.role = payload.role
    await db.commit()
    await db.refresh(user)
    return user


@router.get("/partner-applications", response_model=list[PartnerApplicationResponse])
async def list_partner_applications(
    status_filter: PartnerStatus | None = Query(default=None, alias="status"),
    db: AsyncSession = Depends(get_db),
) -> list[PartnerApplicationResponse]:
    stmt = select(PartnerProfile).order_by(PartnerProfile.created_at.desc())
    if status_filter is not None:
        stmt = stmt.where(PartnerProfile.status == status_filter)
    result = await db.scalars(stmt)
    return [await application_to_response(a) for a in result.all()]


async def _get_application(application_id: uuid.UUID, db: AsyncSession) -> PartnerProfile:
    application = await db.get(PartnerProfile, application_id)
    if application is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found")
    return application


@router.post("/partner-applications/{application_id}/approve", response_model=PartnerApplicationResponse)
async def approve_application(
    application_id: uuid.UUID,
    admin_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> PartnerApplicationResponse:
    application = await _get_application(application_id, db)
    application.status = PartnerStatus.approved
    application.reviewed_by = admin_user.id
    application.reviewed_at = datetime.now(timezone.utc)
    application.rejection_reason = None
    await db.commit()
    await db.refresh(application)
    return await application_to_response(application)


@router.post("/partner-applications/{application_id}/reject", response_model=PartnerApplicationResponse)
async def reject_application(
    application_id: uuid.UUID,
    payload: RejectRequest,
    admin_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> PartnerApplicationResponse:
    application = await _get_application(application_id, db)
    application.status = PartnerStatus.rejected
    application.reviewed_by = admin_user.id
    application.reviewed_at = datetime.now(timezone.utc)
    application.rejection_reason = payload.reason
    await db.commit()
    await db.refresh(application)
    return await application_to_response(application)


@router.get("/payments", response_model=list[AdminPaymentResponse])
async def list_payments(
    status_filter: PaymentStatus | None = Query(default=None, alias="status"),
    db: AsyncSession = Depends(get_db),
) -> list[AdminPaymentResponse]:
    stmt = (
        select(Payment)
        .options(selectinload(Payment.booking).selectinload(Booking.customer))
        .options(selectinload(Payment.booking).selectinload(Booking.hotel))
        .order_by(Payment.created_at.desc())
        .limit(200)
    )
    if status_filter is not None:
        stmt = stmt.where(Payment.status == status_filter)
    result = await db.scalars(stmt)
    return [
        AdminPaymentResponse(
            **PaymentResponse.model_validate(p).model_dump(),
            created_at=p.created_at,
            customer_name=p.booking.customer.name if p.booking and p.booking.customer else None,
            hotel_name=p.booking.hotel.name if p.booking and p.booking.hotel else None,
        )
        for p in result.all()
    ]


@router.post("/payments/{payment_id}/refund", response_model=AdminPaymentResponse)
async def refund_payment(payment_id: uuid.UUID, db: AsyncSession = Depends(get_db)) -> AdminPaymentResponse:
    payment = await db.get(
        Payment, payment_id, options=[selectinload(Payment.booking).selectinload(Booking.customer)]
    )
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    if payment.status != PaymentStatus.successful:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only successful payments can be refunded")
    if not payment.provider_charge_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Payment has no charge to refund")

    await omise_client.create_refund(payment.provider_charge_id, payment.amount)
    payment.status = PaymentStatus.refunded
    booking = await db.get(Booking, payment.booking_id)
    if booking is not None:
        booking.payment_status = _BOOKING_PAYMENT_STATUS_MAP[PaymentStatus.refunded]
    await db.commit()
    await db.refresh(payment)
    return AdminPaymentResponse(
        **PaymentResponse.model_validate(payment).model_dump(),
        created_at=payment.created_at,
        customer_name=payment.booking.customer.name if payment.booking and payment.booking.customer else None,
        hotel_name=None,
    )


@router.get("/reports/finance", response_model=FinanceReportResponse)
async def finance_report(
    days: int = Query(default=30, ge=1, le=365), db: AsyncSession = Depends(get_db)
) -> FinanceReportResponse:
    since = datetime.now(timezone.utc) - timedelta(days=days)

    counts_by_status = dict(
        (await db.execute(
            select(Payment.status, func.count())
            .where(Payment.created_at >= since)
            .group_by(Payment.status)
        )).all()
    )
    total_revenue_satang = await db.scalar(
        select(func.coalesce(func.sum(Payment.amount), 0)).where(
            Payment.created_at >= since, Payment.status == PaymentStatus.successful
        )
    )

    daily_rows = (
        await db.execute(
            select(
                func.date(Payment.created_at).label("day"),
                func.coalesce(func.sum(Payment.amount), 0).label("revenue_satang"),
                func.count().label("successful_count"),
            )
            .where(Payment.created_at >= since, Payment.status == PaymentStatus.successful)
            .group_by(func.date(Payment.created_at))
            .order_by(func.date(Payment.created_at))
        )
    ).all()

    return FinanceReportResponse(
        period_days=days,
        total_revenue_thb=total_revenue_satang / 100,
        successful_count=counts_by_status.get(PaymentStatus.successful, 0),
        pending_count=counts_by_status.get(PaymentStatus.pending, 0),
        failed_count=counts_by_status.get(PaymentStatus.failed, 0),
        refunded_count=counts_by_status.get(PaymentStatus.refunded, 0),
        daily=[
            FinanceReportDay(day=row.day, revenue_thb=row.revenue_satang / 100, successful_count=row.successful_count)
            for row in daily_rows
        ],
    )
