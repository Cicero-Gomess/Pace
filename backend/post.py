from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from models import Post
from schemas import PostSchema, PostResponseSchema
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
