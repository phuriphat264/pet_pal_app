import pytest
from fastapi import HTTPException

from app.core.rate_limit import RateLimiter


class _FakeClient:
    def __init__(self, host: str) -> None:
        self.host = host


class _FakeRequest:
    def __init__(self, host: str) -> None:
        self.client = _FakeClient(host)


def test_allows_requests_under_the_limit():
    limiter = RateLimiter(max_requests=3, window_seconds=60)
    request = _FakeRequest("1.2.3.4")
    for _ in range(3):
        limiter(request)  # should not raise


def test_blocks_requests_over_the_limit():
    limiter = RateLimiter(max_requests=3, window_seconds=60)
    request = _FakeRequest("1.2.3.4")
    for _ in range(3):
        limiter(request)
    with pytest.raises(HTTPException) as exc_info:
        limiter(request)
    assert exc_info.value.status_code == 429


def test_tracks_separate_clients_independently():
    limiter = RateLimiter(max_requests=1, window_seconds=60)
    limiter(_FakeRequest("1.1.1.1"))
    limiter(_FakeRequest("2.2.2.2"))  # different client, should not raise


def test_old_hits_outside_the_window_are_forgotten(monkeypatch):
    limiter = RateLimiter(max_requests=1, window_seconds=10)
    import app.core.rate_limit as rate_limit_module

    t = [1000.0]
    monkeypatch.setattr(rate_limit_module.time, "monotonic", lambda: t[0])

    request = _FakeRequest("1.2.3.4")
    limiter(request)
    with pytest.raises(HTTPException):
        limiter(request)

    t[0] += 11  # advance past the window
    limiter(request)  # should not raise now
