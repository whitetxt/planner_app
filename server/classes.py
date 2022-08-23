from enum import Enum
from pydantic import BaseModel
from typing import Optional

class Permissions(Enum):
	Student = 1
	Teacher = 2

class OAuthToken(BaseModel):
	access_token: str
	uid: int

class User(BaseModel):
	uid: int
	username: str
	password: str
	salt: str
	email: str
	creation_time: int
	permissions: int
	session: Optional[OAuthToken] = None

	def remove(self, *args):
		# Deletes an attribute from an instance of this class.
		for section in args:
			self.__delattr__(section)
		return self

class Subject(BaseModel):
	subject_id: int
	name: str
	teacher: str
	room: str

class TermDate(BaseModel):
	name: str
	start: int
	end: int

class Mark(BaseModel):
	mark_id: int
	user_id: int
	test_name: str
	class_name: str
	mark: int
	grade: str

class Homework(BaseModel):
	homework_id: int
	name: str
	class_id: int
	user_id: int
	due_date: int

class Event(BaseModel):
	event_id: int
	user_id: int
	name: str
	time: int
	description: str

class Class(BaseModel):
	class_id: int
	teacher_id: int
	class_name: int
	students: str