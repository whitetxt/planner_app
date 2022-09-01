import random, uvicorn, os
from time import time
from fastapi import FastAPI, Form, HTTPException, Depends, status, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from hashlib import sha512, sha256, sha384

from database import *
from classes import *

db_path = "./databases"

os.makedirs(db_path, exist_ok=True)

Users_DB = UsersDB(f"{db_path}/main.db")
Subjects_DB = SubjectsDB(f"{db_path}/main.db")
User_Subjects_DB = UserSubjectDB(f"{db_path}/main.db")
Classes_DB = ClassDB(f"{db_path}/main.db")
User_Class_DB = ClassStudentDB(f"{db_path}/main.db")
Homework_DB = HomeworkDB(f"{db_path}/main.db")
Marks_DB = MarkDB(f"{db_path}/main.db")
Events_DB = EventDB(f"{db_path}/main.db")
User_Events_DB = UserEventDB(f"{db_path}/main.db")
Registration_Code_DB = RegistrationCodeDB(f"{db_path}/main.db")

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
	},
	{
		"name": "Marks",
		"description": "Operations to manage a user's marks."
	}
]

app = FastAPI(title="Planner App API",
			description="API used for the backend of the planner app.",
			version="0.4.2_beta",
			tags_metadata=tags_metadata)

oauth2_scheme = OAuth2PasswordBearer(
	tokenUrl="/api/v1/auth/login"
)

@app.get("/onlineCheck")
async def online_check():
	"""
	Returns if the API is online.
	"""
	return {"status": "success"}

async def get_current_user(token: str = Depends(oauth2_scheme)):
	"""
	Gets the user that the web request is logged in as.
	
	Raises a 401 if invalid, or returns the User.
	"""
	user = Users_DB.get_user_from_session(token)
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
async def register(username: str = Form(...), password: str = Form(...), registration_code: str = Form(None)):
	"""
	Registers a user with a username and password.

	Also ensures a duplicate username is not chosen.
	"""
	user = Users_DB.get_user_from_username(username)
	if user is not None:
		# If the username is taken, a user will be returned.
		# Therefore we cannot let them have that username.
		raise HTTPException(status_code=400, detail="Username is unavaliable.")

	token = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=32))
	uid = Users_DB.get_next_uid()

	salt = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=16))
	for _ in range(100):
		# This process is called salting.
		# It means that if a malicious individual gets access to the database,
		# They have no way of retrieving the passwords stored since they go through this process of scrambling.
		# We store the salt in plaintext as to make sure that we can do this same process to allow the user to login.
		for method in [sha256, sha384, sha512]:
			password = method(f"{salt}{password}".encode()).hexdigest()

	permissions = Registration_Code_DB.get_permissions(registration_code)
	if registration_code is None or permissions is None:
		permissions = Permissions.Student

	user = User(
		uid=uid,
		username=username,
		password=password,
		salt=salt,
		created_at=time(),
		permissions=permissions,
		session=OAuthToken(access_token=token, uid=uid)
	)
	Users_DB.add_user(user)

	# Gives the user their token.
	# This means they are now logged in as this user.
	return {"status": "success", "data": {"access_token": token, "token_type": "Bearer"}}

@app.post("/api/v1/auth/login", tags=["Authentication"])
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
	"""
	Logs a user in with their username and password.
	"""
	user = Users_DB.get_user_from_username(form_data.username)
	if not user:
		raise HTTPException(status_code=400, detail="Incorrect username or password")
	password = form_data.password
	for _ in range(100):
		# This process is called salting.
		# It means that if a malicious individual gets access to the database,
		# They have no way of retrieving the passwords stored since they go through this process of scrambling.
		# We store the salt in plaintext as to make sure that we can do this same process to allow the user to login.
		for method in [sha256, sha384, sha512]:
			password = method(f"{user.salt}{password}".encode()).hexdigest()
	if user.password != password:
		raise HTTPException(status_code=400, detail="Incorrect username or password")
	
	token = "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=32))
	user.session = OAuthToken(access_token=token, uid=user.uid)

	Users_DB.update_user(user)

	return {"status": "success", "data": {"access_token": token, "token_type": "Bearer"}}

