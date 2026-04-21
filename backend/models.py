from sqlalchemy import Column, Integer, String, Boolean, Text, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


# =========================
# USUÁRIOS
# =========================
class User(Base):
    __tablename__ = "Usuarios"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False)
    senha_hash = Column(String(255), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    status_conta = Column(Boolean, default=True)
    foto_perfil = Column(String(500))

    # Relacionamentos
    posts = relationship("Post", back_populates="usuario", cascade="all, delete")
    comentarios = relationship("Comentario", back_populates="usuario", cascade="all, delete")
    curtidas = relationship("Curtida", back_populates="usuario", cascade="all, delete")

    seguidores = relationship(
        "Seguidor",
        foreign_keys="Seguidor.seguindo_id",
        back_populates="seguindo",
        cascade="all, delete"
    )

    seguindo = relationship(
        "Seguidor",
        foreign_keys="Seguidor.seguidor_id",
        back_populates="seguidor",
        cascade="all, delete"
    )


# =========================
# POSTS
# =========================
class Post(Base):
    __tablename__ = "Posts"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("Usuarios.id", ondelete="CASCADE"), nullable=False)
    conteudo = Column(Text, nullable=False)
    imagem = Column(Text)
    data_postagem = Column(DateTime, server_default=func.now())

    usuario = relationship("User", back_populates="posts")
    comentarios = relationship("Comentario", back_populates="post", cascade="all, delete")
    curtidas = relationship("Curtida", back_populates="post", cascade="all, delete")


# =========================
# COMENTÁRIOS
# =========================
class Comentario(Base):
    __tablename__ = "comentarios"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("Usuarios.id", ondelete="CASCADE"), nullable=False)
    post_id = Column(Integer, ForeignKey("Posts.id"), nullable=False)
    comentario = Column(Text, nullable=False)
    data_comentario = Column(DateTime, server_default=func.now())

    usuario = relationship("User", back_populates="comentarios")
    post = relationship("Post", back_populates="comentarios")


# =========================
# CURTIDAS
# =========================
class Curtida(Base):
    __tablename__ = "curtidas"

    usuario_id = Column(Integer, ForeignKey("Usuarios.id", ondelete="CASCADE"), primary_key=True)
    post_id = Column(Integer, ForeignKey("Posts.id"), primary_key=True)
    data_curtida = Column(DateTime, server_default=func.now())

    usuario = relationship("User", back_populates="curtidas")
    post = relationship("Post", back_populates="curtidas")


# =========================
# SEGUIDORES
# =========================
class Seguidor(Base):
    __tablename__ = "seguidores"

    seguidor_id = Column(Integer, ForeignKey("Usuarios.id", ondelete="CASCADE"), primary_key=True)
    seguindo_id = Column(Integer, ForeignKey("Usuarios.id", ondelete="CASCADE"), primary_key=True)
    data_follow = Column(DateTime, server_default=func.now())

    __table_args__ = (
        CheckConstraint("seguidor_id <> seguindo_id", name="check_self_follow"),
    )

    seguidor = relationship("User", foreign_keys=[seguidor_id], back_populates="seguindo")
    seguindo = relationship("User", foreign_keys=[seguindo_id], back_populates="seguidores")
