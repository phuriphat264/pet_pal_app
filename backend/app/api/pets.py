import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..core.deps import get_current_user
from ..db.session import get_db
from ..models.pet import Pet, PetMedicalHistory
from ..models.user import User
from ..schemas.pet import MedicalHistoryEntry, PetCreate, PetResponse, PetUpdate

router = APIRouter(prefix="/pets", tags=["pets"])


async def _get_owned_pet(pet_id: uuid.UUID, user: User, db: AsyncSession) -> Pet:
    pet = await db.scalar(
        select(Pet).where(Pet.id == pet_id).options(selectinload(Pet.medical_history))
    )
    if pet is None or (pet.owner_id != user.id and user.role.value != "admin"):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pet not found")
    return pet


@router.get("", response_model=list[PetResponse])
async def list_my_pets(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)) -> list[Pet]:
    result = await db.scalars(
        select(Pet)
        .where(Pet.owner_id == user.id)
        .options(selectinload(Pet.medical_history))
        .order_by(Pet.created_at)
    )
    return list(result.all())


@router.post("", response_model=PetResponse, status_code=status.HTTP_201_CREATED)
async def create_pet(
    payload: PetCreate, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> Pet:
    pet = Pet(owner_id=user.id, **payload.model_dump())
    db.add(pet)
    await db.commit()
    await db.refresh(pet, attribute_names=["medical_history"])
    return pet


@router.get("/{pet_id}", response_model=PetResponse)
async def get_pet(
    pet_id: uuid.UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> Pet:
    return await _get_owned_pet(pet_id, user, db)


@router.patch("/{pet_id}", response_model=PetResponse)
async def update_pet(
    pet_id: uuid.UUID,
    payload: PetUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Pet:
    pet = await _get_owned_pet(pet_id, user, db)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(pet, field, value)
    await db.commit()
    await db.refresh(pet, attribute_names=["medical_history"])
    return pet


@router.delete("/{pet_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_pet(
    pet_id: uuid.UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
) -> None:
    pet = await _get_owned_pet(pet_id, user, db)
    await db.delete(pet)
    await db.commit()


@router.post("/{pet_id}/medical-history", response_model=PetResponse, status_code=status.HTTP_201_CREATED)
async def add_medical_history(
    pet_id: uuid.UUID,
    payload: MedicalHistoryEntry,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Pet:
    pet = await _get_owned_pet(pet_id, user, db)
    entry = PetMedicalHistory(pet_id=pet.id, date=payload.date, event=payload.event, vet=payload.vet)
    db.add(entry)
    await db.commit()
    await db.refresh(pet, attribute_names=["medical_history"])
    return pet
