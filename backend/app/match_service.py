"""Core matching logic for the "AI Smart Match" feature.

Real semantic search (pgvector cosine similarity over locally-computed
embeddings) is the primary engine: it's instant, has no API quota, and
runs directly against the live `hotels` table instead of a static list.
Gemini is an optional enrichment step that rewrites the summary/reasons
in nicer natural language, grounded on the exact candidates the vector
search already picked -- it never gets to choose different hotels, so a
hallucinated or unavailable LLM response can't surface a wrong result.
"""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from . import gemini_client
from .models.hotel import Hotel
from .services.embedding_service import embed_query

TOP_K = 4

_PRIVATE_REASON_SUFFIX = (
    " มีห้องส่วนตัว เงียบสงบ ไม่ถูกรบกวน "
    "ไม่จำเป็นต้องขอให้พนักงานอัปเดตบ่อยๆ เพราะอาจรบกวนน้องได้"
)


async def vector_search_hotels(text: str, db: AsyncSession) -> list[Hotel]:
    query_vector = embed_query(text)
    stmt = (
        select(Hotel)
        .where(Hotel.available.is_(True), Hotel.embedding.is_not(None))
        .options(selectinload(Hotel.images))
        .order_by(Hotel.embedding.cosine_distance(query_vector))
        .limit(TOP_K)
    )
    result = await db.scalars(stmt)
    return list(result.all())


def _hotel_reason(hotel: Hotel) -> str:
    tags = list(hotel.tags or [])
    if not tags:
        return "ที่พักนี้มีลักษณะใกล้เคียงกับสิ่งที่คุณอธิบายเกี่ยวกับน้องมากที่สุดในระบบ"
    reason = f"ที่พักนี้มีจุดเด่นด้าน {', '.join(tags[:3])} ซึ่งใกล้เคียงกับสิ่งที่คุณอธิบายเกี่ยวกับน้อง"
    if "private" in (hotel.ai_tags or []):
        reason += _PRIVATE_REASON_SUFFIX
    return reason


def local_match_result(hotels: list[Hotel]) -> dict:
    if not hotels:
        return {
            "summary": "ยังไม่พบที่พักที่ตรงกับคำอธิบายนี้ในระบบ ลองอธิบายนิสัยน้องเพิ่มเติมดูนะ",
            "matches": [],
        }
    return {
        "summary": "ระบบวิเคราะห์ความหมายจากข้อความของคุณด้วย AI Embedding และจัดอันดับที่พักที่ใกล้เคียงที่สุดให้แล้ว",
        "matches": [{"hotelName": h.name, "reason": _hotel_reason(h)} for h in hotels],
    }


def run_gemini_enrichment(text: str, hotels: list[Hotel], api_key: str) -> dict | None:
    candidates = [
        {
            "name": h.name,
            "tags": list(h.tags or []),
            "ai_tags": list(h.ai_tags or []),
            "description": h.description or "",
            "location": h.location or "",
        }
        for h in hotels
    ]
    enriched = gemini_client.call_gemini_enrich(text, candidates, api_key)
    if enriched is None:
        return None

    valid_names = {h.name for h in hotels}
    matches = [m for m in enriched.get("matches", []) if m.get("hotelName") in valid_names]
    if not matches:
        return None

    return {"summary": enriched["summary"], "matches": matches}
