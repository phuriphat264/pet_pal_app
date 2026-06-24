import pytest
from fastapi.testclient import TestClient

from app import main as main_module
from app.db.session import get_db
from app.main import app, match_cache
from app.models.hotel import Hotel


def _hotel(name: str, tags: list[str] | None = None, ai_tags: list[str] | None = None) -> Hotel:
    return Hotel(name=name, tags=tags or [], ai_tags=ai_tags or [], description="", location="")


_SEEDED_HOTELS = [
    _hotel("Sky Cat Hotel", tags=["เงียบสงบ"], ai_tags=["private", "calm"]),
    _hotel("PigPao Pet Shop", tags=["สนามหญ้า"], ai_tags=["active", "nature"]),
]


async def _fake_get_db():
    yield None


@pytest.fixture()
def client(monkeypatch):
    match_cache.clear()
    # /api/match's DB usage is fully isolated behind vector_search_hotels;
    # stub that out so these tests don't need a real Postgres+pgvector
    # instance, and pin its result to a known set of hotels.
    monkeypatch.setattr(main_module, "vector_search_hotels", _fake_vector_search)
    app.dependency_overrides[get_db] = _fake_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.pop(get_db, None)
    match_cache.clear()


async def _fake_vector_search(text, db):
    return _SEEDED_HOTELS


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_match_without_api_key_returns_local_fallback(client, monkeypatch):
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)

    response = client.post("/api/match", json={"text": "น้องขี้อาย ชอบที่เงียบๆ"})
    assert response.status_code == 200

    data = response.json()
    assert data["isFallback"] is True
    assert data["fallbackNotice"]
    assert data["summary"]
    assert [m["hotelName"] for m in data["matches"]] == ["Sky Cat Hotel", "PigPao Pet Shop"]


def test_match_empty_text_is_rejected(client):
    response = client.post("/api/match", json={"text": ""})
    assert response.status_code == 422


def test_match_falls_back_when_gemini_call_fails(client, monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "fake-key-for-test")

    def boom(*args, **kwargs):
        raise RuntimeError("network error")

    monkeypatch.setattr(main_module, "run_gemini_enrichment", boom)

    response = client.post("/api/match", json={"text": "น้องพลังเยอะ ชอบวิ่งเล่น"})
    assert response.status_code == 200

    data = response.json()
    assert data["isFallback"] is True
    assert "เชื่อมต่อ AI ไม่สำเร็จ" in data["fallbackNotice"]
    assert len(data["matches"]) > 0


def test_match_returns_llm_result_when_gemini_succeeds(client, monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "fake-key-for-test")

    def fake_enrich(text, hotels, api_key):
        return {
            "summary": "น้องเป็นแมวรักสงบ",
            "matches": [{"hotelName": "Sky Cat Hotel", "reason": "ห้องเงียบสงบ"}],
        }

    monkeypatch.setattr(main_module, "run_gemini_enrichment", fake_enrich)

    response = client.post("/api/match", json={"text": "น้องแมวขี้อายมาก"})
    assert response.status_code == 200

    data = response.json()
    assert data["isFallback"] is False
    assert data["fallbackNotice"] is None
    assert data["summary"] == "น้องเป็นแมวรักสงบ"
    assert data["matches"] == [{"hotelName": "Sky Cat Hotel", "reason": "ห้องเงียบสงบ"}]


def test_match_caches_successful_results(client, monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "fake-key-for-test")

    call_count = 0

    def fake_enrich(text, hotels, api_key):
        nonlocal call_count
        call_count += 1
        return {
            "summary": "น้องเป็นแมวรักสงบ",
            "matches": [{"hotelName": "Sky Cat Hotel", "reason": "ห้องเงียบสงบ"}],
        }

    monkeypatch.setattr(main_module, "run_gemini_enrichment", fake_enrich)

    text = "น้องแมวขี้อายมากกกก"
    first = client.post("/api/match", json={"text": text})
    second = client.post("/api/match", json={"text": f"  {text.upper()}  "})

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json() == second.json()
    assert call_count == 1


def test_match_does_not_cache_fallback_results(client, monkeypatch):
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)

    text = "น้องขี้อาย ชอบที่เงียบๆ มากเลย"
    first = client.post("/api/match", json={"text": text})
    assert first.status_code == 200
    assert first.json()["isFallback"] is True

    monkeypatch.setenv("GEMINI_API_KEY", "fake-key-for-test")

    def fake_enrich(text, hotels, api_key):
        return {
            "summary": "น้องเป็นแมวรักสงบ",
            "matches": [{"hotelName": "Sky Cat Hotel", "reason": "ห้องเงียบสงบ"}],
        }

    monkeypatch.setattr(main_module, "run_gemini_enrichment", fake_enrich)

    second = client.post("/api/match", json={"text": text})
    assert second.status_code == 200
    assert second.json()["isFallback"] is False