@app.get("/api/v1/auth/logout", tags=["Authentication"])
async def logout(current_user: User = Depends(get_current_user)):
	"""
	Invalidates the logged in user's token, effectively logging them out.
	"""
	current_user.session = None
	Users_DB.update_user(current_user)
	return {"Status": "OK"}

# ------------------
# USER ENDPOINTS
# ------------------
@app.get("/api/v1/users/search/{name}", tags=["Users"])
async def get_users(name: str, current_user: User = Depends(get_current_user)):
	"""
	Returns users with usernames similar to the search.
	
	Account **MUST** be a teacher account.
	"""
	if (current_user.permissions < Permissions.Teacher):
		return {"status": "error", "message": "Account must be a teacher account"}
	users = Users_DB.get_users()
	users.remove(current_user)
	final_users = [user for user in users if user.username.count(name) != 0]
	return {"status": "success", "data": [user.remove("session", "password", "salt") for user in final_users]}

@app.get("/api/v1/users/@me", tags=["Users"])
async def get_me(current_user: User = Depends(get_current_user)):
	"""
	Returns information about the current user.

	This also removes sensitive pieces of information as to protect the user from attacks.
	"""
	return {"status": "success", "data": current_user.remove("session", "password", "salt")}

@app.get("/api/v1/users/{user_id}", tags=["Users"])
async def get_user(user_id: int, user: User = Depends(get_current_user)):
	"""
	Returns information about another user.
	
	This removes many sensitive pieces of information from the result as to protect users.

	Raises 404 if the user specified is not found.
	"""
	user = Users_DB.get_user_from_uid(user_id)
	if user:
		return {"status": "success", "data": user.remove("session", "password", "salt")}
	raise HTTPException(status_code=404, detail="User not found")

@app.post("/api/v1/users/reset", tags=["Users"])
async def reset_me(request: Request, current_user: User = Depends(get_current_user)):
	"""
	Deletes all of the current user's data, but keeps their account.

	This **CANNOT** be undone!
	"""
	timetable = User_Subjects_DB.get_timetable(current_user.uid)
	for period in range(9):
		if timetable.monday[period] is not None:
			User_Subjects_DB.remove_connection(current_user.uid, 0, period)
		if timetable.tuesday[period] is not None:
			User_Subjects_DB.remove_connection(current_user.uid, 1, period)
		if timetable.wednesday[period] is not None:
			User_Subjects_DB.remove_connection(current_user.uid, 2, period)
		if timetable.thursday[period] is not None:
			User_Subjects_DB.remove_connection(current_user.uid, 3, period)
		if timetable.friday[period] is not None:
			User_Subjects_DB.remove_connection(current_user.uid, 4, period)
	events = User_Events_DB.get_events_for_user(current_user.uid)
	for event in events:
		User_Events_DB.delete_connection(current_user.uid, event)
	marks = Marks_DB.get_marks_for_user(current_user.uid)
	for mark in marks:
		Marks_DB.delete_mark(mark.mark_id)
	homework = Homework_DB.get_homework_for_user(current_user.uid)
	for hw in homework:
		Homework_DB.delete_homework(hw.homework_id)
	created_events = Events_DB.get_events_by_user(current_user.uid)
	for event in created_events:
		connected = User_Events_DB.get_users_for_event(event.event_id)
		for user in connected:
			User_Events_DB.delete_connection(user.uid, event.event_id)
		Events_DB.delete_event(event.event_id, current_user.uid)
	classes_owned = Classes_DB.get_classes(current_user.uid)
	for cl in classes_owned:
		students = User_Class_DB.get_students_in_class(cl.class_id)
		for student in students:
			User_Class_DB.delete_connection(cl.class_id, student.uid)
		Classes_DB.delete_class(cl.class_id)
	return {"status": "success"}

