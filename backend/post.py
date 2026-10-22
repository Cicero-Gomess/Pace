from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload
from models import (
    Comunidade,
    Comentario,
    Curtida,
    MembroComunidade,
    Post,
    Seguidor,
)
from schemas import PostSchema, PostResponseSchema, FeedPostSchema
from dependencies import pegar_sessao, pegar_usuario_atual

post_router = APIRouter(prefix="/post", tags=["post"])


def _montar_feed_item(
    post: Post,
    usuario_atual,
    likes: int,
    liked: bool,
    total_comentarios: int,
) -> FeedPostSchema:
    return FeedPostSchema(
        id=post.id,
        conteudo=post.conteudo,
        imagem=post.imagem,
        data_postagem=post.data_postagem,
        likes=likes,
        liked=liked,
        total_comentarios=total_comentarios,
        comunidade=(
            {"id": post.comunidade.id, "nome": post.comunidade.nome}
            if post.comunidade
            else None
        ),
        usuario={
            "id": post.usuario.id,
            "username": post.usuario.nome_usuario,
            "email": post.usuario.email,
            "foto_perfil": post.usuario.foto_perfil,
        },
    )


def _feed_query(session: Session, usuario_id: int):
    likes_count = (
        session.query(func.count(Curtida.usuario_id))
        .filter(Curtida.post_id == Post.id)
        .correlate(Post)
        .scalar_subquery()
    )
    liked_by_current_user = (
        session.query(Curtida.usuario_id)
        .filter(
            Curtida.post_id == Post.id,
            Curtida.usuario_id == usuario_id,
        )
        .correlate(Post)
        .exists()
    )
    comments_count = (
        session.query(func.count(Comentario.id))
        .filter(Comentario.post_id == Post.id)
        .correlate(Post)
        .scalar_subquery()
    )
    return (
        session.query(Post, likes_count, liked_by_current_user, comments_count)
        .options(joinedload(Post.usuario), joinedload(Post.comunidade))
    )


def _validar_participacao_comunidade(
    session: Session,
    comunidade_id: int,
    usuario_id: int,
) -> Comunidade:
    comunidade = (
        session.query(Comunidade)
        .filter(
            Comunidade.id == comunidade_id,
            Comunidade.ativa.is_(True),
        )
        .first()
    )
    if comunidade is None:
        raise HTTPException(status_code=404, detail="Comunidade não encontrada.")

    participando = (
        session.query(MembroComunidade.usuario_id)
        .filter(
            MembroComunidade.comunidade_id == comunidade.id,
            MembroComunidade.usuario_id == usuario_id,
        )
        .first()
    )
    if participando is None:
        raise HTTPException(
            status_code=403,
            detail="Você precisa participar da comunidade para publicar nela.",
        )
    return comunidade


@post_router.post("/criar_post", response_model=PostResponseSchema)
async def criar_post(
    post_schema: PostSchema,
    usuario=Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao)
):
    if post_schema.comunidade_id is not None:
        _validar_participacao_comunidade(
            session,
            post_schema.comunidade_id,
            usuario.id,
        )

    try:
        novo_post = Post(
            usuario_id=usuario.id,
            conteudo=post_schema.conteudo,
            imagem=post_schema.imagem,
            comunidade_id=post_schema.comunidade_id,
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
    usuario_atual=Depends(pegar_usuario_atual),
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=10, ge=1, le=10),
):
    try:
        posts = (
            _feed_query(session, usuario_atual.id)
            .order_by(Post.data_postagem.desc(), Post.id.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )
        return [
            _montar_feed_item(post, usuario_atual, likes, liked, comments)
            for post, likes, liked, comments in posts
        ]

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter o feed: {str(e)}"
        )


