from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from models import Sessao, Meta, User
from dependencies import pegar_usuario_atual, pegar_sessao
from schemas import SessaoCreate

sessao_router = APIRouter(
    prefix="/sessoes",
    tags=["Sessões"]
)




# =========================
# CRIAR SESSÃO
# =========================

@sessao_router.post("/criar_sessao", status_code=status.HTTP_201_CREATED)
def criar_sessao(
    dados: SessaoCreate,
    session: Session = Depends(pegar_sessao),
    usuario: User = Depends(pegar_usuario_atual)
):
    # Verifica se a meta existe
    meta = (
        db.query(Meta)
        .filter(
            Meta.id == dados.id_meta,
            Meta.id_usuario == usuario.id
        )
        .first()
    )

    if not meta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Meta não encontrada"
        )

    if dados.duracao <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A duração deve ser maior que zero"
        )

    nova_sessao = Sessao(
        id_meta=dados.id_meta,
        inicio=dados.inicio,
        duracao=dados.duracao
    )

    session.add(nova_sessao)
    session.commit()
    session.refresh(nova_sessao)

    return nova_sessao


# =========================
# LISTAR SESSÕES DE UMA META
# =========================

@sessao_router.get("/meta/{meta_id}")
def listar_sessoes_meta(
    meta_id: int,
    session: Session = Depends(pegar_sessao),
    usuario: User = Depends(pegar_usuario_atual)
):
    # Primeiro verifica se a meta pertence ao usuário
    meta = (
        session.query(Meta)
        .filter(
            Meta.id == meta_id,
            Meta.id_usuario == usuario.id
        )
        .first()
    )

    if not meta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Meta não encontrada"
        )

    sessoes = (
        session.query(Sessao)
        .filter(Sessao.id_meta == meta_id)
        .order_by(Sessao.inicio.desc())
        .all()
    )

    return sessoes


# =========================
# BUSCAR SESSÃO
# =========================

@sessao_router.get("/buscar_sessao/{sessao_id}")
def buscar_sessao(
    sessao_id: int,
    session: Session = Depends(pegar_sessao),
    usuario: User = Depends(pegar_usuario_atual)
):
    sessao = (
        session.query(Sessao)
        .join(Meta)
        .filter(
            Sessao.id == sessao_id,
            Meta.id_usuario == usuario.id
        )
        .first()
    )

    if not sessao:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sessão não encontrada"
        )

    return sessao


# =========================
# DELETAR SESSÃO
# =========================

@sessao_router.delete("/deletar_sessao/{sessao_id}")
def deletar_sessao(
    sessao_id: int,
    session: Session = Depends(pegar_sessao),
    usuario: User = Depends(pegar_usuario_atual)
):
    sessao = (
        session.query(Sessao)
        .join(Meta)
        .filter(
            Sessao.id == sessao_id,
            Meta.id_usuario == usuario.id
        )
        .first()
    )

    if not sessao:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sessão não encontrada"
        )

    session.delete(sessao)
    session.commit()

    return {
        "message": "Sessão deletada com sucesso"
    }