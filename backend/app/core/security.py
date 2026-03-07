from datetime import datetime, timedelta
from typing import Optional
from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext
import jwt
from app.core.config import settings
from app.database import get_db
from app.schemas.user import TokenData
from app.models import User


pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/users/login/")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """ตรวจสอบ password"""
    return pwd_context.verify(plain_password, hashed_password)

def get_pwd_hash(password: str) -> str:
    """Hash password"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """สร้าง JWT token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    
    to_encode.update({"exp": expire})

    encoded_jwt = jwt.encode(to_encode, "MuMoodPopoWanPound", algorithm= "HS256")
    return encoded_jwt

def create_refresh_token(data: dict) -> str:        
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def verify_token(token: str, expected_type: str = "access") -> TokenData:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        
        if payload.get("type") != expected_type: 
            raise HTTPException(status_code=401, detail="Invalid token type")
        
        email: str = payload.get("sub")
        if email is None:
            raise HTTPException(status_code=401, detail="Could not validate credentials")
        
        return TokenData(email=email)
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Could not validate credentials")

def verifty_token(token: str) -> TokenData:
    """Verify JWT token"""
    try: 
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
) -> User: 
    """ดึง current user จาก JWT token"""
    token_data = verifty_token(token)
    
    user_query = select(User).where(User.email == token_data.email)
    result = await db.execute(user_query)
    user = result.scalars().first()
    
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user

async def get_current_active_user( 
    current_user: User = Depends(get_current_user)
) -> User:  # ⭐ เพิ่ม return type
    """ตรวจสอบว่า user active"""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user") 
    return current_user