import random, sqlite3, os
from time import time
from typing import Optional
from fastapi import Body, FastAPI, Form, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from hashlib import sha512, sha256, sha384

from database import *
from classes import *

db_path = "./databases"

databases = {
	"users": UsersDB(f"{db_path}/main.db"),
	"subjects": SubjectsDB(f"{db_path}/main.db"),
	"user-subjects": UserSubjectDB(f"{db_path}/main.db"),
	"classes": ClassDB(f"{db_path}/main.db"),
	"class-student": ClassStudentDB(f"{db_path}/main.db"),
	"homework": HomeworkDB(f"{db_path}/main.db")
}

tags_metadata = [
	{
		"name": "Authentication",
		"description": "User authentication. Most of these do **not** require the client to be authenticated to access.",
	},
	{
		"name": "Users",
		"description": "Operations to do with managing users and retrieving information. **All** sensitive information is hidden from results.",
	},
	{
		"name": "Subjects",
		"description": "Operations to manage subjects."
	},
	{
		"name": "Timetable",
		"description": "Operations to manage a user's own timetable."
	},
	{
		"name": "Classes",
		"description": "Operations to manage classes, their students and homework set."
	},
	{
		"name": "Homework",
		"description": "Operations to manage a user's homework."
	}
]


app = FastAPI(title="Planner App API", description="API used for the backend of the planner app.", version="0.2.0b")
oauth2_scheme = OAuth2PasswordBearer(
	tokenUrl="/api/v1/auth/login"
)

@app.get("/")
async def root():
	"""
	Returns if the API is online. Can be used as a simple check I guess?
	"""
	return {"status": "online"}

async def get_current_user(token: str = Depends(oauth2_scheme)):
	"""
	Gets the user that the web request is logged in as.
	
	Raises a 401 if invalid, or returns the User.
	"""
	user = databases["users"].get_user_from_session(token)
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
@app.post("/api/v1/auth/register", tags=["Authentication"])
async def register(username: str = Form(...), password: str = Form(...)):
	"""
	Registers a user with a username and password.

	Also ensures a duplicate username is not chosen.
	"""
	user = databases["users"].get_user_from_username(username)
	if user is not None:
		# If the username is taken, a user will be returned.
		# Therefore we cannot let them have that username.
		raise HTTPException(status_code=400, detail="Username is unavaliable.")

	token = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=32))
	uid = databases["users"].get_next_uid()

	salt = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=16))
	for _ in range(100):
		# This process is called salting.
		# It means that if a malicious individual gets access to the database,
		# They have no way of retrieving the passwords stored since they go through this process of scrambling.
		# We store the salt in plaintext as to make sure that we can do this same process to allow the user to login.
		for method in [sha256, sha384, sha512]:
			password = method(f"{salt}{password}".encode()).hexdigest()

	user = User(
		uid=uid,
		username=username,
		password=password,
		salt=salt,
		created_at=time(),
		permissions=Permissions.Student, # TODO: Change this to check register code.
		token=OAuthToken(access_token=token, uid=uid)
	)
	databases["users"].add_user(user)

	# Gives the user their token.
	# This means they are now logged in as this user.
	return {"access_token": token, "token_type": "Bearer"}

@app.post("/api/v1/auth/login", tags=["Authentication"])
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
	"""
	Logs a user in with their username and password.
	"""
	user = databases["users"].get_user_from_username(form_data.username)
	password = form_data.password
	for _ in range(100):
		# This process is called salting.
		# It means that if a malicious individual gets access to the database,
		# They have no way of retrieving the passwords stored since they go through this process of scrambling.
		# We store the salt in plaintext as to make sure that we can do this same process to allow the user to login.
		for method in [sha256, sha384, sha512]:
			password = method(f"{user.salt}{password}".encode()).hexdigest()
	if not user or user.password != password:
		raise HTTPException(status_code=400, detail="Incorrect username or password")
	
	token = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=32))
	user.session = OAuthToken(access_token=token, uid=user.uid)

	databases["users"].update_user(user)

	return {"access_token": token, "token_type": "Bearer"}

@app.get("/api/v1/auth/logout", tags=["Authentication"])
async def logout(current_user: User = Depends(get_current_user)):
	"""
	Invalidates the logged in user's token, effectively logging them out.
	"""
	current_user.token = None
	databases["users"].update_user(current_user)
	return {"Status": "OK"}

# ------------------
# USER ENDPOINTS
# ------------------
@app.get("/api/v1/users/@me", tags=["Users"])
async def get_me(current_user: User = Depends(get_current_user)):
	"""
	Returns information about the current user.

	This also removes sensitive pieces of information as to protect the user from attacks.
	"""
	return current_user.remove("session", "password", "salt")

@app.get("/api/v1/users/{user_id}", tags=["Users"])
async def get_user(user_id: int, user: User = Depends(get_current_user)):
	"""
	Returns information about another user.
	
	This removes many sensitive pieces of information from the result as to protect users.

	Raises 404 if the user specified is not found.
	"""
	user = databases["users"].get_user_from_uid(user_id)
	if not user:
		raise HTTPException(status_code=404, detail="User not found")
	return user.remove("session", "password", "salt")

