from typing import Union
from app.routes import auth

from fastapi import FastAPI

app = FastAPI()
app.include_router(auth.router)
