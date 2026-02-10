from typing import Union
from app.routes import auth
from app.routes import admin
from app.routes import favourites

from fastapi import FastAPI

app = FastAPI()
app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(favourites.router)