@post_router.get("/feed/seguindo", response_model=list[FeedPostSchema])
async def obter_feed_seguindo(
    session: Session = Depends(pegar_sessao),
    usuario_atual=Depends(pegar_usuario_atual),
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=10, ge=1, le=10),
):
    posts = (
        _feed_query(session, usuario_atual.id)
        .filter(
            Post.usuario_id.in_(
                session.query(Seguidor.seguindo_id).filter(
                    Seguidor.seguidor_id == usuario_atual.id
                )
            )
        )
        .order_by(Post.data_postagem.desc(), Post.id.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return [
        _montar_feed_item(post, usuario_atual, likes, liked, comments)
        for post, likes, liked, comments in posts
    ]


@post_router.get("/feed/comunidades", response_model=list[FeedPostSchema])
async def obter_feed_comunidades(
    comunidade_id: int | None = None,
    session: Session = Depends(pegar_sessao),
    usuario_atual=Depends(pegar_usuario_atual),
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=10, ge=1, le=10),
):
    membership = session.query(MembroComunidade.comunidade_id).filter(
        MembroComunidade.usuario_id == usuario_atual.id
    )
    if comunidade_id is not None:
        if not session.query(Comunidade.id).filter(
            Comunidade.id == comunidade_id,
            Comunidade.ativa.is_(True),
        ).first():
            raise HTTPException(status_code=404, detail="Comunidade não encontrada.")
        if not session.query(MembroComunidade.comunidade_id).filter(
            MembroComunidade.comunidade_id == comunidade_id,
            MembroComunidade.usuario_id == usuario_atual.id,
        ).first():
            raise HTTPException(
                status_code=403,
                detail="Você precisa participar da comunidade para ver esse feed.",
            )
        membership = membership.filter(MembroComunidade.comunidade_id == comunidade_id)

    posts = (
        _feed_query(session, usuario_atual.id)
        .filter(Post.comunidade_id.in_(membership))
        .order_by(Post.data_postagem.desc(), Post.id.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return [
        _montar_feed_item(post, usuario_atual, likes, liked, comments)
        for post, likes, liked, comments in posts
    ]


@post_router.delete("/deletar/{post_id}")
async def deletar_post(
    post_id: int,
    usuario_atual=Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao)
):
    try:
        post = session.query(Post).filter(Post.id == post_id).first()

        if not post:
            raise HTTPException(status_code=404, detail="Post não encontrado.")

        if post.usuario_id != usuario_atual.id and not usuario_atual.admin:
            raise HTTPException(status_code=403, detail="Sem permissão.")

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
            raise HTTPException(status_code=400, detail="Já curtiu")

        nova_curtida = Curtida(
            post_id=post_id,
            usuario_id=usuario_atual.id
        )

        session.add(nova_curtida)
        session.commit()

        return {"message": "Curtido"}

    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao curtir: {str(e)}"
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
            raise HTTPException(status_code=404, detail="Você não curtiu")

        session.delete(curtida)
        session.commit()

        return {"message": "Curtida removida"}

    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao remover curtida: {str(e)}"
        )



@post_router.get("/{post_id}", response_model=FeedPostSchema)
async def obter_post_por_id(
    post_id: int,
    session: Session = Depends(pegar_sessao),
    usuario_atual=Depends(pegar_usuario_atual)
):
    try:
        post = session.query(Post).filter(Post.id == post_id).first()

        if not post:
            raise HTTPException(status_code=404, detail="Post não encontrado.")

        total_curtidas = len(post.curtidas)
        usuario_curtiu = any(
            curtida.usuario_id == usuario_atual.id
            for curtida in post.curtidas
        )
        return _montar_feed_item(
            post,
            usuario_atual,
            total_curtidas,
            usuario_curtiu,
            len(post.comentarios),
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter o post: {str(e)}"
        )



@post_router.put("/atualizar_post/{post_id}", response_model=PostResponseSchema)
async def atualizar_post(
    post_id: int,
    post_schema: PostSchema,
    session: Session = Depends(pegar_sessao),
    usuario_atual=Depends(pegar_usuario_atual)
):
    try:
        post = session.query(Post).filter(Post.id == post_id).first()

        if not post:
            raise HTTPException(status_code=404, detail="Post não encontrado")

        if post.usuario_id != usuario_atual.id:
            raise HTTPException(status_code=403, detail="Sem permissão")

        post.conteudo = post_schema.conteudo
        post.imagem = post_schema.imagem
        if "comunidade_id" in post_schema.model_fields_set:
            comunidade_id = post_schema.comunidade_id
            if comunidade_id is not None:
                _validar_participacao_comunidade(
                    session,
                    comunidade_id,
                    usuario_atual.id,
                )
            post.comunidade_id = comunidade_id

        session.commit()
        session.refresh(post)

        return post

    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao atualizar post: {str(e)}"
        )
    
@post_router.get("/buscar_post_conteudo/")
async def buscar_post_conteudo(
    q: str,
    session: Session = Depends(pegar_sessao),
    usuario_atual=Depends(pegar_usuario_atual)
):
    """
    Busca posts pelo conteúdo (query string `q`).
    Retorna lista de posts que contenham a string `q` (case-insensitive).
    """
    try:
        if not q or not q.strip():
            raise HTTPException(status_code=400, detail="Parâmetro de busca vazio")

        posts = (
            session.query(Post)
            .join(Post.usuario)
            .filter(Post.conteudo.ilike(f"%{q}%"))
            .order_by(Post.data_postagem.desc())
            .all()
        )

        resultados = []
        for post in posts:
            total_curtidas = len(post.curtidas)
            usuario_curtiu = any(
                curtida.usuario_id == usuario_atual.id
                for curtida in post.curtidas
            )

            resultados.append(
                _montar_feed_item(
                    post,
                    usuario_atual,
                    total_curtidas,
                    usuario_curtiu,
                    len(post.comentarios),
                )
            )

        return resultados

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro na busca: {str(e)}")