from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session, joinedload
from dependencies import pegar_sessao, pegar_usuario_atual
from models import Comentario, Post
from schemas import ComentarioSchema, ComentarioResponseSchema

comments_router = APIRouter(prefix="/comments", tags=["comments"])

@comments_router.post("/adicionar_comentario/{post_id}", response_model=ComentarioResponseSchema)
async def adicionar_comentario(
    post_id: int,
    comentario_schema: ComentarioSchema,
    usuario=Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao)
):
    try:
        post = session.query(Post).filter(Post.id == post_id).first()

        if not post:
            raise HTTPException(status_code=404, detail="Post não encontrado")

        novo_comentario = Comentario(
            usuario_id=usuario.id,
            post_id=post_id,
            comentario=comentario_schema.conteudo
        )

        session.add(novo_comentario)
        session.commit()
        session.refresh(novo_comentario)

        comentario_com_usuario = (
            session.query(Comentario)
            .options(joinedload(Comentario.usuario))
            .filter(Comentario.id == novo_comentario.id)
            .first()
        )

        return comentario_com_usuario

    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao adicionar comentário: {str(e)}"
        )

@comments_router.put("/atualizar_comentario/{comentario_id}", response_model=ComentarioResponseSchema)
async def atualizar_comentario(
    comentario_id: int,
    comentario_schema: ComentarioSchema,
    usuario=Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao)
):
    try:
        comentario = session.query(Comentario).filter(Comentario.id == comentario_id).first()

        if not comentario:
            raise HTTPException(status_code=404, detail="Comentário não encontrado")

        if comentario.usuario_id != usuario.id:
            raise HTTPException(status_code=403, detail="Sem permissão")

        comentario.comentario = comentario_schema.conteudo

        session.commit()
        session.refresh(comentario)

        comentario_com_usuario = (
            session.query(Comentario)
            .options(joinedload(Comentario.usuario))
            .filter(Comentario.id == comentario.id)
            .first()
        )

        return comentario_com_usuario

    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao atualizar comentário: {str(e)}"
        )


@comments_router.delete("/deletar_comentario/{comentario_id}")
async def deletar_comentario(
    comentario_id: int,
    usuario=Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao)
):
    try:
        comentario = session.query(Comentario).filter(Comentario.id == comentario_id).first()

        if not comentario:
            raise HTTPException(status_code=404, detail="Comentário não encontrado")

        if comentario.usuario_id != usuario.id:
            raise HTTPException(status_code=403, detail="Sem permissão")

        session.delete(comentario)
        session.commit()

        return {
            "message": "Comentário deletado com sucesso",
            "comentario_id": comentario_id
        }

    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao deletar comentário: {str(e)}"
        )

@comments_router.get("/comentarios/{post_id}", response_model=list[ComentarioResponseSchema])
async def obter_comentarios(
    post_id: int,
    session: Session = Depends(pegar_sessao)
):
    try:
        comentarios = (
            session.query(Comentario)
            .options(joinedload(Comentario.usuario))
            .filter(Comentario.post_id == post_id)
            .order_by(Comentario.data_comentario.desc())
            .limit(20)
            .all()
        )

        return comentarios

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter comentários: {str(e)}"
        )