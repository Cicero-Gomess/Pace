from pydantic import BaseModel
from typing import Optional

class UsuarioSchema(BaseModel):
    username: str
    email: str
    senha: str

    class Config:
        from_attributes = True