@app.delete("/api/v1/users/@me", tags=["Users"])
async def delete_me(request: Request, current_user: User = Depends(get_current_user)):
	"""
	Deletes all of the current user's data, and completely removes their account.

	This **CANNOT** be undone!
	"""
	timetable = User_Subjects_DB.get_timetable(current_user.uid)
	for period in range(9):
		if timetable.monday[period] is not None:
			User_Subjects_DB.remove_connection(current_user.uid, 0, period)
		if timetable.tuesday[period] is not None:
			User_Subjects_DB.remove_connection(current_user.uid, 1, period)
		if timetable.wednesday[period] is not None:
			User_Subjects_DB.remove_connection(current_user.uid, 2, period)
		if timetable.thursday[period] is not None:
			User_Subjects_DB.remove_connection(current_user.uid, 3, period)
		if timetable.friday[period] is not None:
			User_Subjects_DB.remove_connection(current_user.uid, 4, period)
	events = User_Events_DB.get_events_for_user(current_user.uid)
	for event in events:
		User_Events_DB.delete_connection(current_user.uid, event)
	marks = Marks_DB.get_marks_for_user(current_user.uid)
	for mark in marks:
		Marks_DB.delete_mark(mark.mark_id)
	homework = Homework_DB.get_homework_for_user(current_user.uid)
	for hw in homework:
		Homework_DB.delete_homework(hw.homework_id)
	created_events = Events_DB.get_events_by_user(current_user.uid)
	for event in created_events:
		connected = User_Events_DB.get_users_for_event(event.event_id)
		for user in connected:
			User_Events_DB.delete_connection(user.uid, event.event_id)
		Events_DB.delete_event(event.event_id, current_user.uid)
	classes_owned = Classes_DB.get_classes(current_user.uid)
	for cl in classes_owned:
		students = User_Class_DB.get_students_in_class(cl.class_id)
		for student in students:
			User_Class_DB.delete_connection(cl.class_id, student.uid)
		Classes_DB.delete_class(cl.class_id)
	Users_DB.delete_user(current_user)
	return {"status": "success"}

# ------------------
# SUBJECT ENDPOINTS
# ------------------
@app.get("/api/v1/subjects", tags=["Subjects"])
async def get_subjects(user: User = Depends(get_current_user)):
	"""
	Gets all subjects avaliable in the database.
	"""
	sjs = Subjects_DB.get_subjects()
	return {"status": "success", "data": sjs}

@app.post("/api/v1/subjects", tags=["Subjects"])
async def create_subject(name: str = Form(...), teacher: str = Form("None"), room: str = Form("None"), user: User = Depends(get_current_user)):
	"""
	This allows for a user to create a subject.

	If the exact same subject already exists, it will not be recreated.

	Returns the ID of the created subject.
	"""
	name = name.title()
	teacher = teacher.title()
	room = room.upper()
	exists = Subjects_DB.get_subjects_by_name(name)
	if not exists:
		for subject in exists:
			if subject.teacher == teacher and subject.room == room:
				# If we find that this specific subject already exists,
				# We lie and say that we created it, but return the old id instead of a new one.
				return {"status": "success", "id": subject.id}
	Subjects_DB.add_subject(Subject(
		name=name,
		teacher=teacher,
		room=room
	))
	return {"status": "success", "id": Subjects_DB.get_next_id() - 1}

@app.get("/api/v1/subjects/name/{subject_name}", tags=["Subjects"])
async def get_subject_by_name(subject_name: str, user: User = Depends(get_current_user)):
	"""
	Gets all subjects which match a certain name.
	"""
	subject_name = subject_name.title()
	sjs = Subjects_DB.get_subjects_by_name(subject_name)
	return {"status": "success", "data": sjs}

@app.get("/api/v1/subjects/id/{subject_id}", tags=["Subjects"])
async def get_subject_by_id(id: int, user: User = Depends(get_current_user)):
	"""
	Gets the subject with a specific ID.
	"""
	sjs = Subjects_DB.get_subject_by_id(id)
	return {"status": "success", "data": sjs}


