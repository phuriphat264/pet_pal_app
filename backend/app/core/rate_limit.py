"""Minimal in-memory sliding-window rate limiter. Good enough for a single
backend instance; if this ever runs behind multiple replicas, swap the
in-memory dict for Redis -- the interface here would stay the same.
"""

import time

from fastapi import HTTPException, Request, status


class RateLimiter:
    def __init__(self, max_requests: int, window_seconds: float) -> None:
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._hits: dict[str, list[float]] = {}

    def __call__(self, request: Request) -> None:
        key = request.client.host if request.client else "unknown"
        now = time.monotonic()
        cutoff = now - self.window_seconds

        hits = [t for t in self._hits.get(key, []) if t > cutoff]
        if len(hits) >= self.max_requests:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests, please try again later",
            )
        hits.append(now)
        self._hits[key] = hits


auth_rate_limit = RateLimiter(max_requests=10, window_seconds=60)
