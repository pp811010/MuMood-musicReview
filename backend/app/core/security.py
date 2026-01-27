from datetime import datetime, timedelta
from typing import Optional
from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext
import jwt

from app.database import get_db
from app.schemas.user import TokenData
from app.models import User

# ⭐ ลบออก (ย้ายไป setting.py)
# SECRET_KEY = "codewithfuengpopo"
# ALGORITHM = "HS256"
# TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/users/login/")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """ตรวจสอบ password"""
    return pwd_context.verify(plain_password, hashed_password)

def get_pwd_hash(password: str) -> str:
    """Hash password"""
    return pwd_context.hash(password)

def create_acces_token(data: dict, expires_delta: Optional[timedelta] = None):
    """สร้าง JWT token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    
    to_encode.update({"exp": expire})
    
    # ⭐ ใช้จาก settings
    encoded_jwt = jwt.encode(to_encode, "MuMoodPopoWanPound", algorithm= "HS256")
    return encoded_jwt

def verifty_token(token: str) -> TokenData:
    """Verify JWT token"""
    try: 
        # ⭐ ใช้จาก settings
        payload = jwt.decode(token, "MuMoodPopoWanPound", algorithms=[ "HS256"])
        email: str = payload.get("sub")
        if email is None:
            raise HTTPException(status_code=401, detail="Could not validate credentials")
        token_data = TokenData(email=email)
        return token_data
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Could not validate credentials")

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> User:  # ⭐ เพิ่ม return type
    """ดึง current user จาก JWT token"""
    token_data = verifty_token(token)
    
    user_query = select(User).where(User.email == token_data.email)
    result = await db.execute(user_query)
    user = result.scalars().first()
    
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user

async def get_current_active_user(  # ⭐ เพิ่ม async
    current_user: User = Depends(get_current_user)
) -> User:  # ⭐ เพิ่ม return type
    """ตรวจสอบว่า user active"""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")  # ⭐ แก้ 404 → 400
    return current_user