# ------------------
# TIMETABLE ENDPOINTS
# ------------------

@app.get("/api/v1/timetable", tags=["Timetable"])
async def get_timetable(user: User = Depends(get_current_user)):
	"""
	Gets the current user's timetable.
	"""
	result = User_Subjects_DB.get_timetable(user.uid)
	timetable = result.get_client_format()

	# Here, instead of directly using the variable, I am getting indexes as this will allow me to modify the
	# Timetable in-place instead of having to create a copy and waste memory.
	for day in range(len(timetable)):
		for period in range(len(timetable[day])):
			timetable[day][period] = Subjects_DB.get_subject_by_id(timetable[day][period])
	return {"status": "success", "data": timetable}

@app.post("/api/v1/timetable", tags=["Timetable"])
async def add_timetable_subject(subject_id: int = Form(...), day: int = Form(...), period: int = Form(...), user: User = Depends(get_current_user)):
	"""
	Adds a subject to the current user's timetable.
	"""
	subject = Subjects_DB.get_subject_by_id(subject_id)
	if subject is None:
		return {"status": "error", "message": "Subject does not exist."}
	result = User_Subjects_DB.create_connection(user.uid, subject_id, day, period)
	if result:
		return {"status": "success"}
	return {"status": "error", "message": "An unknown error has occured."}

@app.delete("/api/v1/timetable", tags=["Timetable"])
async def remove_timetable_subject(day: int = Form(...), period: int = Form(...), user: User = Depends(get_current_user)):
	"""
	Removes a subject from the current user's timetable.
	"""
	result = User_Subjects_DB.remove_connection(user.uid, day, period)
	if result:
		return {"status": "success"}
	return {"status": "error", "message": "No connection exists."}

# ------------------
# HOMEWORK ENDPOINTS
# ------------------

@app.get("/api/v1/homework", tags=["Homework"])
async def get_homework(user: User = Depends(get_current_user)):
	"""
	Gets all of the current user's homework.
	"""
	result = Homework_DB.get_homework_for_user(user.uid)
	return {"status": "success", "data": result}

@app.post("/api/v1/homework", tags=["Homework"])
async def create_homework(name: str = Form(...), due_date: int = Form(...), description: str = Form(""), user: User = Depends(get_current_user)):
	"""
	Creates a piece of homework for the current user.
	"""
	Homework_DB.create_homework(user.uid, name, due_date, description)
	return {"status": "success"}

@app.patch("/api/v1/homework", tags=["Homework"])
async def complete_homework(id: int = Form(...), user: User = Depends(get_current_user)):
	"""
	Flips whether a piece of homework is completed or not.

	Homework **must** belong to the current user.
	"""
	homework = Homework_DB.get_homework(id)
	if homework is None:
		return {"status": "error", "message": "Homework doesn't exist."}
	if homework.user_id != user.uid:
		return {"status": "error", "message": "Not your homework."}
	homework.completed = not homework.completed
	Homework_DB.update_homework(homework)
	return {"status": "success"}

@app.delete("/api/v1/homework", tags=["Homework"])
async def delete_homework(id: int = Form(...), user: User = Depends(get_current_user)):
	"""
	Deletes a piece of homework.
	
	Homework **must** belong to the current user.
	"""
	homework = Homework_DB.get_homework(id)
	if homework is None:
		return {"status": "error", "message": "Homework doesn't exist."}
	if homework.user_id != user.uid:
		return {"status": "error", "message": "Not your homework."}
	Homework_DB.delete_homework(id)
	return {"status": "success"}

# ------------------
# MARK ENDPOINTS
# ------------------

@app.get("/api/v1/marks", tags=["Marks"])
async def get_marks(user: User = Depends(get_current_user)):
	"""
	Gets all marks for the current user.
	"""
	result = Marks_DB.get_marks_for_user(user.uid)
	return {"status": "success", "data": result}

