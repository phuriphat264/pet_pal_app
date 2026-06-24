import uuid

from pydantic import BaseModel, ConfigDict


class HotelRoomBase(BaseModel):
    room_type: str
    price_surcharge: int = 0
    description: str | None = None
    available: bool = True


class HotelRoomCreate(HotelRoomBase):
    pass


class HotelRoomUpdate(BaseModel):
    room_type: str | None = None
    price_surcharge: int | None = None
    description: str | None = None
    available: bool | None = None


class HotelRoomResponse(HotelRoomBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    hotel_id: uuid.UUID


class HotelImageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    url: str
    sort_order: int


class HotelBase(BaseModel):
    name: str
    location: str | None = None
    distance_text: str | None = None
    base_price: int = 0
    icon_name: str | None = None
    color_hex: str | None = None
    description: str | None = None
    service_type: str | None = None
    available: bool = True
    tags: list[str] = []
    ai_tags: list[str] = []
    pet_types: list[str] = []


class HotelCreate(HotelBase):
    pass


class HotelUpdate(BaseModel):
    name: str | None = None
    location: str | None = None
    distance_text: str | None = None
    base_price: int | None = None
    icon_name: str | None = None
    color_hex: str | None = None
    description: str | None = None
    service_type: str | None = None
    available: bool | None = None
    tags: list[str] | None = None
    ai_tags: list[str] | None = None
    pet_types: list[str] | None = None


class HotelResponse(HotelBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    partner_id: uuid.UUID | None
    rating: float
    reviews_count: int
    images: list[HotelImageResponse] = []
    rooms: list[HotelRoomResponse] = []


class HotelListItem(HotelBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    rating: float
    reviews_count: int
    images: list[HotelImageResponse] = []
