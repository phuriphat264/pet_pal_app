"""Sends transactional emails (currently just password-reset codes). When
SMTP isn't configured (the dev default), the code is logged instead of sent
so local development never needs a real mail server -- same "unconfigured
means a clear no-op, not a crash" pattern as oauth_service.py.
"""

import asyncio
import logging
import smtplib
from email.message import EmailMessage

from ..core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


def _send_sync(to_email: str, subject: str, body: str) -> None:
    message = EmailMessage()
    message["From"] = settings.smtp_from
    message["To"] = to_email
    message["Subject"] = subject
    message.set_content(body)

    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as smtp:
        if settings.smtp_use_tls:
            smtp.starttls()
        if settings.smtp_user:
            smtp.login(settings.smtp_user, settings.smtp_password)
        smtp.send_message(message)


async def send_password_reset_email(to_email: str, reset_token: str) -> None:
    subject = "Your PetPal password reset code"
    body = (
        f"Use this code in the app to reset your PetPal password:\n\n"
        f"{reset_token}\n\n"
        f"This code expires in 30 minutes. If you didn't request this, you can ignore this email."
    )

    if not settings.smtp_host:
        # warning, not info: the app doesn't configure a logging level
        # anywhere, so plain .info() calls are silently dropped under
        # uvicorn's default root logger and this code would never be seen.
        logger.warning("[email_service] SMTP not configured; password reset code for %s: %s", to_email, reset_token)
        return

    await asyncio.to_thread(_send_sync, to_email, subject, body)