@app.post("/api/v1/marks", tags=["Marks"])
async def add_mark(name: str = Form(...), mark: int = Form(...), grade: str = Form(...), user: User = Depends(get_current_user)):
	"""
	Adds a mark to the database for the current user.
	"""
	Marks_DB.add_mark(user.uid, name, mark, grade)
	return {"status": "success"}

@app.put("/api/v1/marks", tags=["Marks"])
async def update_mark(mark_id: int = Form(...), name: str = Form(...), mark: int = Form(...), grade: int = Form(...), user: User = Depends(get_current_user)):
	"""
	Updates the details of a mark.
	
	Mark **must** belong to the current user.
	"""
	mark = Marks_DB.get_mark(mark_id)
	if mark is None:
		return {"status": "error", "message": "Mark doesn't exist."}
	if mark.user_id != user.uid:
		return {"status": "error", "message": "Not your mark."}
	mark.name = name
	mark.mark = mark
	mark.grade = grade
	Marks_DB.update_mark(mark)
	return {"status": "success"}

@app.delete("/api/v1/marks", tags=["Marks"])
async def delete_mark(mark_id: int = Form(...), user: User = Depends(get_current_user)):
	"""
	Deletes a mark.
	
	Mark **must** belong to the current user.
	"""
	mark = Marks_DB.get_mark(mark_id)
	if mark is None:
		return {"status": "error", "message": "Mark doesn't exist."}
	if mark.user_id != user.uid:
		return {"status": "error", "message": "Not your mark."}
	Marks_DB.delete_mark(mark_id)
	return {"status": "success"}

# ------------------
# EVENT ENDPOINTS
# ------------------
@app.get("/api/v1/events", tags=["Events"])
async def get_events(user: User = Depends(get_current_user)):
	"""
	Gets all events.
	"""
	return {"status": "success", "data": Events_DB.get_events()}

@app.get("/api/v1/events/user/@me", tags=["Events"])
async def get_events_by_user(user: User = Depends(get_current_user)):
	"""
	Gets all events created by the current user..
	"""
	return {"status": "success", "data": Events_DB.get_events_by_user(user.uid)}

@app.get("/api/v1/events/user/{user_id}", tags=["Events"])
async def get_events_by_user(user_id: int, user: User = Depends(get_current_user)):
	"""
	Gets all events created by a user.
	"""
	return {"status": "success", "data": Events_DB.get_events_by_user(user_id)}

@app.post("/api/v1/events", tags=["Events"])
async def create_event(name: str = Form(...), time: int = Form(...), description: str = Form(None), private: bool = Form(...), user: User = Depends(get_current_user)):
	"""
	Creates an event.
	
	This event can be marked as private or public. Public events require a teacher account.
	"""
	if user.permissions < Permissions.Teacher and not private:
		return HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authorized to create public events.")
	Events_DB.create_event(user.uid, name, time, description, private)
	return {"status": "success"}

@app.get("/api/v1/events/{event_id}", tags=["Events"])
async def get_event(event_id: int, user: User = Depends(get_current_user)):
	"""
	Fetches the event with the specified ID.
	"""
	event = Events_DB.get_event(event_id, user.uid)
	if not event:
		return {"status": "error", "message": "Event doesn't exist."}
	return {"status": "success", "data": event}

@app.delete("/api/v1/events/{event_id}", tags=["Events"])
async def delete_event(event_id: int, user: User = Depends(get_current_user)):
	"""
	Deletes the event with the specified ID.
	
	This event must be owned by the current user.
	"""
	event = Events_DB.get_event(event_id, user.uid)
	if not event:
		return {"status": "error", "message": "Event doesn't exist."}
	if event.user_id != user.uid:
		return {"status": "error", "message": "Not your event."}
	if Events_DB.delete_event(event_id, user.uid):
		return {"status": "success"}
	return {"status": "error", "message": "Event doesn't exist or it's not your event."}

