from pydantic import BaseModel, Field, field_validator
from typing import Literal, Optional
from datetime import datetime
from datetime import date

class UsuarioSchema(BaseModel):
    nome_usuario: str
    email: str
    senha: str

    class Config:
        from_attributes = True


class PostSchema(BaseModel):
    conteudo: str
    imagem: Optional[str] = None
    comunidade_id: Optional[int] = None

    class Config:
        from_attributes = True


class ComunidadeResumoSchema(BaseModel):
    id: int
    nome: str

    class Config:
        from_attributes = True


class PostResponseSchema(BaseModel):
    id: int
    usuario_id: int
    conteudo: str
    imagem: Optional[str]
    data_postagem: datetime
    comunidade_id: Optional[int] = None
    comunidade: Optional[ComunidadeResumoSchema] = None

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
    total_comentarios: int = 0
    comunidade: Optional[ComunidadeResumoSchema] = None

    class Config:
        from_attributes = True


class ComunidadeCreateSchema(BaseModel):
    nome: str = Field(min_length=3, max_length=50)
    descricao: str = Field(min_length=10, max_length=220)
    topicos: list[str] = Field(min_length=1, max_length=5)
    privacidade: Literal["publica", "privada"] = "publica"

    @field_validator("nome", "descricao", mode="before")
    @classmethod
    def strip_text(cls, value: str):
        if isinstance(value, str):
            value = value.strip()
        if value == "":
            raise ValueError("O campo não pode ficar vazio.")
        return value

    @field_validator("topicos")
    @classmethod
    def validate_topics(cls, topics: list[str]) -> list[str]:
        return _normalizar_topicos(topics)


class ComunidadeUpdateSchema(BaseModel):
    nome: Optional[str] = Field(default=None, min_length=3, max_length=50)
    descricao: Optional[str] = Field(default=None, min_length=10, max_length=220)
    topicos: Optional[list[str]] = Field(default=None, min_length=1, max_length=5)
    privacidade: Optional[Literal["publica", "privada"]] = None

    @field_validator("nome", "descricao", mode="before")
    @classmethod
    def strip_optional_text(cls, value: Optional[str]) -> Optional[str]:
        if value is None or not isinstance(value, str):
            return value
        value = value.strip()
        if not value:
            raise ValueError("O campo não pode ficar vazio.")
        return value

    @field_validator("topicos")
    @classmethod
    def validate_optional_topics(
        cls,
        topics: Optional[list[str]],
    ) -> Optional[list[str]]:
        if topics is None:
            return topics
        return _normalizar_topicos(topics)


def _normalizar_topicos(topics: list[str]) -> list[str]:
    normalized = []
    seen = set()
    for topic in topics:
        topic = topic.strip().lstrip("#")
        if not topic:
            continue
        key = topic.casefold()
        if key not in seen:
            normalized.append(topic)
            seen.add(key)
    if not normalized:
        raise ValueError("Adicione pelo menos um tópico.")
    if len(normalized) > 5:
        raise ValueError("Uma comunidade pode ter no máximo 5 tópicos.")
    return normalized


class ComunidadeResponseSchema(BaseModel):
    id: int
    nome: str
    descricao: Optional[str]
    topicos: list[str]
    privacidade: str
    criador_id: int
    data_criacao: datetime
    membros_count: int
    sou_membro: bool
    sou_criador: bool


class MembroComunidadeResponseSchema(BaseModel):
    usuario_id: int
    username: str
    foto_perfil: Optional[str] = None
    cargo: str
    data_entrada: datetime


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
    username: str = Field(validation_alias="nome_usuario")
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


class MetaCreate(BaseModel):
    titulo: str
    prazo: Optional[date] = None
    categoria: str
    descricao: Optional[str] = None


class MetaUpdate(BaseModel):
    titulo: Optional[str] = None
    prazo: Optional[date] = None
    categoria: Optional[str] = None
    descricao: Optional[str] = None
    status: Optional[str] = None

class SessaoCreate(BaseModel):
    id_meta: int
    inicio: datetime
    duracao: int