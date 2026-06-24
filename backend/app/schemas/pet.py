import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict


class MedicalHistoryEntry(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID | None = None
    date: date
    event: str
    vet: str | None = None


class PetBase(BaseModel):
    name: str
    breed: str | None = None
    age: str | None = None
    weight: str | None = None
    height: str | None = None
    temp: str | None = None
    heart_rate: str | None = None
    gender: str | None = None
    dob: date | None = None
    color_desc: str | None = None
    vaccine: str | None = None
    next_vet: str | None = None
    last_vet: str | None = None
    chip_id: str | None = None
    allergies: str | None = None
    food: str | None = None
    feeding_times: str | None = None
    neutered: str | None = None
    traits: list[str] = []
    icon_name: str | None = None
    color_hex: str | None = None


class PetCreate(PetBase):
    pass


class PetUpdate(BaseModel):
    name: str | None = None
    breed: str | None = None
    age: str | None = None
    weight: str | None = None
    height: str | None = None
    temp: str | None = None
    heart_rate: str | None = None
    gender: str | None = None
    dob: date | None = None
    color_desc: str | None = None
    vaccine: str | None = None
    next_vet: str | None = None
    last_vet: str | None = None
    chip_id: str | None = None
    allergies: str | None = None
    food: str | None = None
    feeding_times: str | None = None
    neutered: str | None = None
    traits: list[str] | None = None
    icon_name: str | None = None
    color_hex: str | None = None


class PetResponse(PetBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    owner_id: uuid.UUID
    medical_history: list[MedicalHistoryEntry] = []
