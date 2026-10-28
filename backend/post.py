from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from models import (
    Comunidade,
    Curtida,
    Meta,
    MembroComunidade,
    Sessao,
    Post,
    Seguidor,
    User,
)

from schemas import (
    PostSchema,
    PostResponseSchema,
    FeedPostSchema,
)

from dependencies import (
    pegar_sessao,
    pegar_usuario_atual,
)


post_router = APIRouter(
    prefix="/post",
    tags=["post"],
)


# ============================================================
# MONTAR ITEM DO FEED
# ============================================================

def _montar_feed_item(
    post: Post,
    usuario_atual,
    likes: int,
    liked: bool,
) -> FeedPostSchema:

    return FeedPostSchema(
        id=post.id,
        conteudo=post.conteudo,
        imagem=post.imagem,
        data_postagem=post.data_postagem,

        tipo=post.tipo,
        meta_id=post.meta_id,
        sessao_id=post.sessao_id,

        meta=(
            {
                "id": post.meta.id,
                "titulo": post.meta.titulo,
                "categoria": post.meta.categoria,
                "status": post.meta.status,
            }
            if post.meta
            else None
        ),

        sessao=(
            {
                "id": post.sessao.id,
                "meta_id": post.sessao.meta_id,
                "inicio": post.sessao.inicio,
                "duracao": post.sessao.duracao,
            }
            if post.sessao
            else None
        ),

        likes=likes,
        liked=liked,

        # Comentários não são carregados junto com o feed.
        # O front busca somente quando o usuário abrir.
        total_comentarios=0,

        comunidade=(
            {
                "id": post.comunidade.id,
                "nome": post.comunidade.nome,
            }
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


# ============================================================
# QUERY BASE DO FEED
# ============================================================

def _feed_query(
    session: Session,
    usuario_id: int,
):
    likes_count = (
        session.query(
            func.count(
                Curtida.usuario_id
            )
        )
        .filter(
            Curtida.post_id == Post.id
        )
        .correlate(Post)
        .scalar_subquery()
    )

    liked_by_current_user = (
        session.query(
            Curtida.usuario_id
        )
        .filter(
            Curtida.post_id == Post.id,
            Curtida.usuario_id == usuario_id,
        )
        .correlate(Post)
        .exists()
    )

    return (
        session
        .query(
            Post,
            likes_count,
            liked_by_current_user,
        )
        .options(
            joinedload(Post.usuario),
            joinedload(Post.comunidade),
            joinedload(Post.meta),
            joinedload(Post.sessao),
        )
    )


# ============================================================
# VALIDAR PARTICIPAÇÃO EM COMUNIDADE
# ============================================================

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
        raise HTTPException(
            status_code=404,
            detail="Comunidade não encontrada.",
        )

    participando = (
        session
        .query(
            MembroComunidade.usuario_id
        )
        .filter(
            MembroComunidade.comunidade_id
            == comunidade.id,

            MembroComunidade.usuario_id
            == usuario_id,
        )
        .first()
    )

    if participando is None:
        raise HTTPException(
            status_code=403,
            detail=(
                "Você precisa participar da "
                "comunidade para publicar nela."
            ),
        )

    return comunidade


# ============================================================
# VALIDAR CONQUISTA
# ============================================================

def _validar_tipo_post(
    session: Session,
    usuario_id: int,
    tipo: str,
    meta_id: int | None,
    sessao_id: int | None,
) -> tuple[Meta | None, Sessao | None]:

    if tipo == "geral":
        if meta_id is not None or sessao_id is not None:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Posts comuns não podem estar "
                    "vinculados a meta ou sessão."
                ),
            )

        return None, None


    if tipo == "conquista":
        if meta_id is None:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Uma conquista precisa estar "
                    "vinculada a uma meta."
                ),
            )

        if sessao_id is not None:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Uma conquista não pode estar "
                    "vinculada a uma sessão de foco."
                ),
            )

        meta = (
            session.query(Meta)
            .filter(
                Meta.id == meta_id,
                Meta.usuario_id == usuario_id,
            )
            .first()
        )

        if meta is None:
            raise HTTPException(
                status_code=404,
                detail=(
                    "Meta não encontrada ou não "
                    "pertence ao usuário."
                ),
            )

        if meta.status != "concluida":
            raise HTTPException(
                status_code=400,
                detail=(
                    "A meta precisa estar concluída "
                    "antes de ser compartilhada."
                ),
            )

        return meta, None


    if tipo == "foco":
        if sessao_id is None:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Um post de foco precisa estar "
                    "vinculado a uma sessão."
                ),
            )

        sessao = (
            session.query(Sessao)
            .join(Meta)
            .filter(
                Sessao.id == sessao_id,
                Meta.usuario_id == usuario_id,
            )
            .first()
        )

        if sessao is None:
            raise HTTPException(
                status_code=404,
                detail=(
                    "Sessão não encontrada ou não "
                    "pertence ao usuário."
                ),
            )

        if (
            meta_id is not None
            and int(meta_id) != int(sessao.meta_id)
        ):
            raise HTTPException(
                status_code=400,
                detail=(
                    "A meta informada não corresponde "
                    "à sessão de foco."
                ),
            )

        meta = (
            session.query(Meta)
            .filter(Meta.id == sessao.meta_id)
            .first()
        )

        return meta, sessao


    raise HTTPException(
        status_code=400,
        detail="Tipo de post inválido.",
    )


