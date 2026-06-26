from enum import Enum

from pydantic import BaseModel, Field


class MatchRequest(BaseModel):
    text: str = Field(min_length=1)


class MatchItem(BaseModel):
    hotelName: str
    reason: str


class MatchResponse(BaseModel):
    summary: str
    matches: list[MatchItem]
    isFallback: bool
    fallbackNotice: str | None = None
    job_id: str | None = None


class JobStatus(str, Enum):
    processing = "processing"
    ready = "ready"
    fallback = "fallback"


class MatchStatusResponse(BaseModel):
    status: JobStatus
    result: MatchResponse | None = None
