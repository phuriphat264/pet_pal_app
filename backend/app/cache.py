"""In-memory TTL cache with LRU eviction for /api/match results."""

import time
from collections import OrderedDict


class TTLCache:
    def __init__(self, ttl_seconds: float = 600, maxsize: int = 500):
        self.ttl_seconds = ttl_seconds
        self.maxsize = maxsize
        self._store: OrderedDict[str, tuple[float, dict]] = OrderedDict()

    def get(self, key: str) -> dict | None:
        entry = self._store.get(key)
        if entry is None:
            return None
        expires_at, value = entry
        if time.monotonic() > expires_at:
            del self._store[key]
            return None
        self._store.move_to_end(key)
        return value

    def set(self, key: str, value: dict) -> None:
        if key in self._store:
            self._store.move_to_end(key)
        self._store[key] = (time.monotonic() + self.ttl_seconds, value)
        while len(self._store) > self.maxsize:
            self._store.popitem(last=False)

    def clear(self) -> None:
        self._store.clear()

    @staticmethod
    def normalize_key(text: str) -> str:
        return " ".join(text.strip().lower().split())