# ============================================================
# CRIAR POST
# ============================================================

@post_router.post(
    "/criar_post",
    response_model=PostResponseSchema,
)
async def criar_post(
    post_schema: PostSchema,
    usuario=Depends(
        pegar_usuario_atual
    ),
    session: Session = Depends(
        pegar_sessao
    ),
):

    if (
        post_schema.comunidade_id
        is not None
    ):
        _validar_participacao_comunidade(
            session,
            post_schema.comunidade_id,
            usuario.id,
        )


    _validar_tipo_post(
        session,
        usuario.id,
        post_schema.tipo,
        post_schema.meta_id,
        post_schema.sessao_id,
    )


    try:
        novo_post = Post(
            usuario_id=usuario.id,
            conteudo=post_schema.conteudo,
            imagem=post_schema.imagem,
            comunidade_id=(
                post_schema.comunidade_id
            ),
            tipo=post_schema.tipo,
            meta_id=post_schema.meta_id,
            sessao_id=post_schema.sessao_id,
        )

        session.add(novo_post)
        session.commit()
        session.refresh(novo_post)

        return novo_post

    except HTTPException:
        raise

    except Exception as e:
        session.rollback()

        raise HTTPException(
            status_code=500,
            detail=(
                f"Erro ao criar o post: {str(e)}"
            ),
        )


# ============================================================
# FILTRO DE TIPO DO FEED
# ============================================================

def _aplicar_filtro_tipo_feed(
    query,
    tipo: str | None,
):
    if tipo is None:
        return query

    tipo_normalizado = (
        str(tipo)
        .strip()
        .lower()
    )

    if tipo_normalizado not in {
        "geral",
        "conquista",
        "foco",
    }:
        raise HTTPException(
            status_code=400,
            detail="Tipo de post inválido.",
        )

    return query.filter(
        Post.tipo == tipo_normalizado
    )


# ============================================================
# FEED GERAL
# ============================================================

@post_router.get(
    "/feed",
    response_model=list[FeedPostSchema],
)
async def obter_feed(
    session: Session = Depends(
        pegar_sessao
    ),
    usuario_atual=Depends(
        pegar_usuario_atual
    ),
    offset: int = Query(
        default=0,
        ge=0,
    ),
    limit: int = Query(
        default=4,
        ge=1,
        le=4,
    ),
    tipo: str | None = Query(
        default=None,
    ),
):
    try:
        query = _aplicar_filtro_tipo_feed(
            _feed_query(
                session,
                usuario_atual.id,
            ),
            tipo,
        )

        posts = (
            query
            .order_by(
                Post.data_postagem.desc(),
                Post.id.desc(),
            )
            .offset(offset)
            .limit(limit)
            .all()
        )

        return [
            _montar_feed_item(
                post,
                usuario_atual,
                likes,
                liked,
            )
            for post, likes, liked
            in posts
        ]

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=(
                f"Erro ao obter o feed: {str(e)}"
            ),
        )


