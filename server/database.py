import sqlite3, json
from typing import List, Optional
from classes import *

class DB:
	"""This is the base class for a database.

	It provides wrappers for SQL functions, making them easier to implement and use.

	This class should not be used by itself.
	A child of this class should be implemented to wrap around these functions."""
	def __init__(self, path):
		self.path = path

	def _get(self, col: str, table: str, where: Optional[str] = None, order: Optional[str] = None, args: Optional[tuple] = ()) -> List:
		db = sqlite3.connect(self.path)
		cursor = db.cursor()
		statement = f"SELECT {col} FROM {table}"
		if where:
			statement += f" WHERE {where}"
		if order:
			statement += f" ORDER BY {order}"
		cursor.execute(statement, args)
		return cursor.fetchall()

	def _get_raw(self, query: str) -> List:
		db = sqlite3.connect(self.path)
		cursor = db.cursor()
		cursor.execute(query)
		return cursor.fetchall()

	def _update(self, table: str, set_cols: str, where: str, args: tuple) -> None:
		db = sqlite3.connect(self.path)
		cursor = db.cursor()
		cursor.execute(f"UPDATE {table} SET {set_cols} WHERE {where}", args)
		db.commit()

	def _insert(self, table: str, cols: str, args: tuple) -> None:
		db = sqlite3.connect(self.path)
		cursor = db.cursor()
		cursor.execute(f"INSERT INTO {table}({cols}) VALUES (?" + ",?" * (len(args) - 1) + ")", args)
		db.commit()

	def _delete(self, table: str, where: str, args: tuple) -> None:
		db = sqlite3.connect(self.path)
		cursor = db.cursor()
		cursor.execute(f"DELETE FROM {table} WHERE {where}", args)
		db.commit()

	def _create(self, table: str, ddl: str) -> None:
		db = sqlite3.connect(self.path)
		cursor = db.cursor()
		cursor.execute(f"CREATE TABLE IF NOT EXISTS {table} ({ddl})")
		db.commit()
	
	def _create_raw(self, ddl: str) -> None:
		db = sqlite3.connect(self.path)
		cursor = db.cursor()
		cursor.execute(ddl + ";")
		db.commit()

class UsersDB(DB):
	"""
	This class handles user data inside of a database file.
	
	Wrapper functions are provided to make manipulation of the data easier.
	"""
	def __init__(self, path):
		super().__init__(path)
		DDL = """CREATE TABLE IF NOT EXISTS "users" (
	"uid"	INTEGER NOT NULL,
	"username"	TEXT NOT NULL UNIQUE,
	"password"	TEXT NOT NULL,
	"salt"	TEXT NOT NULL,
	"created_at"	INTEGER NOT NULL,
	"permissions"	INTEGER NOT NULL,
	"session"	TEXT,
	PRIMARY KEY("uid" AUTOINCREMENT)
)"""
		self._create_raw(DDL)

	def convert_result_to_user(self, user_data: dict) -> User:
		return User(
			uid=user_data[0],
			username=user_data[1],
			password=user_data[2],
			salt=user_data[3],
			created_at=user_data[4],
			permissions=user_data[5],
			session=OAuthToken(
				uid=user_data[0],
				access_token=user_data[6]) 
				if user_data[6] is not None else None
		)

	def get_user_from_username(self, username: str) -> User:
		user_data = self._get("*", "users", where="username = ?", args=(username,))
		if len(user_data) == 0:
			return None
		user_data = user_data[0]
		return self.convert_result_to_user(user_data)

	def get_user_from_uid(self, uid: int) -> User:
		user_data = self._get("*", "users", where="uid = ?", args=(uid,))
		if len(user_data) == 0:
			return None
		user_data = user_data[0]
		return self.convert_result_to_user(user_data)
	
	def get_user_from_session(self, session: str) -> User:
		user_data = self._get("*", "users", where="session = ?", args=(session,))
		if len(user_data) == 0:
			return None
		user_data = user_data[0]
		return self.convert_result_to_user(user_data)
	
	def get_users(self) -> List[User]:
		users = self._get("*", "users")
		return [self.convert_result_to_user(user) for user in users]
	
	def update_user(self, user: User) -> bool:
		token = user.session.access_token if user.session is not None else None
		self._update(
			"users",
			"username = ?, password = ?, salt = ?, created_at = ?, permissions = ?, session = ?",
			"uid = ?",
			(user.username, user.password, user.salt, user.created_at, user.permissions, token, user.uid)
		)
		return True

	def add_user(self, user: User) -> bool:
		if user.uid is None:
			user.uid = self.get_next_uid()
		self._insert(
			"users",
			"uid, username, password, salt, created_at, permissions, session",
			(user.uid, user.username, user.password, user.salt, user.created_at, user.permissions, user.session.access_token if user.session else None)
		)
		return True

	def get_next_uid(self) -> int:
		latest_uid = self._get("uid", "users", order="uid DESC")
		return 1 if len(latest_uid) == 0 else latest_uid[0][0] + 1
	
	def delete_user(self, user: User) -> None:
		self._delete("users", "uid = ? AND username = ?", (user.uid, user.username))
	