# ------------------
# CLASS ENDPOINTS
# ------------------

@app.get("/api/v1/classes", tags=["Classes"])
async def get_classes(user: User = Depends(get_current_user)):
	"""
	Gets all classes owned by the current user.
	"""
	classes = Classes_DB.get_classes(user.uid)
	for idx, thisClass in enumerate(classes):
		students = User_Class_DB.get_students_in_class(thisClass.class_id)
		classes[idx].students = []
		for student in students:
			classes[idx].students.append(Users_DB.get_user_from_uid(student).remove("password", "salt", "session"))
		classes[idx].homework = Homework_DB.get_homework_for_class(thisClass.class_id)
	return {"status": "success", "data": classes}

@app.get("/api/v1/classes/{class_id}", tags=["Classes"])
async def get_class(class_id: int, user: User = Depends(get_current_user)):
	"""
	Gets the class specified by the URL.

	Returns an error if it doesn't exist.
	"""
	thisClass = Classes_DB.get_class(class_id)
	if thisClass is None:
		return {"status": "error", "message": "Class doesn't exist."}
	students = User_Class_DB.get_students_in_class(thisClass.class_id)
	thisClass.students = [Users_DB.get_user_from_uid(student).remove("password", "salt", "session") for student in students]
	homework = Homework_DB.get_homework_for_class(thisClass.class_id)
	thisClass.homework = homework
	return {"status": "success", "data": thisClass}

@app.post("/api/v1/classes", tags=["Classes"])
async def create_class(name: str = Form(...), user: User = Depends(get_current_user)):
	"""
	Creates a class with the parameters defined in the POST Form.

	**MUST** be a teacher account to create the class.
	"""
	if user.permissions < Permissions.Teacher:
		return {"status": "error", "message": "Only teachers can create classes."}
	Classes_DB.create_class(user.uid, name)
	return {"status": "success"}

@app.patch("/api/v1/classes/{class_id}", tags=["Classes"])
async def add_student_to_class(class_id: int, student_id: int = Form(...), user: User = Depends(get_current_user)):
	"""
	Adds a student to a class.
	
	Class **MUST** be owned by current user.
	"""
	thisClass = Classes_DB.get_class(class_id)
	if thisClass.teacher_id != user.uid:
		return {"status": "error", "message": "You can only add to your own class."}
	student = Users_DB.get_user_from_uid(student_id)
	if student is None:
		return {"status": "error", "message": "Student doesn't exist."}
	User_Class_DB.create_connection(thisClass.class_id, student_id)
	return {"status": "success"}

@app.get("/api/v1/classes/{class_id}/homework", tags=["Classes"])
async def get_class_homework(class_id: int, user: User = Depends(get_current_user)):
	"""
	Gets all pieces of homework set for a class.
	
	Class **MUST** belong to the current user.
	"""
	thisClass = Classes_DB.get_class(class_id)
	if thisClass.teacher_id != user.uid:
		return {"status": "error", "message": "You may only set homework for your own class."}
	homeworkSet = Homework_DB.get_homework_for_class(class_id)
	return {"status": "success", "data": homeworkSet}

@app.post("/api/v1/classes/{class_id}/homework", tags=["Classes"])
async def set_class_homework(class_id: int, homework_name: str = Form(...), due_date: int = Form(...), description: str = Form(""), user: User = Depends(get_current_user)):
	"""
	Creates a piece of homework for an entire class.
	
	Class **MUST** belong to the current user.
	"""
	thisClass = Classes_DB.get_class(class_id)
	if thisClass.teacher_id != user.uid:
		return {"status": "error", "message": "You may only set homework for your own class."}
	studentsInClass = User_Class_DB.get_students_in_class(class_id)
	for student in studentsInClass:
		Homework_DB.create_homework_for_class(class_id, student, homework_name, due_date, description)
	return {"status": "success"}

if __name__ == "__main__":
	uvicorn.run("main:app", port=8000, debug=True, reload=True, workers=4)