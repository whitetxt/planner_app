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