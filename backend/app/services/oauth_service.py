"""Verifies third-party login tokens so we never trust a client-asserted
identity directly. Google ID tokens are verified cryptographically against
Google's public certs; Facebook access tokens are verified against the
Graph API (and cross-checked against our own app ID via debug_token) so a
token issued to a different app can't be replayed against this backend.
"""

import httpx
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

from ..core.config import get_settings
from ..core.security import normalize_email

settings = get_settings()


class OAuthVerificationError(Exception):
    pass


def verify_google_id_token(token: str) -> dict:
    if not settings.google_client_id:
        raise OAuthVerificationError("Google login is not configured (GOOGLE_CLIENT_ID is unset)")
    try:
        claims = google_id_token.verify_oauth2_token(
            token, google_requests.Request(), audience=settings.google_client_id
        )
    except ValueError as exc:
        raise OAuthVerificationError(f"Invalid Google ID token: {exc}") from exc

    email = claims.get("email")
    if not email:
        raise OAuthVerificationError("Google account has no email")
    return {"email": normalize_email(email), "name": claims.get("name") or email.split("@")[0]}


async def verify_facebook_access_token(token: str) -> dict:
    if not settings.facebook_app_id or not settings.facebook_app_secret:
        raise OAuthVerificationError("Facebook login is not configured (FACEBOOK_APP_ID/SECRET unset)")

    app_token = f"{settings.facebook_app_id}|{settings.facebook_app_secret}"

    async with httpx.AsyncClient(timeout=10.0) as client:
        debug_resp = await client.get(
            "https://graph.facebook.com/debug_token",
            params={"input_token": token, "access_token": app_token},
        )
        if debug_resp.status_code != 200:
            raise OAuthVerificationError("Could not validate Facebook token")
        debug_data = debug_resp.json().get("data", {})
        if not debug_data.get("is_valid") or str(debug_data.get("app_id")) != settings.facebook_app_id:
            raise OAuthVerificationError("Facebook token is invalid or was issued to a different app")

        me_resp = await client.get(
            "https://graph.facebook.com/me",
            params={"access_token": token, "fields": "id,name,email"},
        )
        if me_resp.status_code != 200:
            raise OAuthVerificationError("Could not fetch Facebook profile")
        me_data = me_resp.json()

    email = me_data.get("email")
    if not email:
        raise OAuthVerificationError(
            "This Facebook account has no email on file or didn't grant email permission"
        )
    return {"email": normalize_email(email), "name": me_data.get("name") or email.split("@")[0]}
