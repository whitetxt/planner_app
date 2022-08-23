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

# ------------------
# AUTHENTICATION ENDPOINTS
# ------------------
@app.post("/api/v1/auth/register")
async def register(username: str = Form(...), password: str = Form(...), email: str = Form(...)):
	username = users.get_user_from_username(username)
	if user is not None:
		raise HTTPException(status_code=400, detail="Username is unavaliable.")

	token = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=32))
	uid = users.get_next_uid()

	user = User(
		uid=uid,
		username=username,
		password=password,
		creation_time=time(),
		last_login=time(),
		enabled=True,
		token=OAuthToken(access_token=token, uid=uid)
	)
	users.add_user(user)

	return {"access_token": token, "token_type": "Bearer"}

@app.post("/api/v1/auth/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
	user = users.get_user_from_username(form_data.username)
	if not user or user.password != form_data.password:
		print("Invalid username or password")
		raise HTTPException(status_code=400, detail="Incorrect username or password")
	
	token = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=32))
	user.session = OAuthToken(access_token=token, uid=user.uid)

	return {"access_token": token, "token_type": "Bearer"}

@app.get("/api/v1/auth/logout")
async def logout(current_user: User = Depends(get_current_user)):
	current_user.token = None
	users.update_user(current_user)
	return {"Status": "OK"}

# ------------------
# USER ENDPOINTS
# ------------------
@app.get("/api/v1/users/@me")
async def api_get_me(current_user: User = Depends(get_current_user)):
	"""
	This gets information about the current user."""
	return current_user.remove("session", "password", "salt")

@app.get("/api/v1/users/{user_id}")
async def api_get_user(user_id: int, user: User = Depends(get_current_user)):
	user = users.get_user_from_uid(user_id)
	if not user:
		raise HTTPException(status_code=404, detail="User not found")
	return user.remove("session", "password", "email", "salt")