
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    Text,
    JSON,
    DateTime,
    Date,
    ForeignKey,
    CheckConstraint,
    Enum,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from database import Base


# =========================
# USUÁRIOS
# =========================

class User(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nome_usuario = Column(String(50), unique=True, nullable=False)
    senha_hash = Column(String(255), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    status_conta = Column(Boolean, default=True)
    foto_perfil = Column(String(500))
    admin = Column(Boolean, default=False, nullable=False)

    # Relacionamentos
    posts = relationship(
        "Post",
        back_populates="usuario",
        cascade="all, delete-orphan",
    )

    comentarios = relationship(
        "Comentario",
        back_populates="usuario",
        cascade="all, delete-orphan",
    )

    curtidas = relationship(
        "Curtida",
        back_populates="usuario",
        cascade="all, delete-orphan",
    )

    # Usuários que seguem este usuário
    seguidores = relationship(
        "Seguidor",
        foreign_keys="Seguidor.seguindo_id",
        back_populates="seguindo",
        cascade="all, delete-orphan",
    )

    # Usuários que este usuário segue
    seguindo = relationship(
        "Seguidor",
        foreign_keys="Seguidor.seguidor_id",
        back_populates="seguidor",
        cascade="all, delete-orphan",
    )

    metas = relationship(
        "Meta",
        back_populates="usuario",
        cascade="all, delete-orphan",
    )

    # Comunidades criadas pelo usuário
    comunidades_criadas = relationship(
        "Comunidade",
        back_populates="criador",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    # Comunidades das quais o usuário participa
    membros_comunidade = relationship(
        "MembroComunidade",
        back_populates="usuario",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


# =========================
# POSTS
# =========================

class Post(Base):
    __tablename__ = "posts"

    __table_args__ = (
        CheckConstraint(
            "tipo IN ('geral', 'conquista', 'foco')",
            name="check_posts_tipo",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)

    usuario_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        nullable=False,
    )

    # NULL = feed geral; preenchido = post de comunidade
    comunidade_id = Column(
        Integer,
        ForeignKey("comunidades.id", ondelete="CASCADE"),
        nullable=True,
    )

    # geral = post comum; conquista = meta concluída compartilhada
    tipo = Column(
        String(20),
        nullable=False,
        default="geral",
        server_default="geral",
    )

    # Preenchido apenas quando o post representa uma meta concluída
    meta_id = Column(
        Integer,
        ForeignKey("metas.id", ondelete="SET NULL"),
        nullable=True,
    )

    # Preenchido quando o post representa uma sessão de foco
    sessao_id = Column(
        Integer,
        ForeignKey("sessoes.id", ondelete="SET NULL"),
        nullable=True,
    )

    conteudo = Column(Text, nullable=False)
    imagem = Column(Text)
    data_postagem = Column(DateTime, server_default=func.now())

    usuario = relationship("User", back_populates="posts")

    comunidade = relationship(
        "Comunidade",
        back_populates="posts",
    )

    meta = relationship(
        "Meta",
        back_populates="posts",
    )

    sessao = relationship(
        "Sessao",
        back_populates="posts",
    )

    comentarios = relationship(
        "Comentario",
        back_populates="post",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    curtidas = relationship(
        "Curtida",
        back_populates="post",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


# =========================
# COMENTÁRIOS
# =========================

class Comentario(Base):
    __tablename__ = "comentarios"

    id = Column(Integer, primary_key=True, index=True)

    usuario_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        nullable=False,
    )

    post_id = Column(
        Integer,
        ForeignKey("posts.id", ondelete="CASCADE"),
        nullable=False,
    )

    comentario = Column(Text, nullable=False)
    data_comentario = Column(DateTime, server_default=func.now())

    usuario = relationship("User", back_populates="comentarios")
    post = relationship("Post", back_populates="comentarios")


# =========================
# CURTIDAS
# =========================

class Curtida(Base):
    __tablename__ = "curtidas"

    usuario_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        primary_key=True,
    )

    post_id = Column(
        Integer,
        ForeignKey("posts.id", ondelete="CASCADE"),
        primary_key=True,
    )

    data_curtida = Column(DateTime, server_default=func.now())

    usuario = relationship("User", back_populates="curtidas")
    post = relationship("Post", back_populates="curtidas")


# =========================
# SEGUIDORES
# =========================

class Seguidor(Base):
    __tablename__ = "seguidores"

    seguidor_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        primary_key=True,
    )

    seguindo_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        primary_key=True,
    )

    data_seguimento = Column(
        DateTime,
        server_default=func.now(),
    )

    __table_args__ = (
        CheckConstraint(
            "seguidor_id <> seguindo_id",
            name="check_self_follow",
        ),
    )

    # Quem iniciou o seguimento
    seguidor = relationship(
        "User",
        foreign_keys=[seguidor_id],
        back_populates="seguindo",
    )

    # Quem está sendo seguido
    seguindo = relationship(
        "User",
        foreign_keys=[seguindo_id],
        back_populates="seguidores",
    )


# =========================
# METAS
# =========================

class Meta(Base):
    __tablename__ = "metas"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)

    usuario_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        nullable=False,
    )

    titulo = Column(String(100), nullable=False)
    prazo = Column(Date)

    categoria = Column(
        Enum(
            "Pessoal",
            "Estudos",
            "Trabalho",
            "Saúde",
            "Projeto",
            "Outro",
        ),
        nullable=False,
    )

    descricao = Column(String(200))

    status = Column(
        Enum("concluida", "em andamento"),
        nullable=False,
        default="em andamento",
    )

    usuario = relationship(
        "User",
        back_populates="metas",
    )

    sessoes = relationship(
        "Sessao",
        back_populates="meta",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    posts = relationship(
        "Post",
        back_populates="meta",
        passive_deletes=True,
    )


# =========================
# SESSÕES
# =========================

class Sessao(Base):
    __tablename__ = "sessoes"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)

    meta_id = Column(
        Integer,
        ForeignKey("metas.id", ondelete="CASCADE"),
        nullable=False,
    )

    inicio = Column(DateTime, nullable=False)

    # Duração armazenada em segundos
    duracao = Column(Integer, nullable=False)

    __table_args__ = (
        CheckConstraint(
            "duracao > 0",
            name="check_duracao_positiva",
        ),
    )

    meta = relationship(
        "Meta",
        back_populates="sessoes",
    )

    posts = relationship(
        "Post",
        back_populates="sessao",
        passive_deletes=True,
    )