# ------------------
# SUBJECT ENDPOINTS
# ------------------
@app.get("/api/v1/subjects", tags=["Subjects"])
async def get_subjects(user: User = Depends(get_current_user)):
	"""
	Gets all subjects avaliable in the database.
	"""
	sjs = databases["subjects"].get_subjects()
	if sjs is None:
		return {"status": "error", "message": "No subjects found."}
	return {"status": "success", "data": sjs}

@app.get("/api/v1/subjects/name-{subject_name}", tags=["Subjects"])
async def get_subject_by_name(subject_name: str, user: User = Depends(get_current_user)):
	"""
	Gets all subjects which match a certain name.
	"""
	sjs = databases["subjects"].get_subjects_by_name(subject_name)
	if sjs is None:
		return {"status": "error", "message": "No subjects found."}
	return {"status": "success", "data": sjs}

@app.get("/api/v1/subjects/id-{subject_id}", tags=["Subjects"])
async def get_subject_by_id(id: int, user: User = Depends(get_current_user)):
	"""
	Gets the subject with a specific ID.
	"""
	sjs = databases["subjects"].get_subject_by_id(id)
	if sjs is None:
		return {"status": "error", "message": "No subjects found."}
	return {"status": "success", "data": sjs}

@app.post("/api/v1/subjects", tags=["Subjects"])
async def create_subject(name: str = Form(...), teacher: str = Form(...), room: str = Form(...), user: User = Depends(get_current_user)):
	"""
	This allows for a user to create a subject.

	If the exact same subject already exists, it will not be recreated.

	Returns the ID of the created subject.
	"""
	exists = databases["subjects"].get_subjects_by_name(name)
	if exists is not None:
		for subject in exists:
			if subject.teacher == teacher and subject.room == room:
				# If we find that this specific subject already exists,
				# We lie and say that we created it, but return the old id instead of a new one.
				return {"status": "success", "id": subject.id}
	databases["subjects"].add_subject(Subject(
		name=name,
		teacher=teacher,
		room=room
	))
	return {"status": "success", "id": databases["subjects"].get_next_id() - 1}

# ------------------
# TIMETABLE ENDPOINTS
# ------------------

@app.post("/api/v1/timetable", tags=["Timetable"])
async def add_timetable_subject(subject_id: int = Form(...), day: int = Form(...), period: int = Form(...), user: User = Depends(get_current_user)):
	result = databases["user-subjects"].create_connection(user.uid, subject_id, day, period)
	if result:
		return {"status": "success"}
	return {"status": "error"}

@app.delete("/api/v1/timetable", tags=["Timetable"])
async def remove_timetable_subject(subject_id: int = Form(...), day: int = Form(...), period: int = Form(...), user: User = Depends(get_current_user)):
	result = databases["user-subjects"].remove_connection(user.uid, subject_id, day, period)
	if result:
		return {"status": "success"}
	return {"status": "error"}

@app.get("/api/v1/timetable", tags=["Timetable"])
async def get_timetable(user: User = Depends(get_current_user)):
	result = databases["user-subjects"].get_timetable(user.uid)
	timetable = result.get_client_format()

	# Here, instead of directly using the variable, I am getting indexes as this will allow me to modify the
	# Timetable in-place instead of having to create a copy and waste memory.
	for day in range(len(timetable)):
		for period in range(len(timetable[day])):
			timetable[day][period] = databases["subjects"].get_subject_by_id(timetable[day][period])
	return {"status": "success", "data": timetable}

# ------------------
# HOMEWORK ENDPOINTS
# ------------------

@app.get("/api/v1/homework", tags=["Homework"])
async def get_homework(user: User = Depends(get_current_user)):
	result = databases["homework"].get_homework_for_user(user.uid)
	return {"status": "success", "data": result}

@app.post("/api/v1/homework", tags=["Homework"])
async def create_homework(name: str = Form(...), due_date: int = Form(...), user: User = Depends(get_current_user)):
	databases["homework"].create_homework(user.uid, name, due_date)
	return {"status": "success"}

@app.put("/api/v1/homework", tags=["Homework"])
async def complete_homework(id: int = Form(...), user: User = Depends(get_current_user)):
	homework = databases["homework"].get_homework(id)
	if homework is None:
		return {"status": "error", "message": "Homework doesn't exist."}
	if homework.user_id != user.uid:
		return {"status": "error", "message": "Not your homework."}
	homework.completed = True
	databases["homework"].update_homework(homework)
	return {"status": "success"}

@app.delete("/api/v1/homework", tags=["Homework"])
async def delete_homework(id: int = Form(...), user: User = Depends(get_current_user)):
	homework = databases["homework"].get_homework(id)
	if homework is None:
		return {"status": "error", "message": "Homework doesn't exist."}
	databases["homework"].delete_homework(id)
	return {"status": "success"}