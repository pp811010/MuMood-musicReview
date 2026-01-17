from fastapi import APIRouter, Depends, HTTPException
from app.core.security import *
from app.schemas.user import *
from app.core.security import *
from app.models import *
from app.database import SessionDep
from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter(
    prefix="/users",
    tags=["users"]
)

@router.post("/register/", response_model=UserResponse)
async def register_user(user: UserCreate, db: SessionDep):
    db_user = select(User).where(User.email == user.email)
    result = await db.execute(db_user)
    db_user = result.scalars().first()
    if db_user:
        raise HTTPException(status_code=400, detail="User already registered")

    hash_password = get_pwd_hash(user.password)
    new_user = User(
        username=user.username,
        email = user.email,
        favorite_genres=user.favorite_genres,
        password_hash = hash_password,
        bio = user.bio
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

@router.post("/login/", response_model=Token)
async def login_for_access_token(db: SessionDep,form_data: OAuth2PasswordRequestForm = Depends()):
    user_query = select(User).where(User.email == form_data.username)
    result = await db.execute(user_query)
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    if not verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    

    access_token_expires = timedelta(minutes= 30)
    access_token = create_acces_token(
        data={"sub": user.email},
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/profile", response_model=UserResponse)
async def get_profile(db: SessionDep, current_user: User =  Depends(get_current_active_user)):
    return current_user

@router.get("/verity-token")
def verity_token_endpoint(current_user: User = Depends(get_current_active_user)):
    return {"valid": True, "user": {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "purpose": current_user.purpose,
    }}

@router.get("/{user_id}", response_model=UserResponse)
async def read_user(user_id: int, db: SessionDep, current_user: User = Depends(get_current_active_user)):
    db_user = select(User).where(User.id == user_id)
    result = await db.execute(db_user)
    db_user = result.scalars().first()
    if db_user is None:
        raise HTTPException(status_code=404, detail=f"User with ID {user_id} not found")
    return db_user

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(user_id: int, user: UserCreate, db: SessionDep, current_user: User = Depends(get_current_active_user)):
    db_user = select(User).where(User.id == user_id)
    result = await db.execute(db_user)
    db_user = result.scalars().first()
    if db_user is None:
        raise HTTPException(status_code=404, detail=f"User with ID {user_id} not found")
    
    db_user.name = user.name
    db_user.email = user.email
    db_user.purpose = user.purpose

    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    return db_user

@router.delete("/{user_id}")
async def delete_user(user_id:int, db: SessionDep, current_user: User = Depends(get_current_active_user)):
    db_user = select(User).where(User.id == user_id)
    result = await db.execute(db_user)
    user = result.scalars().first()
    if( user is None):
        raise HTTPException(status_code=404, detail=f"User with ID {user_id} not found")
    
    if( current_user.id == user_id):
        raise HTTPException(status_code=404, detail="You can not delete yourself")
    
    await db.delete(user)
    db.commit()
    return {"massage": "User deleted"}