from enum import IntEnum
from pydantic import BaseModel
from typing import List, Optional

class Permissions(IntEnum):
	Student = 0
	Teacher = 1

class OAuthToken(BaseModel):
	access_token: str
	uid: int

class User(BaseModel):
	uid: int = None
	username: str
	password: str
	salt: str
	created_at: int
	permissions: int
	session: Optional[OAuthToken] = None

	def remove(self, *args):
		# Deletes an attribute from an instance of this class.
		for section in args:
			self.__delattr__(section)
		return self

class Subject(BaseModel):
	subject_id: int = None
	user_id: int
	name: str
	teacher: str
	room: str
	colour: str = "#FFFFFF"

class Mark(BaseModel):
	mark_id: int = None
	user_id: int
	test_name: str
	mark: int
	grade: str

class Homework(BaseModel):
	homework_id: int = None
	name: str
	class_id: int = None
	completed_by: int = None
	user_id: int = None
	due_date: int
	description: str = None
	completed: bool

class Event(BaseModel):
	event_id: int = None
	user_id: int
	name: str
	time: int
	description: str = None
	private: bool

class Class(BaseModel):
	class_id: int = None
	teacher_id: int
	class_name: str
	homework: List[Homework] = []
	students: List[User] = []

class ClassStudentJoin(BaseModel):
	student_id: int
	class_id: int

class UserSubjectJoin(BaseModel):
	user_id: int
	subject_id: int
	day: int
	period: int

class Timetable:
	monday: list
	tuesday: list
	wednesday: list
	thursday: list
	friday: list

	def __init__(self):
		self.monday = [None] * 9
		self.tuesday = [None] * 9
		self.wednesday = [None] * 9
		self.thursday = [None] * 9
		self.friday = [None] * 9

	def get_client_format(self):
		"""
		This returns the timetable in the format which the client expects.
		"""
		return [self.monday, self.tuesday, self.wednesday, self.thursday, self.friday]
	
class RegistrationCode(BaseModel):
	code: str
	permissions: Permissions