# =========================
# COMUNIDADES
# =========================

class Comunidade(Base):
    __tablename__ = "comunidades"
    __table_args__ = (
        CheckConstraint(
            "privacidade IN ('publica', 'privada')",
            name="check_comunidade_privacidade",
        ),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)

    criador_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        nullable=False,
    )

    nome = Column(String(100), nullable=False, unique=True)
    descricao = Column(String(500))
    topicos = Column(JSON, nullable=False, default=list)
    privacidade = Column(
        String(10),
        nullable=False,
        default="publica",
        server_default="publica",
    )
    imagem = Column(String(500))

    data_criacao = Column(
        DateTime,
        nullable=False,
        server_default=func.now(),
    )

    ativa = Column(
        Boolean,
        nullable=False,
        default=True,
        server_default="1",
    )

    # Relacionamentos
    criador = relationship(
        "User",
        back_populates="comunidades_criadas",
    )

    membros = relationship(
        "MembroComunidade",
        back_populates="comunidade",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    posts = relationship(
        "Post",
        back_populates="comunidade",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


# =========================
# MEMBROS DAS COMUNIDADES
# =========================

class MembroComunidade(Base):
    __tablename__ = "membros_comunidade"

    comunidade_id = Column(
        Integer,
        ForeignKey("comunidades.id", ondelete="CASCADE"),
        primary_key=True,
    )

    usuario_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        primary_key=True,
    )

    cargo = Column(
        Enum("membro", "moderador", "admin"),
        nullable=False,
        default="membro",
    )

    data_entrada = Column(
        DateTime,
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        UniqueConstraint(
            "comunidade_id",
            "usuario_id",
            name="uq_membro_comunidade",
        ),
    )

    comunidade = relationship(
        "Comunidade",
        back_populates="membros",
    )

    usuario = relationship(
        "User",
        back_populates="membros_comunidade",
    )