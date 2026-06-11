from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from dependencies import pegar_sessao, pegar_usuario_atual
from models import User, Seguidor

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
    username: str = "",
    skip: int = 0,
    limit: int = 100,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    """
    Busca perfis pelo `username` (query string `username`).
    Retorna lista de usuários cujo `username` contenha o termo (case-insensitive).
    Se username estiver vazio, retorna TODOS os usuários com paginação.
    EXCLUI o próprio usuário logado dos resultados.
    """
    try:
        query = session.query(User)
        
        # Excluir o usuário logado dos resultados
        query = query.filter(User.id != usuario_atual.id)
        
        # Filtrar por username se fornecido
        if username and username.strip():
            query = query.filter(User.username.ilike(f"%{username}%"))
        
        # Aplicar paginação
        usuarios = (
            query
            .order_by(User.username.asc())
            .offset(skip)
            .limit(limit)
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


# =========================
# ENDPOINTS DE SEGUIR/DEIXAR DE SEGUIR
# =========================

@profile_router.post("/follow/{usuario_id}")
async def seguir_usuario(
    usuario_id: int,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    """
    Segue um usuário. 
    Retorna erro se:
    - Tentar seguir a si mesmo
    - Usuário não existir
    - Já está seguindo o usuário
    """
    try:
        # Verificar se está tentando seguir a si mesmo
        if usuario_id == usuario_atual.id:
            raise HTTPException(status_code=400, detail="Você não pode seguir a si mesmo")

        # Verificar se o usuário a ser seguido existe
        usuario_para_seguir = session.query(User).filter(User.id == usuario_id).first()
        if not usuario_para_seguir:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        # Verificar se já está seguindo
        ja_segue = session.query(Seguidor).filter(
            Seguidor.seguidor_id == usuario_atual.id,
            Seguidor.seguindo_id == usuario_id
        ).first()

        if ja_segue:
            raise HTTPException(status_code=400, detail="Você já está seguindo este usuário")

        # Criar o relacionamento de seguidor
        novo_seguidor = Seguidor(
            seguidor_id=usuario_atual.id,
            seguindo_id=usuario_id
        )
        session.add(novo_seguidor)
        session.commit()

        return {
            "message": f"Você agora está seguindo {usuario_para_seguir.username}",
            "usuario_id": usuario_id,
            "seguindo": True
        }

    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail="Erro ao seguir usuário")


@profile_router.post("/unfollow/{usuario_id}")
async def deixar_de_seguir_usuario(
    usuario_id: int,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    """
    Deixa de seguir um usuário.
    Retorna erro se:
    - Usuário não existir
    - Não está seguindo o usuário
    """
    try:
        # Verificar se o usuário existe
        usuario_alvo = session.query(User).filter(User.id == usuario_id).first()
        if not usuario_alvo:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        # Verificar se está seguindo
        seguidor = session.query(Seguidor).filter(
            Seguidor.seguidor_id == usuario_atual.id,
            Seguidor.seguindo_id == usuario_id
        ).first()

        if not seguidor:
            raise HTTPException(status_code=400, detail="Você não está seguindo este usuário")

        # Remover o relacionamento
        session.delete(seguidor)
        session.commit()

        return {
            "message": f"Você deixou de seguir {usuario_alvo.username}",
            "usuario_id": usuario_id,
            "seguindo": False
        }

    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail="Erro ao deixar de seguir usuário")


@profile_router.get("/{usuario_id}/followers")
async def listar_seguidores(
    usuario_id: int,
    skip: int = 0,
    limit: int = 100,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    """
    Lista os seguidores de um usuário.
    Retorna informações dos usuários que seguem o usuário especificado.
    """
    try:
        # Verificar se o usuário existe
        usuario = session.query(User).filter(User.id == usuario_id).first()
        if not usuario:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        # Buscar seguidores
        seguidores = (
            session.query(User)
            .join(Seguidor, Seguidor.seguidor_id == User.id)
            .filter(Seguidor.seguindo_id == usuario_id)
            .offset(skip)
            .limit(limit)
            .all()
        )

        total = (
            session.query(Seguidor)
            .filter(Seguidor.seguindo_id == usuario_id)
            .count()
        )

        resultado = {
            "total": total,
            "usuarios": [
                {
                    "id": s.id,
                    "username": s.username,
                    "email": s.email,
                    "foto_perfil": getattr(s, "foto_perfil", None),
                    "seguindo": bool(
                        session.query(Seguidor).filter(
                            Seguidor.seguidor_id == usuario_atual.id,
                            Seguidor.seguindo_id == s.id
                        ).first()
                    )
                }
                for s in seguidores
            ]
        }

        return resultado

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Erro ao buscar seguidores")


@profile_router.get("/{usuario_id}/following")
async def listar_seguindo(
    usuario_id: int,
    skip: int = 0,
    limit: int = 100,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    """
    Lista os usuários que um usuário está seguindo.
    Retorna informações dos usuários que o usuário especificado segue.
    """
    try:
        # Verificar se o usuário existe
        usuario = session.query(User).filter(User.id == usuario_id).first()
        if not usuario:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        # Buscar quem o usuário está seguindo
        seguindo = (
            session.query(User)
            .join(Seguidor, Seguidor.seguindo_id == User.id)
            .filter(Seguidor.seguidor_id == usuario_id)
            .offset(skip)
            .limit(limit)
            .all()
        )

        total = (
            session.query(Seguidor)
            .filter(Seguidor.seguidor_id == usuario_id)
            .count()
        )

        resultado = {
            "total": total,
            "usuarios": [
                {
                    "id": s.id,
                    "username": s.username,
                    "email": s.email,
                    "foto_perfil": getattr(s, "foto_perfil", None),
                    "seguindo": bool(
                        session.query(Seguidor).filter(
                            Seguidor.seguidor_id == usuario_atual.id,
                            Seguidor.seguindo_id == s.id
                        ).first()
                    )
                }
                for s in seguindo
            ]
        }

        return resultado

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Erro ao buscar usuários seguindo")


@profile_router.get("/{usuario_id}")
async def obter_perfil_usuario(
    usuario_id: int,
    session: Session = Depends(pegar_sessao),
    usuario_atual: User = Depends(pegar_usuario_atual)
):
    """
    Obtém o perfil de um usuário (diferente do /me que é o próprio).
    Retorna informações do usuário e estatísticas (seguidores, seguindo, posts).
    """
    try:
        # Buscar o usuário
        usuario = session.query(User).filter(User.id == usuario_id).first()
        if not usuario:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        # Contar seguidores
        total_seguidores = (
            session.query(Seguidor)
            .filter(Seguidor.seguindo_id == usuario_id)
            .count()
        )

        # Contar seguindo
        total_seguindo = (
            session.query(Seguidor)
            .filter(Seguidor.seguidor_id == usuario_id)
            .count()
        )

        # Contar posts
        total_posts = session.query(User).filter(User.id == usuario_id).first().posts.__len__()

        # Verificar se o usuário atual segue este usuário
        segue = bool(
            session.query(Seguidor).filter(
                Seguidor.seguidor_id == usuario_atual.id,
                Seguidor.seguindo_id == usuario_id
            ).first()
        )

        return {
            "id": usuario.id,
            "username": usuario.username,
            "email": usuario.email,
            "foto_perfil": getattr(usuario, "foto_perfil", None),
            "total_seguidores": total_seguidores,
            "total_seguindo": total_seguindo,
            "total_posts": total_posts,
            "segue": segue,
            "eh_eu": usuario_id == usuario_atual.id
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Erro ao buscar perfil do usuário")