import asyncio
import json
import logging
import os
import uuid

import redis.asyncio as aioredis
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

from .api import admin, auth, bookings, cameras, chat, hotels, notifications, partners, payments, pets, users
from .cache import TTLCache
from .db.session import get_db
from .match_service import local_match_result, run_gemini_enrichment, vector_search_hotels
from .match_schemas import JobStatus, MatchRequest, MatchResponse, MatchStatusResponse
from .services.storage_service import ensure_bucket

load_dotenv()

CACHE_TTL_SECONDS = float(os.environ.get("MATCH_CACHE_TTL_SECONDS", "600"))
CACHE_MAXSIZE = int(os.environ.get("MATCH_CACHE_MAXSIZE", "500"))
GEMINI_MAX_CONCURRENT = int(os.environ.get("GEMINI_MAX_CONCURRENT", "3"))
MATCH_TIMEOUT_SECONDS = float(os.environ.get("MATCH_TIMEOUT_SECONDS", "40"))
REDIS_URL = os.environ.get("REDIS_URL", "redis://redis:6379")
JOB_TTL = 300

match_cache = TTLCache(ttl_seconds=CACHE_TTL_SECONDS, maxsize=CACHE_MAXSIZE)
_gemini_sem = asyncio.Semaphore(GEMINI_MAX_CONCURRENT)
_redis: aioredis.Redis | None = None

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
app.include_router(cameras.stream_router)
app.include_router(chat.router)
app.include_router(notifications.router)
app.include_router(payments.router)


@app.on_event("startup")
async def _startup() -> None:
    global _redis
    try:
        _redis = aioredis.from_url(REDIS_URL, decode_responses=True)
        await _redis.ping()
    except Exception:
        _redis = None
    await ensure_bucket()


async def _run_gemini_enrich(text: str, hotels_list: list) -> dict | None:
    api_key = os.environ.get("GEMINI_API_KEY", "")
    async with _gemini_sem:
        return await asyncio.to_thread(run_gemini_enrichment, text, hotels_list, api_key)


async def _gemini_background(job_id: str, text: str, hotels_list: list, cache_key: str) -> None:
    try:
        enriched = await asyncio.wait_for(
            _run_gemini_enrich(text, hotels_list), timeout=MATCH_TIMEOUT_SECONDS
        )
        if enriched:
            match_cache.set(cache_key, {**enriched, "isFallback": False, "fallbackNotice": None})
            payload = json.dumps({"status": "ready", **enriched, "isFallback": False, "fallbackNotice": None})
        else:
            payload = json.dumps({"status": "fallback"})
    except Exception as e:
        logger.error("Gemini enrichment failed: %s", e)
        payload = json.dumps({"status": "fallback"})

    if _redis:
        await _redis.setex(f"match_job:{job_id}", JOB_TTL, payload)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/api/match", response_model=MatchResponse)
async def match(request: MatchRequest, db: AsyncSession = Depends(get_db)) -> MatchResponse:
    cache_key = TTLCache.normalize_key(request.text)
    cached = match_cache.get(cache_key)
    if cached is not None:
        return MatchResponse(**cached, job_id=None)

    hotels_list = await vector_search_hotels(request.text, db)
    local_result = local_match_result(hotels_list)

    api_key = os.environ.get("GEMINI_API_KEY", "")
    has_api_key = bool(api_key) and api_key not in ("YOUR_API_KEY_HERE", "<CHANGE_ME>")

    if not has_api_key or not hotels_list:
        notice = "⚠️ ยังไม่ได้ตั้งค่า AI (API Key)" if not has_api_key else None
        return MatchResponse(**local_result, isFallback=True, fallbackNotice=notice, job_id=None)

    job_id = str(uuid.uuid4())
    if _redis:
        await _redis.setex(f"match_job:{job_id}", JOB_TTL, json.dumps({"status": "processing"}))

    asyncio.create_task(_gemini_background(job_id, request.text, hotels_list, cache_key))

    return MatchResponse(
        **local_result,
        isFallback=True,
        fallbackNotice="🔄 AI กำลังวิเคราะห์ผลให้ละเอียดขึ้น รอสักครู่...",
        job_id=job_id,
    )


@app.get("/api/match/status/{job_id}", response_model=MatchStatusResponse)
async def match_status(job_id: str) -> MatchStatusResponse:
    if not _redis:
        raise HTTPException(status_code=503, detail="Queue unavailable")
    raw = await _redis.get(f"match_job:{job_id}")
    if not raw:
        raise HTTPException(status_code=404, detail="Job expired or not found")
    payload = json.loads(raw)
    status = payload.get("status")
    if status == "processing":
        return MatchStatusResponse(status=JobStatus.processing)
    if status == "fallback":
        return MatchStatusResponse(status=JobStatus.fallback)
    return MatchStatusResponse(
        status=JobStatus.ready,
        result=MatchResponse(**{k: v for k, v in payload.items() if k != "status"}, job_id=job_id),
    )
