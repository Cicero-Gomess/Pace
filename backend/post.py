from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from models import Post, Curtida
from schemas import PostSchema, PostResponseSchema, FeedPostSchema
from dependencies import pegar_sessao, pegar_usuario_atual

post_router = APIRouter(prefix="/post", tags=["post"])


@post_router.post("/criar_post", response_model=PostResponseSchema)
async def criar_post(
    post_schema: PostSchema,
    usuario=Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao)
):
    try:
        novo_post = Post(
            usuario_id=usuario.id,
            conteudo=post_schema.conteudo,
            imagem=post_schema.imagem
        )

        session.add(novo_post)
        session.commit()
        session.refresh(novo_post)

        return novo_post

    except Exception as e:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao criar o post: {str(e)}"
        )


@post_router.get("/feed", response_model=list[FeedPostSchema])
async def obter_feed(
    session: Session = Depends(pegar_sessao),
    usuario_atual=Depends(pegar_usuario_atual)
):
    try:
        posts = (
            session.query(Post)
            .join(Post.usuario)
            .order_by(Post.data_postagem.desc())
            .all()
        )

        feed_posts = []
        for post in posts:
            total_curtidas = len(post.curtidas)

            usuario_curtiu = any(
                curtida.usuario_id == usuario_atual.id
                for curtida in post.curtidas
            )

            feed_post = FeedPostSchema(
                id=post.id,
                conteudo=post.conteudo,
                imagem=post.imagem,
                data_postagem=post.data_postagem,
                likes=total_curtidas,
                liked=usuario_curtiu,
                usuario={
                    "id": post.usuario.id,
                    "username": post.usuario.username,
                    "email": post.usuario.email,
                    "foto_perfil": post.usuario.foto_perfil
                }
            )

            feed_posts.append(feed_post)

        return feed_posts

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter o feed: {str(e)}"
        )


@post_router.delete("/deletar/{post_id}")
async def deletar_post(
    post_id: int,
    usuario_atual=Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao)
):
    try:
        post = session.query(Post).filter(Post.id == post_id).first()

        if not post:
            raise HTTPException(
                status_code=404,
                detail="Post não encontrado."
            )

        if post.usuario_id != usuario_atual.id:
            raise HTTPException(
                status_code=403,
                detail="Você não tem permissão para deletar este post."
            )

        session.delete(post)
        session.commit()

        return {
            "message": "Post deletado com sucesso!",
            "post_id": post_id
        }

    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao deletar o post: {str(e)}"
        )


@post_router.post("/curtir/{post_id}")
async def curtir_post(
    post_id: int,
    session: Session = Depends(pegar_sessao),
    usuario_atual=Depends(pegar_usuario_atual)
):
    try:
        post = session.query(Post).filter(Post.id == post_id).first()

        if not post:
            raise HTTPException(status_code=404, detail="Post não encontrado")

        curtida = (
            session.query(Curtida)
            .filter(
                Curtida.post_id == post_id,
                Curtida.usuario_id == usuario_atual.id
            )
            .first()
        )

        if curtida:
            raise HTTPException(status_code=400, detail="Você já curtiu esse post")

        nova_curtida = Curtida(
            post_id=post_id,
            usuario_id=usuario_atual.id
        )

        session.add(nova_curtida)
        session.commit()

        return {
            "message": "Post curtido",
            "post_id": post_id
        }
    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao curtir o post: {str(e)}"
        )

@post_router.delete("/remover_curtida/{post_id}")
async def remover_curtida(
    post_id: int,
    session: Session = Depends(pegar_sessao),
    usuario_atual=Depends(pegar_usuario_atual)
):
    try:
        curtida = (
            session.query(Curtida)
            .filter(
                Curtida.post_id == post_id,
                Curtida.usuario_id == usuario_atual.id
            )
            .first()
        )

        if not curtida:
            raise HTTPException(status_code=404, detail="Você não curtiu esse post")

        session.delete(curtida)
        session.commit()

        return {
            "message": "Curtida removida com sucesso",
            "post_id": post_id
        }
    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao remover a curtida: {str(e)}"
        )


@post_router.get("/{post_id}", response_model=FeedPostSchema)
async def obter_post_por_id(
    post_id: int,
    session: Session = Depends(pegar_sessao),
    usuario_atual=Depends(pegar_usuario_atual)
):
    try:
        post = (
            session.query(Post)
            .filter(Post.id == post_id)
            .first()
        )

        if not post:
            raise HTTPException(
                status_code=404,
                detail="Post não encontrado."
            )

        total_curtidas = len(post.curtidas)

        usuario_curtiu = any(
            curtida.usuario_id == usuario_atual.id
            for curtida in post.curtidas
        )

        feed_post = FeedPostSchema(
            id=post.id,
            conteudo=post.conteudo,
            imagem=post.imagem,
            data_postagem=post.data_postagem,
            likes=total_curtidas,
            liked=usuario_curtiu,
            usuario={
                "id": post.usuario.id,
                "username": post.usuario.username,
                "email": post.usuario.email,
                "foto_perfil": post.usuario.foto_perfil
            }
        )

        return feed_post

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter o post: {str(e)}"
        )
@post_router.put("/atualizar_post/{post_id}")
async def atualizar_post(post_id: int,post_schema: PostSchema, session: Session = Depends(pegar_sessao), usuario_atual=Depends(pegar_usuario_atual)):
    try:
        post = session.query(Post).filter(Post.id == post_id).first()

        if not post:
            raise HTTPException(status_code=404, detail="Post não encontrado")
        if post.usuario_id != usuario_atual.id:
            raise HTTPException(status_code=403, detail="Você não tem permissão para editar esse post")
        post.conteudo = post_schema.conteudo
        post.imagem = post_schema.imagem

        session.commit()

        return {"message": "post atualizado com sucesso"}
    
    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail="Erro ao atualizar post")
        
