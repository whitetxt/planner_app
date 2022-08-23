import sqlite3
from typing import Optional
from classes import *

class DB:
	"""This is the base class for a database.

	It provides wrappers for SQL functions, making them easier to implement and use.

	This class should not be used by itself.
	A child of this class should be implemented to wrap around these functions."""
	def __init__(self, path):
		self.path = path

	def _get(self, col: str, table: str, where: Optional[str] = None, order: Optional[str] = None, args: Optional[tuple] = ()) -> list:
		db = sqlite3.connect(self.path)
		cursor = db.cursor()
		statement = f"SELECT {col} FROM {table}"
		if where:
			statement += f" WHERE {where}"
		if order:
			statement += f" ORDER BY {order}"
		cursor.execute(statement, args)
		return cursor.fetchall()

	def _get_raw(self, query: str) -> list:
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

class UsersDB(DB):
	"""
	This class handles user data inside of a database file.
	
	Wrapper functions are provided to make manipulation of the data easier.
	"""
	def __init__(self, path):
		super().__init__(path)
	
	def get_user_from_username(self, username: str) -> User:
		user_data = self._get("*", "users", where="username = ?", args=(username,))
		if len(user_data) == 0:
			return None
		user_data = user_data[0]
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
	
	def get_user_from_uid(self, uid: int) -> User:
		user_data = self._get("*", "users", where="uid = ?", args=(uid,))
		if len(user_data) == 0:
			return None
		user_data = user_data[0]
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
	
	def get_user_from_session(self, session: str) -> User:
		user_data = self._get("*", "users", where="session = ?", args=(session,))
		if len(user_data) == 0:
			return None
		user_data = user_data[0]
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
	
	def get_users(self) -> list:
		users = self._get("*", "users")
		return [User(
			uid=user[0],
			username=user[1],
			password=user[2],
			salt=user[3],
			created_at=user[4],
			permissions=user[5],
			token=OAuthToken(
				uid=user[0],
				access_token=user[6])
				if user[6] is not None else None
		) for user in users]
	
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
		if len(latest_uid) == 0:
			return 1
		return latest_uid[0][0] + 1
	
class SubjectsDB(DB):
	"""
	This implements functions to deal with subjects inside the database.
	"""
	def __init__(self, path):
		super().__init__(path)
	
	def get_subject_by_id(self, id: int) -> Subject:
		subject_data = self._get("*", "subjects", where="subject_id = ?", args=(id,))
		if len(subject_data) == 0:
			return None
		subject_data = subject_data[0]
		return Subject(
			subject_id=subject_data[0],
			name=subject_data[1],
			teacher=subject_data[2],
			room=subject_data[3]
		)
	
	def get_subjects_by_name(self, name: str) -> list:
		subject_data = self._get("*", "subjects", where="name = ?", args=(name,))
		if len(subject_data) == 0:
			return None
		return [Subject(
			subject_id=sd[0],
			name=sd[1],
			teacher=sd[2],
			room=sd[3]
		) for sd in subject_data]
	
	def get_subjects_by_teacher(self, name: str) -> list:
		subject_data = self._get("*", "subjects", where="teacher = ?", args=(name,))
		if len(subject_data) == 0:
			return None
		return [Subject(
			subject_id=sd[0],
			name=sd[1],
			teacher=sd[2],
			room=sd[3]
		) for sd in subject_data]

	def get_subjects_by_room(self, room: str) -> list:
		subject_data = self._get("*", "subjects", where="room = ?", args=(room,))
		if len(subject_data) == 0:
			return None
		return [Subject(
			subject_id=sd[0],
			name=sd[1],
			teacher=sd[2],
			room=sd[3]
		) for sd in subject_data]
	
	def get_subjects(self) -> list:
		subjects = self._get("*", "subjects")
		if len(subjects) == 0:
			return None
		[Subject(
			subject_id=subject[0],
			name=subject[1],
			teacher=subject[2],
			room=subject[3]
		) for subject in subjects]

	def update_subject(self, subject: Subject) -> bool:
		self._update(
			"subjects",
			"name = ?, teacher = ?, room = ?",
			"subject_id = ?",
			(subject.name, subject.teacher, subject.room, subject.subject_id)
		)
		return True

	def add_subject(self, subject: Subject) -> bool:
		if subject.subject_id is None:
			subject.subject_id = self.get_next_id()
		self._insert(
			"subjects",
			"subject_id, name, teacher, room",
			(subject.subject_id, subject.name, subject.teacher, subject.room)
		)
		return True
	
	def get_next_id(self) -> int:
		latest_id = self._get("subject_id", "subjects", order="uid DESC")
		if len(latest_id) == 0:
			return 1
		return latest_id[0][0] + 1

class UserSubjectDB(DB):
	def __init__(self, path):
		super().__init__(path)
	
	def get_subject_by_period(self, user_id: int, day: int, period: int) -> UserSubjectJoin:
		result = self._get("subject_id", "`users-subjects`", where="user_id = ? AND day = ? AND period = ?", args=(user_id, day, period))
		if not result:
			return None
		return UserSubjectJoin(user_id=user_id, subject_id=result[0][0], day=day, period=period)

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
		if existing is not None and existing.subject_id == subject_id:
			# If inserting will do nothing, just don't do it as it will just waste time.
			return True
		self._insert("`users-subjects`", "user_id, subject_id, day, period", (user_id, subject_id, day, period))
		return True

	def remove_connection(self, user_id: int, day: int, period: int) -> bool:
		existing = self.get_subject_by_period(user_id, day, period)
		if existing is None:
			return False
		self._delete("`users-subjects`", "user_id = ? AND day = ? AND period = ?", (user_id, day, period))
		return True