class SubjectsDB(DB):
	"""
	This implements functions to deal with subjects inside the database.
	"""
	def __init__(self, path):
		super().__init__(path)
		DDL = """CREATE TABLE IF NOT EXISTS "subjects" (
	"subject_id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"teacher"	TEXT NOT NULL,
	"room"	TEXT NOT NULL,
	PRIMARY KEY("subject_id" AUTOINCREMENT)
)"""
		self._create_raw(DDL)

	def convert_result_to_subject(self, subject):
		return Subject(
				subject_id=subject[0],
				name=subject[1],
				teacher=subject[2],
				room=subject[3]
			)

	def get_subject_by_id(self, id: int) -> Subject:
		subject_data = self._get("*", "subjects", where="subject_id = ?", args=(id,))
		if len(subject_data) == 0:
			return None
		subject_data = subject_data[0]
		return self.convert_result_to_subject(subject_data)
	
	def get_subjects_by_name(self, name: str) -> List[Subject]:
		subject_data = self._get("*", "subjects", where="name = ?", args=(name,))
		return [self.convert_result_to_subject(subject) for subject in subject_data]
	
	def get_subjects_by_teacher(self, name: str) -> List[Subject]:
		subject_data = self._get("*", "subjects", where="teacher = ?", args=(name,))
		return [self.convert_result_to_subject(subject) for subject in subject_data]

	def get_subjects_by_room(self, room: str) -> List[Subject]:
		subject_data = self._get("*", "subjects", where="room = ?", args=(room,))
		return [self.convert_result_to_subject(subject) for subject in subject_data]
	
	def get_subjects(self) -> list:
		subjects = self._get("*", "subjects")
		[self.new_method(subject) for subject in subjects]

	def update_subject(self, subject: Subject) -> bool:
		self._update(
			"subjects",
			"name = ?, teacher = ?, room = ?",
			"subject_id = ?",
			(subject.name.title(), subject.teacher.title(), subject.room.upper(), subject.subject_id)
		)
		return True

	def add_subject(self, subject: Subject) -> bool:
		if subject.subject_id is None:
			subject.subject_id = self.get_next_id()
		self._insert(
			"subjects",
			"subject_id, name, teacher, room",
			(subject.subject_id, subject.name.title(), subject.teacher.title(), subject.room.upper())
		)
		return True
	
	def get_next_id(self) -> int:
		latest_id = self._get("subject_id", "subjects", order="subject_id DESC")
		return 1 if len(latest_id) == 0 else latest_id[0][0] + 1

