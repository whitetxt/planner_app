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