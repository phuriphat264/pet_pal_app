import asyncio
import os

from dotenv import load_dotenv
from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession

from .api import admin, auth, bookings, cameras, chat, hotels, notifications, partners, pets, users
from .cache import TTLCache
from .db.session import get_db
from .match_service import local_match_result, run_gemini_enrichment, vector_search_hotels
from .match_schemas import MatchRequest, MatchResponse
from .services.storage_service import ensure_bucket

load_dotenv()

CACHE_TTL_SECONDS = float(os.environ.get("MATCH_CACHE_TTL_SECONDS", "600"))
CACHE_MAXSIZE = int(os.environ.get("MATCH_CACHE_MAXSIZE", "500"))
GEMINI_MAX_CONCURRENT = int(os.environ.get("GEMINI_MAX_CONCURRENT", "3"))
MATCH_TIMEOUT_SECONDS = float(os.environ.get("MATCH_TIMEOUT_SECONDS", "40"))

match_cache = TTLCache(ttl_seconds=CACHE_TTL_SECONDS, maxsize=CACHE_MAXSIZE)
_gemini_sem = asyncio.Semaphore(GEMINI_MAX_CONCURRENT)

app = FastAPI(title="PetPal API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(pets.router)
app.include_router(hotels.router)
app.include_router(bookings.router)
app.include_router(partners.router)
app.include_router(admin.router)
app.include_router(cameras.router)
app.include_router(chat.router)
app.include_router(notifications.router)


@app.on_event("startup")
async def _startup() -> None:
    await ensure_bucket()


async def _run_gemini_enrich(text: str, hotels: list) -> dict | None:
    api_key = os.environ.get("GEMINI_API_KEY", "")
    async with _gemini_sem:
        return await asyncio.to_thread(run_gemini_enrichment, text, hotels, api_key)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/api/match", response_model=MatchResponse)
async def match(request: MatchRequest, db: AsyncSession = Depends(get_db)) -> MatchResponse:
    cache_key = TTLCache.normalize_key(request.text)

    cached = match_cache.get(cache_key)
    if cached is not None:
        return MatchResponse(**cached)

    # The vector search is the real matching engine and is always fast (a
    # single local embedding inference + an indexed cosine-distance query),
    # so it runs outside the Gemini timeout/semaphore entirely.
    hotels = await vector_search_hotels(request.text, db)
    local_result = local_match_result(hotels)

    api_key = os.environ.get("GEMINI_API_KEY", "")
    has_api_key = bool(api_key) and api_key != "YOUR_API_KEY_HERE"

    if not has_api_key or not hotels:
        result = {
            **local_result,
            "isFallback": True,
            "fallbackNotice": "⚠️ ยังไม่ได้ตั้งค่า AI (API Key) ระบบจึงแสดงผลจากการค้นหาเชิงความหมายในฐานข้อมูลให้ก่อน"
            if not has_api_key
            else None,
        }
    else:
        try:
            enriched = await asyncio.wait_for(
                _run_gemini_enrich(request.text, hotels), timeout=MATCH_TIMEOUT_SECONDS
            )
            notice = "🤖 AI ไม่สามารถสรุปผลได้ในครั้งนี้ ระบบจึงแสดงผลจากการค้นหาเชิงความหมายในฐานข้อมูลให้ก่อน"
        except asyncio.TimeoutError:
            enriched = None
            notice = "⏳ ระบบกำลังมีคำขอจำนวนมาก ระบบจึงแสดงผลจากการค้นหาเชิงความหมายในฐานข้อมูลให้ก่อน"
        except Exception:
            enriched = None
            notice = "🤖 เชื่อมต่อ AI ไม่สำเร็จ (เครือข่ายหรือบริการขัดข้อง) ระบบจึงแสดงผลจากการค้นหาเชิงความหมายในฐานข้อมูลให้ก่อน"

        if enriched is None:
            result = {**local_result, "isFallback": True, "fallbackNotice": notice}
        else:
            result = {**enriched, "isFallback": False, "fallbackNotice": None}

    if not result["isFallback"]:
        match_cache.set(cache_key, result)

    return MatchResponse(**result)
