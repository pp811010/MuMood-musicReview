
from pydantic import BaseModel
from typing import Optional

class UserCreate(BaseModel):
    email: str
    username: str
    favorite_genres: str
    bio: str
    password: str

class UserResponse(BaseModel):
    id : int
    username: str
    email: str
    favorite_genres: str
    bio : str
    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: str
    password: str
    
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None