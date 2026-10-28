from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from dependencies import pegar_sessao, pegar_usuario_atual
from models import User, Seguidor


profile_router = APIRouter(
    prefix="/profile",
    tags=["profile"]
)


class FotoUpdate(BaseModel):
    foto_url: str


# ============================================================
# MEU PERFIL
# ============================================================

@profile_router.get("/me")
async def buscar_meu_perfil(
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    return {
        "id": usuario_atual.id,
        "username": usuario_atual.nome_usuario,
        "email": usuario_atual.email,
        "foto_perfil": getattr(
            usuario_atual,
            "foto_perfil",
            None
        )
    }


# ============================================================
# TROCAR FOTO
# ============================================================

@profile_router.post("/trocar_foto")
async def trocar_foto(
    dados: FotoUpdate,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    try:
        if (
            not dados.foto_url
            or not dados.foto_url.strip()
        ):
            raise HTTPException(
                status_code=400,
                detail="URL da foto inválida"
            )

        usuario_atual.foto_perfil = (
            dados.foto_url.strip()
        )

        session.commit()
        session.refresh(usuario_atual)

        return {
            "message": (
                "Foto de perfil atualizada "
                "com sucesso"
            ),
            "foto_perfil": (
                usuario_atual.foto_perfil
            ),
            "username": (
                usuario_atual.nome_usuario
            ),
            "id": usuario_atual.id
        }

    except HTTPException:
        raise

    except Exception:
        session.rollback()

        raise HTTPException(
            status_code=500,
            detail=(
                "Erro ao atualizar "
                "a foto de perfil"
            )
        )


# ============================================================
# BUSCAR USUÁRIOS
# ============================================================

@profile_router.get("/buscar_por_username/")
async def buscar_por_username(
    username: str = "",
    skip: int = 0,
    limit: int = 100,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    """
    Busca perfis pelo username.

    - Não retorna o próprio usuário.
    - Busca por nome de usuário.
    - Não retorna todos os usuários quando
      a busca está vazia.
    """

    try:
        termo = username.strip()

        # Não carregar usuários automaticamente
        if not termo:
            return []

        query = (
            session.query(User)
            .filter(
                User.id != usuario_atual.id
            )
            .filter(
                User.nome_usuario.ilike(
                    f"%{termo}%"
                )
            )
        )

        usuarios = (
            query
            .order_by(
                User.nome_usuario.asc()
            )
            .offset(skip)
            .limit(limit)
            .all()
        )

        resultados = [
            {
                "id": usuario.id,
                "username": (
                    usuario.nome_usuario
                ),
                "email": usuario.email,
                "foto_perfil": getattr(
                    usuario,
                    "foto_perfil",
                    None
                )
            }
            for usuario in usuarios
        ]

        return resultados

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Erro ao buscar usuários"
        )


# ============================================================
# SEGUIR USUÁRIO
# ============================================================

@profile_router.post("/follow/{usuario_id}")
async def seguir_usuario(
    usuario_id: int,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    try:
        if usuario_id == usuario_atual.id:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Você não pode seguir "
                    "a si mesmo"
                )
            )

        usuario_para_seguir = (
            session.query(User)
            .filter(
                User.id == usuario_id
            )
            .first()
        )

        if not usuario_para_seguir:
            raise HTTPException(
                status_code=404,
                detail="Usuário não encontrado"
            )

        ja_segue = (
            session.query(Seguidor)
            .filter(
                Seguidor.seguidor_id
                == usuario_atual.id,

                Seguidor.seguindo_id
                == usuario_id
            )
            .first()
        )

        if ja_segue:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Você já está seguindo "
                    "este usuário"
                )
            )

        novo_seguidor = Seguidor(
            seguidor_id=usuario_atual.id,
            seguindo_id=usuario_id
        )

        session.add(novo_seguidor)
        session.commit()

        return {
            "message": (
                "Você agora está seguindo "
                f"{usuario_para_seguir.nome_usuario}"
            ),
            "usuario_id": usuario_id,
            "seguindo": True
        }

    except HTTPException:
        raise

    except Exception:
        session.rollback()

        raise HTTPException(
            status_code=500,
            detail="Erro ao seguir usuário"
        )


# ============================================================
# DEIXAR DE SEGUIR
# ============================================================

@profile_router.post("/unfollow/{usuario_id}")
async def deixar_de_seguir_usuario(
    usuario_id: int,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    try:
        usuario_alvo = (
            session.query(User)
            .filter(
                User.id == usuario_id
            )
            .first()
        )

        if not usuario_alvo:
            raise HTTPException(
                status_code=404,
                detail="Usuário não encontrado"
            )

        seguidor = (
            session.query(Seguidor)
            .filter(
                Seguidor.seguidor_id
                == usuario_atual.id,

                Seguidor.seguindo_id
                == usuario_id
            )
            .first()
        )

        if not seguidor:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Você não está seguindo "
                    "este usuário"
                )
            )

        session.delete(seguidor)
        session.commit()

        return {
            "message": (
                "Você deixou de seguir "
                f"{usuario_alvo.nome_usuario}"
            ),
            "usuario_id": usuario_id,
            "seguindo": False
        }

    except HTTPException:
        raise

    except Exception:
        session.rollback()

        raise HTTPException(
            status_code=500,
            detail=(
                "Erro ao deixar de "
                "seguir usuário"
            )
        )