class UserSubjectDB(DB):
	def __init__(self, path):
		super().__init__(path)
		DDL = """CREATE TABLE IF NOT EXISTS "users-subjects" (
	"user_id"	INTEGER NOT NULL,
	"subject_id"	INTEGER NOT NULL,
	"day"	INTEGER NOT NULL,
	"period"	INTEGER NOT NULL,
	PRIMARY KEY("user_id","period","day"),
	FOREIGN KEY("user_id") REFERENCES "users"("uid"),
	FOREIGN KEY("subject_id") REFERENCES "subjects"("subject_id")
)"""
		self._create_raw(DDL)
	
	def get_subject_by_period(self, user_id: int, day: int, period: int) -> UserSubjectJoin:
		result = self._get("subject_id", "`users-subjects`", where="user_id = ? AND day = ? AND period = ?", args=(user_id, day, period))

		return UserSubjectJoin(user_id=user_id, subject_id=result[0][0], day=day, period=period) if result else None

	def get_timetable(self, user_id: int) -> Timetable:
		results = self._get("day, period, subject_id", "`users-subjects`", where="user_id = ?", order="day ASC", args=(user_id, ))
		if not results:
			return Timetable()
		timetable = Timetable()
		for result in results:
			day = result[0]
			period = result[1]
			subject_id = result[2]
			if day == 0:
				timetable.monday[period] = subject_id
			elif day == 1:
				timetable.tuesday[period] = subject_id
			elif day == 2:
				timetable.wednesday[period] = subject_id
			elif day == 3:
				timetable.thursday[period] = subject_id
			elif day == 4:
				timetable.friday[period] = subject_id
		return timetable

	def create_connection(self, user_id: int, subject_id: int, day: int, period: int) -> bool:
		existing = self.get_subject_by_period(user_id, day, period)
		if existing is not None:
			if existing.subject_id == subject_id:
				# If inserting will do nothing, just don't do it as it will just waste time.
				return True
			self._update("`users-subjects`", "subject_id = ?", "user_id = ? AND day = ? AND period = ?", (subject_id, user_id, day, period))
			return True
		self._insert("`users-subjects`", "user_id, subject_id, day, period", (user_id, subject_id, day, period))
		return True

	def remove_connection(self, user_id: int, day: int, period: int) -> bool:
		existing = self.get_subject_by_period(user_id, day, period)
		if existing is None:
			return False
		self._delete("`users-subjects`", "user_id = ? AND day = ? AND period = ?", (user_id, day, period))
		return True

class ClassDB(DB):
	def __init__(self, path):
		super().__init__(path)
		DDL = """CREATE TABLE IF NOT EXISTS "classes" (
	"class_id"	INTEGER NOT NULL,
	"teacher_id"	INTEGER NOT NULL,
	"class_name"	TEXT NOT NULL,
	FOREIGN KEY("teacher_id") REFERENCES "users"("uid"),
	PRIMARY KEY("class_id" AUTOINCREMENT)
)"""
		self._create_raw(DDL)

	def convert_result_to_class(self, result) -> Class:
		return Class(class_id=result[0], teacher_id=result[1], class_name=result[2])
	
	def get_class(self, class_id: int) -> Class:
		result = self._get("*", "classes", where="class_id = ?", args=(class_id, ))
		return self.convert_result_to_class(result[0]) if result else None

	def get_classes(self, teacher_id: int) -> List[Class]:
		results = self._get("*", "classes", where="teacher_id = ?", args=(teacher_id,))
		return [self.convert_result_to_class(result) for result in results]

	def create_class(self, teacher_id: int, name: str) -> None:
		self._insert("classes", "teacher_id, class_name", (teacher_id, name))

	def delete_class(self, class_id: int) -> None:
		self._delete("classes", "class_id = ?", (class_id, ))

class ClassStudentDB(DB):
	def __init__(self, path):
		super().__init__(path)
		DDL = """CREATE TABLE IF NOT EXISTS "class-student" (
	"student_id"	INTEGER NOT NULL,
	"class_id"	INTEGER NOT NULL,
	PRIMARY KEY("student_id","class_id"),
	FOREIGN KEY("class_id") REFERENCES "classes"("class_id"),
	FOREIGN KEY("student_id") REFERENCES "users"("uid")
)"""
		self._create_raw(DDL)

	def get_classes_for_student(self, student_id: int) -> List[Class]:
		classes = self._get("class_id", "`class-student`", where="student_id = ?", args=(student_id, ))
		return [cl[0] for cl in classes]
	
	def get_students_in_class(self, class_id: int) -> List[int]:
		students = self._get("student_id", "`class-student`", where="class_id = ?", args=(class_id,))
		return [student[0] for student in students]
	
	def create_connection(self, class_id: int, student_id: int) -> None:
		self._insert("`class-student`", "class_id, student_id", (class_id, student_id))
	
	def delete_connection(self, class_id: int, student_id: int) -> None:
		self._delete("`class-student`", "class_id = ? AND student_id = ?", (class_id, student_id))

