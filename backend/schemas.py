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


class UsuarioFeedSchema(BaseModel):
    id: int
    username: str
    email: str
    foto_perfil: Optional[str] = None

    class Config:
        from_attributes = True


class FeedPostSchema(BaseModel):
    id: int
    conteudo: str
    imagem: Optional[str]
    data_postagem: datetime
    likes: int
    liked: bool
    usuario: UsuarioFeedSchema

    class Config:
        from_attributes = True


class AtualizarSenhaSchema(BaseModel):
    senha_atual: str
    nova_senha: str

    class Config:
        from_attributes = True


class ComentarioSchema(BaseModel):
    conteudo: str

    class Config:
        from_attributes = True


class UsuarioComentarioSchema(BaseModel):
    id: int
    username: str
    foto_perfil: Optional[str] = None

    class Config:
        from_attributes = True


class ComentarioResponseSchema(BaseModel):
    id: int
    usuario_id: int
    post_id: int
    comentario: str
    data_comentario: datetime
    usuario: UsuarioComentarioSchema

    class Config:
        from_attributes = True


# =========================
# SEGUIDORES
# =========================
class SeguidorResponseSchema(BaseModel):
    id: int
    username: str
    email: str
    foto_perfil: Optional[str] = None
    seguindo: bool  # Se o usuário atual segue este usuário

    class Config:
        from_attributes = True


class SeguidorListSchema(BaseModel):
    total: int
    usuarios: list[SeguidorResponseSchema]

    class Config:
        from_attributes = True


class FollowActionSchema(BaseModel):
    message: str
    usuario_id: int
    seguindo: bool

    class Config:
        from_attributes = True