# ============================================================
# FEED SEGUINDO
# ============================================================

@post_router.get(
    "/feed/seguindo",
    response_model=list[FeedPostSchema],
)
async def obter_feed_seguindo(
    session: Session = Depends(
        pegar_sessao
    ),
    usuario_atual=Depends(
        pegar_usuario_atual
    ),
    offset: int = Query(
        default=0,
        ge=0,
    ),
    limit: int = Query(
        default=4,
        ge=1,
        le=4,
    ),
    tipo: str | None = Query(
        default=None,
    ),
):
    try:
        query = _aplicar_filtro_tipo_feed(
            _feed_query(
                session,
                usuario_atual.id,
            ),
            tipo,
        )

        posts = (
            query
            .filter(
                Post.usuario_id.in_(
                    session
                    .query(
                        Seguidor.seguindo_id
                    )
                    .filter(
                        Seguidor.seguidor_id
                        == usuario_atual.id
                    )
                )
            )
            .order_by(
                Post.data_postagem.desc(),
                Post.id.desc(),
            )
            .offset(offset)
            .limit(limit)
            .all()
        )

        return [
            _montar_feed_item(
                post,
                usuario_atual,
                likes,
                liked,
            )
            for post, likes, liked
            in posts
        ]

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=(
                "Erro ao obter feed de "
                f"seguidos: {str(e)}"
            ),
        )


# ============================================================
# FEED DE COMUNIDADES
# ============================================================

@post_router.get(
    "/feed/comunidades",
    response_model=list[FeedPostSchema],
)
async def obter_feed_comunidades(
    comunidade_id: int | None = None,

    session: Session = Depends(
        pegar_sessao
    ),

    usuario_atual=Depends(
        pegar_usuario_atual
    ),

    offset: int = Query(
        default=0,
        ge=0,
    ),

    limit: int = Query(
        default=4,
        ge=1,
        le=4,
    ),

    tipo: str | None = Query(
        default=None,
    ),
):

    membership = (
        session
        .query(
            MembroComunidade.comunidade_id
        )
        .filter(
            MembroComunidade.usuario_id
            == usuario_atual.id
        )
    )

    if comunidade_id is not None:

        comunidade_existe = (
            session
            .query(
                Comunidade.id
            )
            .filter(
                Comunidade.id
                == comunidade_id,

                Comunidade.ativa.is_(True),
            )
            .first()
        )

        if not comunidade_existe:
            raise HTTPException(
                status_code=404,
                detail=(
                    "Comunidade não encontrada."
                ),
            )

        participa = (
            session
            .query(
                MembroComunidade.comunidade_id
            )
            .filter(
                MembroComunidade.comunidade_id
                == comunidade_id,

                MembroComunidade.usuario_id
                == usuario_atual.id,
            )
            .first()
        )

        if not participa:
            raise HTTPException(
                status_code=403,
                detail=(
                    "Você precisa participar da "
                    "comunidade para ver esse feed."
                ),
            )

        membership = (
            membership.filter(
                MembroComunidade.comunidade_id
                == comunidade_id
            )
        )

    try:
        query = _aplicar_filtro_tipo_feed(
            _feed_query(
                session,
                usuario_atual.id,
            ),
            tipo,
        )

        posts = (
            query
            .filter(
                Post.comunidade_id.in_(
                    membership
                )
            )
            .order_by(
                Post.data_postagem.desc(),
                Post.id.desc(),
            )
            .offset(offset)
            .limit(limit)
            .all()
        )

        return [
            _montar_feed_item(
                post,
                usuario_atual,
                likes,
                liked,
            )
            for post, likes, liked
            in posts
        ]

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=(
                "Erro ao obter feed de "
                f"comunidades: {str(e)}"
            ),
        )


# ============================================================
# POSTS DE UM USUÁRIO
# ============================================================

