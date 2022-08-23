import random, sqlite3, os
from time import time
from typing import Optional
from fastapi import Body, FastAPI, Form, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm

from database import *
from classes import *

db_path = "./databases"

users = UsersDB(f"{db_path}/main.db")

app = FastAPI()
oauth2_scheme = OAuth2PasswordBearer(
	tokenUrl="/api/v1/auth/login",
	scopes={"me": "Read information about the current user"}
)

@app.get("/")
async def api_root():
	return {"status": "online"}

async def get_current_user(token: str = Depends(oauth2_scheme)):
	user = users.get_user_from_token(token)
	if not user:
		raise HTTPException(
			status_code=status.HTTP_401_UNAUTHORIZED,
			detail="Invalid token",
			headers={"WWW-Authenticate": "Bearer"}
		)
	return user

async def get_current_active_user(current_user: User = Depends(get_current_user)):
	if not current_user.enabled:
		raise HTTPException(status_code=400, detail="Inactive user")
	return current_user

# ------------------
# AUTH ENDPOINTS
# ------------------
@app.get("/api/v1/auth/register")
async def register_user():
	return