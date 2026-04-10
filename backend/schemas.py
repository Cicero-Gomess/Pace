from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UsuarioSchema(BaseModel):
    username: str
    email: str
    senha: str

    class Config:
        from_attributes = True


class PostSchema(BaseModel):
    conteudo: str
    imagem: Optional[str] = None

    class Config:
        from_attributes = True


class PostResponseSchema(BaseModel):
    id: int
    usuario_id: int
    conteudo: str
    imagem: Optional[str]
    data_postagem: datetime

    class Config:
        from_attributes = True


class FeedPostSchema(BaseModel):
    id: int
    conteudo: str
    imagem: Optional[str]
    data_postagem: datetime
    usuario: dict  # Informações básicas do usuário

    class Config:
        from_attributes = True