@post_router.get(
    "/usuario/{usuario_id}",
    response_model=list[FeedPostSchema],
)
async def obter_posts_usuario(
    usuario_id: int,

    session: Session = Depends(
        pegar_sessao
    ),

    usuario_atual=Depends(
        pegar_usuario_atual
    ),

    offset: int = Query(
        default=0,
        ge=0,
    ),

    limit: int = Query(
        default=20,
        ge=1,
        le=50,
    ),
):
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
            detail="Usuário não encontrado.",
        )

    try:
        posts = (
            _feed_query(
                session,
                usuario_atual.id,
            )
            .filter(
                Post.usuario_id
                == usuario_id
            )
            .order_by(
                Post.data_postagem.desc(),
                Post.id.desc(),
            )
            .offset(offset)
            .limit(limit)
            .all()
        )

        return [
            _montar_feed_item(
                post,
                usuario_atual,
                likes,
                liked,
            )
            for post, likes, liked
            in posts
        ]

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=(
                "Erro ao obter posts do "
                f"usuário: {str(e)}"
            ),
        )


# ============================================================
# DELETAR POST
# ============================================================

@post_router.delete(
    "/deletar/{post_id}"
)
async def deletar_post(
    post_id: int,

    usuario_atual=Depends(
        pegar_usuario_atual
    ),

    session: Session = Depends(
        pegar_sessao
    ),
):
    try:
        post = (
            session.query(Post)
            .filter(
                Post.id == post_id
            )
            .first()
        )

        if not post:
            raise HTTPException(
                status_code=404,
                detail="Post não encontrado.",
            )

        if (
            post.usuario_id
            != usuario_atual.id

            and not usuario_atual.admin
        ):
            raise HTTPException(
                status_code=403,
                detail="Sem permissão.",
            )

        session.delete(post)
        session.commit()

        return {
            "message": (
                "Post deletado com sucesso!"
            ),
            "post_id": post_id,
        }

    except HTTPException:
        raise

    except Exception as e:
        session.rollback()

        raise HTTPException(
            status_code=500,
            detail=(
                f"Erro ao deletar o post: {str(e)}"
            ),
        )


# ============================================================
# CURTIR POST
# ============================================================

@post_router.post(
    "/curtir/{post_id}"
)
async def curtir_post(
    post_id: int,

    session: Session = Depends(
        pegar_sessao
    ),

    usuario_atual=Depends(
        pegar_usuario_atual
    ),
):
    try:
        post = (
            session.query(Post)
            .filter(
                Post.id == post_id
            )
            .first()
        )

        if not post:
            raise HTTPException(
                status_code=404,
                detail="Post não encontrado",
            )

        curtida = (
            session.query(Curtida)
            .filter(
                Curtida.post_id
                == post_id,

                Curtida.usuario_id
                == usuario_atual.id,
            )
            .first()
        )

        if curtida:
            raise HTTPException(
                status_code=400,
                detail="Já curtiu",
            )

        nova_curtida = Curtida(
            post_id=post_id,
            usuario_id=usuario_atual.id,
        )

        session.add(nova_curtida)
        session.commit()

        return {
            "message": "Curtido"
        }

    except HTTPException:
        raise

    except Exception as e:
        session.rollback()

        raise HTTPException(
            status_code=500,
            detail=(
                f"Erro ao curtir: {str(e)}"
            ),
        )


# ============================================================
# REMOVER CURTIDA
# ============================================================

@post_router.delete(
    "/remover_curtida/{post_id}"
)
async def remover_curtida(
    post_id: int,

    session: Session = Depends(
        pegar_sessao
    ),

    usuario_atual=Depends(
        pegar_usuario_atual
    ),
):
    try:
        curtida = (
            session.query(Curtida)
            .filter(
                Curtida.post_id
                == post_id,

                Curtida.usuario_id
                == usuario_atual.id,
            )
            .first()
        )

        if not curtida:
            raise HTTPException(
                status_code=404,
                detail="Você não curtiu",
            )

        session.delete(curtida)
        session.commit()

        return {
            "message": (
                "Curtida removida"
            )
        }

    except HTTPException:
        raise

    except Exception as e:
        session.rollback()

        raise HTTPException(
            status_code=500,
            detail=(
                "Erro ao remover "
                f"curtida: {str(e)}"
            ),
        )


