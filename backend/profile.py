from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from dependencies import pegar_sessao, pegar_usuario_atual
from models import User

profile_router = APIRouter(prefix="/profile", tags=["profile"])

class FotoUpdate(BaseModel):
    foto_url: str


@profile_router.get("/me")
async def buscar_meu_perfil(
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    return {
        "id": usuario_atual.id,
        "username": usuario_atual.username,
        "email": usuario_atual.email,
        "foto_perfil": getattr(usuario_atual, "foto_perfil", None)
    }


@profile_router.post("/trocar_foto")
async def trocar_foto(
    dados: FotoUpdate,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    try:
        if not dados.foto_url or not dados.foto_url.strip():
            raise HTTPException(status_code=400, detail="URL da foto invalida")

        usuario_atual.foto_perfil = dados.foto_url
        session.commit()
        session.refresh(usuario_atual)

        return {
            "message": "Foto de perfil atualizada com sucesso",
            "foto_perfil": usuario_atual.foto_perfil,
            "username": usuario_atual.username,
            "id": usuario_atual.id
        }

    except HTTPException:
        raise
    except Exception:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail="Erro ao atualizar a foto de perfil"
        )


@profile_router.get("/buscar_por_username/")
async def buscar_por_username(
    username: str,
    session: Session = Depends(pegar_sessao)
):
    """
    Busca perfis pelo `username` (query string `username`).
    Retorna lista de usuários cujo `username` contenha o termo (case-insensitive).
    """
    try:
        if not username or not username.strip():
            raise HTTPException(status_code=400, detail="Parâmetro username vazio")

        usuarios = (
            session.query(User)
            .filter(User.username.ilike(f"%{username}%"))
            .order_by(User.username.asc())
            .all()
        )

        resultados = [
            {
                "id": u.id,
                "username": u.username,
                "email": u.email,
                "foto_perfil": getattr(u, "foto_perfil", None)
            }
            for u in usuarios
        ]

        return resultados

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Erro ao buscar usuários")
