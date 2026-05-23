from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

class Address(BaseModel):
    street: str
    city: str
    zip_code: Optional[str] = None

class UserCreate(BaseModel):
    name: str
    email: str
    address: Optional[Address] = None

@router.post("/users")
async def create_user(user: UserCreate):
    # Simulate saving to DB
    user_data = {
        "name": user.name,
        "email": user.email,
        "street": user.address.street,  # This line causes the error when address is None
        "city": user.address.city,
    }
    return {"id": 1, **user_data}
