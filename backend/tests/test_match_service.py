from app.match_service import local_match_result, run_gemini_enrichment
from app.models.hotel import Hotel


def _hotel(name: str, tags: list[str] | None = None, ai_tags: list[str] | None = None) -> Hotel:
    return Hotel(name=name, tags=tags or [], ai_tags=ai_tags or [], description="", location="")


def test_local_match_result_is_empty_summary_when_no_hotels():
    result = local_match_result([])
    assert result["matches"] == []
    assert result["summary"]


def test_local_match_result_builds_a_reason_per_hotel():
    hotels = [_hotel("Sky Cat Hotel", tags=["เงียบสงบ", "ห้องส่วนตัว"], ai_tags=["private"])]
    result = local_match_result(hotels)

    assert len(result["matches"]) == 1
    match = result["matches"][0]
    assert match["hotelName"] == "Sky Cat Hotel"
    assert "เงียบสงบ" in match["reason"]
    assert "พนักงานอัปเดต" in match["reason"]  # private-room suffix


def test_run_gemini_enrichment_keeps_only_candidate_hotel_names(monkeypatch):
    hotels = [_hotel("Sky Cat Hotel"), _hotel("Dapperdou")]

    def fake_call(text, candidates, api_key):
        return {
            "summary": "สรุปผล",
            "matches": [
                {"hotelName": "Sky Cat Hotel", "reason": "ดี"},
                {"hotelName": "โรงแรมที่ไม่ได้อยู่ใน candidates", "reason": "ไม่ควรปรากฏ"},
            ],
        }

    monkeypatch.setattr("app.match_service.gemini_client.call_gemini_enrich", fake_call)

    result = run_gemini_enrichment("text", hotels, "fake-key")
    assert result is not None
    assert [m["hotelName"] for m in result["matches"]] == ["Sky Cat Hotel"]


def test_run_gemini_enrichment_returns_none_when_no_matches_are_valid(monkeypatch):
    hotels = [_hotel("Sky Cat Hotel")]

    def fake_call(text, candidates, api_key):
        return {"summary": "สรุปผล", "matches": [{"hotelName": "ไม่มีในระบบ", "reason": "x"}]}

    monkeypatch.setattr("app.match_service.gemini_client.call_gemini_enrich", fake_call)

    assert run_gemini_enrichment("text", hotels, "fake-key") is None


def test_run_gemini_enrichment_returns_none_when_gemini_returns_none(monkeypatch):
    hotels = [_hotel("Sky Cat Hotel")]
    monkeypatch.setattr("app.match_service.gemini_client.call_gemini_enrich", lambda *a, **kw: None)

    assert run_gemini_enrichment("text", hotels, "fake-key") is None