# ============================================================
# BUSCAR POST POR CONTEÚDO
# ============================================================

@post_router.get(
    "/buscar_post_conteudo/",
    response_model=list[FeedPostSchema],
)
async def buscar_post_conteudo(
    q: str,

    session: Session = Depends(
        pegar_sessao
    ),

    usuario_atual=Depends(
        pegar_usuario_atual
    ),
):
    try:
        termo = q.strip()

        if not termo:
            return []

        posts = (
            _feed_query(
                session,
                usuario_atual.id,
            )
            .filter(
                Post.conteudo.ilike(
                    f"%{termo}%"
                )
            )
            .order_by(
                Post.data_postagem.desc(),
                Post.id.desc(),
            )
            .limit(50)
            .all()
        )

        return [
            _montar_feed_item(
                post,
                usuario_atual,
                likes,
                liked,
            )
            for post, likes, liked
            in posts
        ]

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=(
                f"Erro na busca: {str(e)}"
            ),
        )


# ============================================================
# ATUALIZAR POST
# ============================================================

@post_router.put(
    "/atualizar_post/{post_id}",
    response_model=PostResponseSchema,
)
async def atualizar_post(
    post_id: int,
    post_schema: PostSchema,

    session: Session = Depends(
        pegar_sessao
    ),

    usuario_atual=Depends(
        pegar_usuario_atual
    ),
):
    try:
        post = (
            session.query(Post)
            .filter(
                Post.id == post_id
            )
            .first()
        )

        if not post:
            raise HTTPException(
                status_code=404,
                detail="Post não encontrado",
            )

        if (
            post.usuario_id
            != usuario_atual.id
        ):
            raise HTTPException(
                status_code=403,
                detail="Sem permissão",
            )

        post.conteudo = (
            post_schema.conteudo
        )

        post.imagem = (
            post_schema.imagem
        )

        if (
            "comunidade_id"
            in post_schema.model_fields_set
        ):
            comunidade_id = (
                post_schema.comunidade_id
            )

            if comunidade_id is not None:
                _validar_participacao_comunidade(
                    session,
                    comunidade_id,
                    usuario_atual.id,
                )

            post.comunidade_id = (
                comunidade_id
            )


        tipo_novo = (
            post_schema.tipo
            if "tipo" in post_schema.model_fields_set
            else post.tipo
        )

        meta_id_novo = (
            post_schema.meta_id
            if "meta_id" in post_schema.model_fields_set
            else post.meta_id
        )

        sessao_id_novo = (
            post_schema.sessao_id
            if "sessao_id" in post_schema.model_fields_set
            else post.sessao_id
        )


        if (
            "tipo" in post_schema.model_fields_set
            or "meta_id" in post_schema.model_fields_set
            or "sessao_id" in post_schema.model_fields_set
        ):
            _validar_tipo_post(
                session,
                usuario_atual.id,
                tipo_novo,
                meta_id_novo,
                sessao_id_novo,
            )

            post.tipo = tipo_novo
            post.meta_id = meta_id_novo
            post.sessao_id = sessao_id_novo


        session.commit()
        session.refresh(post)

        return post

    except HTTPException:
        raise

    except Exception as e:
        session.rollback()

        raise HTTPException(
            status_code=500,
            detail=(
                "Erro ao atualizar "
                f"post: {str(e)}"
            ),
        )


# ============================================================
# OBTER POST POR ID
# ============================================================

@post_router.get(
    "/{post_id}",
    response_model=FeedPostSchema,
)
async def obter_post_por_id(
    post_id: int,

    session: Session = Depends(
        pegar_sessao
    ),

    usuario_atual=Depends(
        pegar_usuario_atual
    ),
):
    try:
        resultado = (
            _feed_query(
                session,
                usuario_atual.id,
            )
            .filter(
                Post.id == post_id
            )
            .first()
        )

        if not resultado:
            raise HTTPException(
                status_code=404,
                detail="Post não encontrado.",
            )

        post, likes, liked = resultado

        return _montar_feed_item(
            post,
            usuario_atual,
            likes,
            liked,
        )

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=(
                f"Erro ao obter o post: {str(e)}"
            ),
        )