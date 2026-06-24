import time

from app.cache import TTLCache


def test_set_and_get_round_trip():
    cache = TTLCache(ttl_seconds=60)
    cache.set("key", {"value": 1})
    assert cache.get("key") == {"value": 1}


def test_missing_key_returns_none():
    cache = TTLCache(ttl_seconds=60)
    assert cache.get("missing") is None


def test_expired_entry_returns_none():
    cache = TTLCache(ttl_seconds=0.05)
    cache.set("key", {"value": 1})
    time.sleep(0.1)
    assert cache.get("key") is None


def test_normalize_key_collapses_case_and_whitespace():
    assert TTLCache.normalize_key("  Hello   World  ") == "hello world"
    assert TTLCache.normalize_key("hello world") == "hello world"
