import asyncio

import httpx
import pytest

from app.services import oauth_service


def test_verify_google_id_token_raises_when_not_configured(monkeypatch):
    monkeypatch.setattr(oauth_service.settings, "google_client_id", "")
    with pytest.raises(oauth_service.OAuthVerificationError, match="not configured"):
        oauth_service.verify_google_id_token("whatever")


def test_verify_google_id_token_returns_email_and_name(monkeypatch):
    monkeypatch.setattr(oauth_service.settings, "google_client_id", "test-client-id")
    monkeypatch.setattr(
        oauth_service.google_id_token,
        "verify_oauth2_token",
        lambda token, request, audience: {"email": "a@example.com", "name": "A Name"},
    )
    result = oauth_service.verify_google_id_token("fake-token")
    assert result == {"email": "a@example.com", "name": "A Name"}


def test_verify_google_id_token_wraps_value_error(monkeypatch):
    monkeypatch.setattr(oauth_service.settings, "google_client_id", "test-client-id")

    def boom(token, request, audience):
        raise ValueError("bad signature")

    monkeypatch.setattr(oauth_service.google_id_token, "verify_oauth2_token", boom)
    with pytest.raises(oauth_service.OAuthVerificationError, match="bad signature"):
        oauth_service.verify_google_id_token("fake-token")


def test_verify_facebook_access_token_raises_when_not_configured(monkeypatch):
    monkeypatch.setattr(oauth_service.settings, "facebook_app_id", "")
    monkeypatch.setattr(oauth_service.settings, "facebook_app_secret", "")
    with pytest.raises(oauth_service.OAuthVerificationError, match="not configured"):
        asyncio.run(oauth_service.verify_facebook_access_token("whatever"))


def test_verify_facebook_access_token_rejects_token_from_another_app(monkeypatch):
    monkeypatch.setattr(oauth_service.settings, "facebook_app_id", "123")
    monkeypatch.setattr(oauth_service.settings, "facebook_app_secret", "secret")

    async def fake_get(self, url, params=None, **kwargs):
        if "debug_token" in url:
            return httpx.Response(200, json={"data": {"is_valid": True, "app_id": "999"}})
        raise AssertionError("should not call /me when app_id mismatches")

    monkeypatch.setattr(httpx.AsyncClient, "get", fake_get, raising=True)

    with pytest.raises(oauth_service.OAuthVerificationError, match="different app"):
        asyncio.run(oauth_service.verify_facebook_access_token("fake-token"))


def test_verify_facebook_access_token_returns_email_and_name(monkeypatch):
    monkeypatch.setattr(oauth_service.settings, "facebook_app_id", "123")
    monkeypatch.setattr(oauth_service.settings, "facebook_app_secret", "secret")

    async def fake_get(self, url, params=None, **kwargs):
        if "debug_token" in url:
            return httpx.Response(200, json={"data": {"is_valid": True, "app_id": "123"}})
        return httpx.Response(200, json={"id": "1", "name": "B Name", "email": "b@example.com"})

    monkeypatch.setattr(httpx.AsyncClient, "get", fake_get, raising=True)

    result = asyncio.run(oauth_service.verify_facebook_access_token("fake-token"))
    assert result == {"email": "b@example.com", "name": "B Name"}