class HomeworkDB(DB):
	def __init__(self, path):
		super().__init__(path)
		DDL = """CREATE TABLE IF NOT EXISTS "homework" (
	"homework_id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"class_id"	INTEGER DEFAULT NULL,
	"user_id"	INTEGER DEFAULT NULL,
	"due_date"	INTEGER NOT NULL,
	"decription" TEXT,
	"completed"	INTEGER,
	PRIMARY KEY("homework_id" AUTOINCREMENT),
	FOREIGN KEY("user_id") REFERENCES "users"("uid"),
	FOREIGN KEY("class_id") REFERENCES "classes"("class_id")
)"""
		self._create_raw(DDL)

	def convert_result_to_homework(self, result) -> Homework:
		return Homework(homework_id=result[0], name=result[1], class_id=result[2], user_id=result[3], due_date=result[4], completed=result[5] != None, description=result[6])

	def get_homework_for_user(self, user_id: int) -> List[Homework]:
		results = self._get("*", "homework", where="user_id = ?", order="due_date ASC", args=(user_id,))
		return [self.convert_result_to_homework(result) for result in results]

	def get_homework_for_class(self, class_id: int) -> List[Homework]:
		results = self._get("*", "homework", where="class_id = ?", order="due_date ASC", args=(class_id, ))
		output = [] # I am removing duplicate pieces of homework.
		# This is because there will be the same piece of homework for each user, and the only difference is the user_id and homework_id.
		# I only want each one once, and so this removes duplicates after I make all the user_ids the same.
		for homework in results:
			homework = self.convert_result_to_homework(homework)
			homework.user_id = 0
			found = False
			for hw in output:
				if hw.name == homework.name and hw.due_date == homework.due_date and hw.description == homework.description:
					found = True
					break
			if not found:
				output.append(homework)
		return output

	def get_homework(self, homework_id: int) -> Homework:
		result = self._get("*", "homework", where="homework_id = ?", order="due_date ASC", args=(homework_id, ))
		if not result:
			return None
		result = result[0]
		return self.convert_result_to_homework(result)

	def create_homework(self, user_id: int, name: str, due_date: int, description: str) -> None:
		self._insert("homework", "name, user_id, due_date, completed, description", (name, user_id, due_date, None, description))
	
	def create_homework_for_class(self, user_id: int, class_id: int, name: str, due_date: int, description: str) -> None:
		self._insert("homework", "name, class_id, user_id, due_date, completed, description", (name, class_id, user_id, due_date, None, description))
	
	def update_homework(self, homework: Homework) -> None:
		self._update("homework", "name = ?, class_id = ?, user_id = ?, due_date = ?, completed = ?", "homework_id = ?", (homework.name, homework.class_id, homework.user_id, homework.due_date, \
			None if homework.completed == False else 1, homework.homework_id))
		
	def delete_homework(self, homework_id: int) -> None:
		self._delete("homework", "homework_id = ?", (homework_id, ))
	
class EventDB(DB):
	def __init__(self, path):
		super().__init__(path)
		DDL = """CREATE TABLE IF NOT EXISTS "events" (
	"event_id"	INTEGER NOT NULL,
	"user_id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"time"	INTEGER NOT NULL,
	"description"	TEXT,
	"private"	INTEGER,
	FOREIGN KEY("user_id") REFERENCES "users"("uid"),
	PRIMARY KEY("event_id" AUTOINCREMENT)
)"""
		self._create_raw(DDL)

	def convert_result_to_event(self, result) -> Event:
		return Event(event_id=result[0], user_id=result[1], name=result[2], time=result[3], description=result[4], private=result[5] == 1)

	def get_events(self) -> List[Event]:
		public_results = self._get("*", "events", where="private = ?", args=(0, ))
		return [self.convert_result_to_event(result) for result in public_results]

	def get_event(self, event_id: int, user_id: int) -> Event:
		result = self._get("*", "events", where="event_id = ?", args=(event_id, ))
		if result and (result[0][5] is None or result[0][1] == user_id):
			return self.convert_result_to_event(result[0])
		else:
			return None
	
	def get_events_by_user(self, user_id: int) -> List[Event]:
		results = self._get("*", "events", where="user_id = ?", args=(user_id, ))
		return [self.convert_result_to_event(result) for result in results]
	
	def create_event(self, user_id: int, name: str, time: int, description: str, private: bool) -> None:
		self._insert("events", "user_id, name, time, description, private", (user_id, name, time, description, 1 if private else 0))
	
	def delete_event(self, event_id: int, user_id: int) -> bool:
		exists = self.get_event(event_id, user_id)
		if exists is None:
			return False
		self._delete("events", "event_id = ?", (event_id, ))
		return True

