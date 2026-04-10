from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from models import Post
from schemas import PostSchema, PostResponseSchema, FeedPostSchema
from dependencies import pegar_sessao, pegar_usuario_atual


post_router = APIRouter(prefix="/post", tags=["post"])


@post_router.post("/criar_post", response_model=PostResponseSchema)
async def criar_post(
    post_schema: PostSchema,
    usuario = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao)
):
    """
    Cria um novo post para o usuário autenticado.
    
    - **conteudo**: Conteúdo obrigatório do post (texto)
    - **imagem**: URL da imagem (opcional)
    """
    
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
    usuario_atual = Depends(pegar_usuario_atual)
):
    """
    Obtém o feed da rede social com todos os posts existentes.
    
    Retorna posts ordenados por data de criação (mais recentes primeiro).
    """
    
    try:
        # Buscar posts com informações do usuário, ordenados por data decrescente
        posts = session.query(Post).join(Post.usuario).order_by(Post.data_postagem.desc()).all()
        
        # Formatar resposta com dados do usuário
        feed_posts = []
        for post in posts:
            feed_post = FeedPostSchema(
                id=post.id,
                conteudo=post.conteudo,
                imagem=post.imagem,
                data_postagem=post.data_postagem,
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
