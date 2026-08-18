from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from schemas import MetaCreate, MetaUpdate
from models import Meta, User
from dependencies import pegar_usuario_atual, pegar_sessao

metas_router = APIRouter(
    prefix="/metas",
    tags=["Metas"]
)



# =========================
# CRIAR META
# =========================

@metas_router.post("/criar_meta", status_code=status.HTTP_201_CREATED)
def criar_meta(
    dados: MetaCreate,
    session: Session = Depends(pegar_sessao),
    usuario: User = Depends(pegar_usuario_atual)
):
    nova_meta = Meta(
        id_usuario=usuario.id,
        titulo=dados.titulo,
        prazo=dados.prazo,
        categoria=dados.categoria,
        descricao=dados.descricao,
        status="em andamento"
    )

    session.add(nova_meta)
    session.commit()
    session.refresh(nova_meta)

    return nova_meta


# =========================
# LISTAR METAS DO USUÁRIO
# =========================

@metas_router.get("/listar_metas")
def listar_metas(
    session: Session = Depends(pegar_sessao),
    usuario: User = Depends(pegar_usuario_atual)
):
    metas = (
        session.query(Meta)
        .filter(Meta.id_usuario == usuario.id)
        .all()
    )

    return metas


# =========================
# BUSCAR META
# =========================

@metas_router.get("/buscar_meta_id/{meta_id}")
def buscar_meta(
    meta_id: int,
    session: Session = Depends(pegar_sessao),
    usuario: User = Depends(pegar_usuario_atual)
):
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

    return meta


# =========================
# ATUALIZAR META
# =========================

@metas_router.put("/atualizar_meta/{meta_id}")
def atualizar_meta(
    meta_id: int,
    dados: MetaUpdate,
    session: Session = Depends(pegar_sessao),
    usuario: User = Depends(pegar_usuario_atual)
):
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

    if dados.titulo is not None:
        meta.titulo = dados.titulo

    if dados.prazo is not None:
        meta.prazo = dados.prazo

    if dados.categoria is not None:
        meta.categoria = dados.categoria

    if dados.descricao is not None:
        meta.descricao = dados.descricao

    if dados.status is not None:
        if dados.status not in ["concluida", "em andamento"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Status inválido"
            )

        meta.status = dados.status

    session.commit()
    session.refresh(meta)

    return meta


# =========================
# DELETAR META
# =========================

@metas_router.delete("/deletar_meta/{meta_id}")
def deletar_meta(
    meta_id: int,
    session: Session = Depends(pegar_sessao),
    usuario: User = Depends(pegar_usuario_atual)
):
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

    session.delete(meta)
    session.commit()

    return {
        "message": "Meta deletada com sucesso"
    }