class UserEventDB(DB):
	def __init__(self, path):
		super().__init__(path)
		DDL = """CREATE TABLE IF NOT EXISTS "user-events" (
	"user_id"	INTEGER NOT NULL,
	"event_id"	INTEGER NOT NULL,
	PRIMARY KEY("user_id","event_id"),
	FOREIGN KEY("event_id") REFERENCES "events"("event_id"),
	FOREIGN KEY("user_id") REFERENCES "users"("uid")
)"""
		self._create_raw(DDL)
	
	def get_users_for_event(self, event_id: int) -> List[int]:
		results = self._get("user_id", "`user-events`", where="event_id = ?", args=(event_id, ))
		return [user_id[0] for user_id in results]

	def get_events_for_user(self, user_id: int) -> List[int]:
		results = self._get("event_id", "`user-events`", where="user_id = ?", args=(user_id, ))
		return [event_id[0] for event_id in results]

	def create_connection(self, user_id: int, event_id: int) -> None:
		self._insert("`user-events`", "user_id, event_id", (user_id, event_id))
	
	def delete_connection(self, user_id: int, event_id: int) -> bool:
		exists = self._get("*", "`user-events`", where="user_id = ? AND event_id = ?", args=(user_id, event_id))
		if not exists:
			return False
		self._delete("`user-events`", "user_id = ? AND event_id = ?", args=(user_id, event_id))
		return True

class MarkDB(DB):
	def __init__(self, path):
		super().__init__(path)
		DDL = """CREATE TABLE IF NOT EXISTS "marks" (
	"mark_id"	INTEGER NOT NULL,
	"user_id"	INTEGER NOT NULL,
	"test_name"	TEXT NOT NULL,
	"mark"	INTEGER NOT NULL,
	"grade"	TEXT,
	PRIMARY KEY("mark_id" AUTOINCREMENT),
	FOREIGN KEY("user_id") REFERENCES "users"("uid")
)"""
		self._create_raw(DDL)
	
	def convert_result_to_mark(self, result) -> Mark:
		return Mark(mark_id=result[0], user_id=result[1], test_name=result[2], mark=result[3], grade=result[4])

	def get_mark(self, mark_id: int) -> Mark:
		result = self._get("*", "marks", where="mark_id = ?", args=(mark_id, ))
		if not result:
			return None
		result = result[0]
		return self.convert_result_to_mark(mark_id, result)

	def get_marks_for_user(self, user_id: int) -> List[Mark]:
		results = self._get("*", "marks", where="user_id = ?", args=(user_id, ))
		return [self.convert_result_to_mark(result) for result in results]

	def add_mark(self, user_id: int, test_name: str, mark: int, grade: str) -> None:
		self._insert("marks", "user_id, test_name, mark, grade", (user_id, test_name, mark, grade))

	def delete_mark(self, mark_id: int) -> bool:
		exists = self.get_mark(mark_id)
		if exists is None:
			return False
		self._delete("marks", "mark_id = ?", (mark_id, ))
		return True

	def update_mark(self, mark: Mark) -> None:
		self._update("marks", "user_id, test_name, mark, grade", "mark_id = ?", (mark.user_id, mark.test_name, mark.mark, mark.grade, mark.mark_id))

class RegistrationCodeDB(DB):
	def __init__(self, path):
		super().__init__(path)
		DDL = """CREATE TABLE IF NOT EXISTS "registration_codes" (
	"code"	TEXT NOT NULL,
	"permissions"	INTEGER NOT NULL,
	PRIMARY KEY("code")
)"""
		self._create_raw(DDL)
	
	def get_permissions(self, code: str) -> Permissions:
		result = self._get("*", "registration_codes", where="code = ?", args=(code, ))
		if not result:
			return None
		result = result[0]
		return Permissions(result[1])