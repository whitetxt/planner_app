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

	def _commit(self) -> None:
		db = sqlite3.connect(self.path)
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
			email=user_data[4],
			creation_time=user_data[5],
			permissions=user_data[6],
			session=OAuthToken(
				uid=user_data[0],
				access_token=user_data[7]) 
				if user_data[7] is not None else None
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
			email=user_data[4],
			creation_time=user_data[5],
			permissions=user_data[6],
			session=OAuthToken(
				uid=user_data[0],
				access_token=user_data[7]) 
				if user_data[7] is not None else None
		)
	
	def get_user_from_token(self, token: str) -> User:
		user_data = self._get("*", "users", where="token = ?", args=(token,))
		if len(user_data) == 0:
			return None
		user_data = user_data[0]
		return User(
			uid=user_data[0],
			username=user_data[1],
			password=user_data[2],
			salt=user_data[3],
			email=user_data[4],
			creation_time=user_data[5],
			permissions=user_data[6],
			session=OAuthToken(
				uid=user_data[0],
				access_token=user_data[7]) 
				if user_data[7] is not None else None
		)
	
	def get_users(self) -> list:
		users = self._get("*", "users")
		return [User(
			uid=user[0],
			username=user[1],
			password=user[2],
			salt=user[3],
			email=user[4],
			creation_time=user[5],
			permissions=user[6],
			token=OAuthToken(
				uid=user[0],
				access_token=user[7])
				if user[7] is not None else None
		) for user in users]
	
	def update_user(self, user: User) -> bool:
		token = user.session.access_token if user.session is not None else None
		self._update(
			"users",
			"username = ?, password = ?, salt = ?, email = ?, creation_time = ?, permissions = ?, session = ?",
			"uid = ?",
			(user.username, user.password, user.salt, user.email, user.creation_time, user.permissions, token, user.uid)
		)
		self._commit()
		return True

	def add_user(self, user: User) -> bool:
		self._insert(
			"users",
			"uid, username, password, salt, email, creation_time, permissions, session",
			(user.uid, user.username, user.tag, user.password, user.creation_time, user.last_login, str(user.enabled), user.session.access_token if user.session else None)
		)
		self._commit()

	def get_next_uid(self) -> int:
		latest_uid = self._get("uid", "users", order="uid DESC")
		if len(latest_uid) == 0:
			return 1
		return latest_uid[0][0] + 1