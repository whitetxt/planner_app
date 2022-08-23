import random, sqlite3, os
from time import time
from typing import Optional
from fastapi import Body, FastAPI, Form, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from email_validator import validate_email, EmailNotValidError
from hashlib import sha512, sha256, sha384

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
	"""
	Returns if the API is online. Can be used as a simple check I guess?
	"""
	return {"status": "online"}

async def get_current_user(token: str = Depends(oauth2_scheme)):
	"""
	Gets the user that the web request is logged in as.
	
	Raises a 401 if invalid, or returns the User.
	"""
	user = users.get_user_from_token(token)
	if user is None:
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
	"""
	Registers a user with a username, password and email.

	Also ensures a duplicate username is not chosen.
	"""
	user = users.get_user_from_username(username)
	if user is not None:
		# If the username is taken, a user will be returned.
		# Therefore we cannot let them have that username.
		raise HTTPException(status_code=400, detail="Username is unavaliable.")

	try:
		# Check that the email address is valid.
		validation = validate_email(email, check_deliverability=True)
		email = validation.email
	except EmailNotValidError as e:
		# Email is not valid.
		raise HTTPException(status_code=400, detail=str(e))

	token = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=32))
	uid = users.get_next_uid()

	salt = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=16))
	for _ in range(100):
		# This process is called salting.
		# It means that if a malicious individual gets access to the database,
		# They have no way of retrieving the passwords stored since they go through this process of scrambling.
		# We store the salt in plaintext as to make sure that we can do this same process to allow the user to login.
		for method in [sha256, sha384, sha512]:
			password = method(f"{salt}{password}").hexdigest()

	user = User(
		uid=uid,
		username=username,
		password=password,
		salt=salt,
		creation_time=time(),
		permissions=Permissions.Student, # TODO: Change this to check register code.
		token=OAuthToken(access_token=token, uid=uid)
	)
	users.add_user(user)

	# Gives the user their token.
	# This means they are now logged in as this user.
	return {"access_token": token, "token_type": "Bearer"}

@app.post("/api/v1/auth/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
	"""
	Logs a user in with their username and password.
	"""
	user = users.get_user_from_username(form_data.username)
	password = form_data.password
	for _ in range(100):
		# This process is called salting.
		# It means that if a malicious individual gets access to the database,
		# They have no way of retrieving the passwords stored since they go through this process of scrambling.
		# We store the salt in plaintext as to make sure that we can do this same process to allow the user to login.
		for method in [sha256, sha384, sha512]:
			password = method(f"{user.salt}{password}").hexdigest()
	if not user or user.password != password:
		raise HTTPException(status_code=400, detail="Incorrect username or password")
	
	token = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=32))
	user.session = OAuthToken(access_token=token, uid=user.uid)

	return {"access_token": token, "token_type": "Bearer"}

@app.get("/api/v1/auth/logout")
async def logout(current_user: User = Depends(get_current_user)):
	"""
	Invalidates the logged in user's token, effectively logging them out.
	"""
	current_user.token = None
	users.update_user(current_user)
	return {"Status": "OK"}

# ------------------
# USER ENDPOINTS
# ------------------
@app.get("/api/v1/users/@me")
async def api_get_me(current_user: User = Depends(get_current_user)):
	"""
	Returns information about the current user.

	This also removes sensitive pieces of information as to protect the user from attacks.
	"""
	return current_user.remove("session", "password", "salt")

@app.get("/api/v1/users/{user_id}")
async def api_get_user(user_id: int, user: User = Depends(get_current_user)):
	"""
	Returns information about another user.
	
	This removes many sensitive pieces of information from the result as to protect users.

	Raises 404 if the user specified is not found.
	"""
	user = users.get_user_from_uid(user_id)
	if not user:
		raise HTTPException(status_code=404, detail="User not found")
	return user.remove("session", "password", "email", "salt")

# ------------------
# SUBJECT ENDPOINTS
# ------------------
@app.get("/api/v1/subjects")
async def api_get_subjects(user: User = Depends(get_current_user)):
	return