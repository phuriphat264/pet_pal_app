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