# ============================================================
# LISTAR SEGUIDORES
# ============================================================

@profile_router.get("/{usuario_id}/followers")
async def listar_seguidores(
    usuario_id: int,
    skip: int = 0,
    limit: int = 100,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    try:
        usuario = (
            session.query(User)
            .filter(
                User.id == usuario_id
            )
            .first()
        )

        if not usuario:
            raise HTTPException(
                status_code=404,
                detail="Usuário não encontrado"
            )

        seguidores = (
            session.query(User)
            .join(
                Seguidor,
                Seguidor.seguidor_id
                == User.id
            )
            .filter(
                Seguidor.seguindo_id
                == usuario_id
            )
            .offset(skip)
            .limit(limit)
            .all()
        )

        total = (
            session.query(Seguidor)
            .filter(
                Seguidor.seguindo_id
                == usuario_id
            )
            .count()
        )

        resultado = {
            "total": total,
            "usuarios": [
                {
                    "id": seguidor.id,
                    "username": (
                        seguidor.nome_usuario
                    ),
                    "email": seguidor.email,
                    "foto_perfil": getattr(
                        seguidor,
                        "foto_perfil",
                        None
                    ),
                    "seguindo": bool(
                        session
                        .query(Seguidor)
                        .filter(
                            Seguidor.seguidor_id
                            == usuario_atual.id,

                            Seguidor.seguindo_id
                            == seguidor.id
                        )
                        .first()
                    )
                }
                for seguidor in seguidores
            ]
        }

        return resultado

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail=(
                "Erro ao buscar seguidores"
            )
        )


# ============================================================
# LISTAR SEGUINDO
# ============================================================

@profile_router.get("/{usuario_id}/following")
async def listar_seguindo(
    usuario_id: int,
    skip: int = 0,
    limit: int = 100,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    try:
        usuario = (
            session.query(User)
            .filter(
                User.id == usuario_id
            )
            .first()
        )

        if not usuario:
            raise HTTPException(
                status_code=404,
                detail="Usuário não encontrado"
            )

        seguindo = (
            session.query(User)
            .join(
                Seguidor,
                Seguidor.seguindo_id
                == User.id
            )
            .filter(
                Seguidor.seguidor_id
                == usuario_id
            )
            .offset(skip)
            .limit(limit)
            .all()
        )

        total = (
            session.query(Seguidor)
            .filter(
                Seguidor.seguidor_id
                == usuario_id
            )
            .count()
        )

        resultado = {
            "total": total,
            "usuarios": [
                {
                    "id": usuario_seguido.id,
                    "username": (
                        usuario_seguido.nome_usuario
                    ),
                    "email": (
                        usuario_seguido.email
                    ),
                    "foto_perfil": getattr(
                        usuario_seguido,
                        "foto_perfil",
                        None
                    ),
                    "seguindo": bool(
                        session
                        .query(Seguidor)
                        .filter(
                            Seguidor.seguidor_id
                            == usuario_atual.id,

                            Seguidor.seguindo_id
                            == usuario_seguido.id
                        )
                        .first()
                    )
                }
                for usuario_seguido in seguindo
            ]
        }

        return resultado

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail=(
                "Erro ao buscar usuários "
                "seguindo"
            )
        )


# ============================================================
# PERFIL DE OUTRO USUÁRIO
# ============================================================

@profile_router.get("/{usuario_id}")
async def obter_perfil_usuario(
    usuario_id: int,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    try:
        usuario = (
            session.query(User)
            .filter(
                User.id == usuario_id
            )
            .first()
        )

        if not usuario:
            raise HTTPException(
                status_code=404,
                detail="Usuário não encontrado"
            )

        total_seguidores = (
            session.query(Seguidor)
            .filter(
                Seguidor.seguindo_id
                == usuario_id
            )
            .count()
        )

        total_seguindo = (
            session.query(Seguidor)
            .filter(
                Seguidor.seguidor_id
                == usuario_id
            )
            .count()
        )

        total_posts = len(
            usuario.posts
        )

        segue = bool(
            session.query(Seguidor)
            .filter(
                Seguidor.seguidor_id
                == usuario_atual.id,

                Seguidor.seguindo_id
                == usuario_id
            )
            .first()
        )

        return {
            "id": usuario.id,
            "username": (
                usuario.nome_usuario
            ),
            "email": usuario.email,
            "foto_perfil": getattr(
                usuario,
                "foto_perfil",
                None
            ),
            "total_seguidores": (
                total_seguidores
            ),
            "total_seguindo": (
                total_seguindo
            ),
            "total_posts": total_posts,
            "segue": segue,
            "eh_eu": (
                usuario_id
                == usuario_atual.id
            )
        }

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail=(
                "Erro ao buscar perfil "
                "do usuário"
            )
        )