from fastapi import APIRouter, HTTPException, Depends
from schemas import UsuarioSchema
from dependencies import pegar_sessao
from sqlalchemy.orm import Session
from models import User

auth_router = APIRouter(prefix="/auth", tags=["auth"])

@auth_router.post("/criar_usuario")
def criar_usuario(usuario_schema: UsuarioSchema, session: Session = Depends(pegar_sessao)):
    # Verificar se o nome de usuário ou email já existe
    usuario_existente = session.query(User).filter(
        (User.username == usuario_schema.username) | (User.email == usuario_schema.email)
    ).first()
    
    if usuario_existente:
        raise HTTPException(status_code=400, detail="Nome de usuário ou email já existe.")
    
    # Criar um novo usuário
    novo_usuario = User(
        username=usuario_schema.username,
        email=usuario_schema.email,
        senha_hash = usuario_schema.senha)  # Função para hash da senha
    
    
    session.add(novo_usuario)
    session.commit()
    
    return {"message": "Usuário criado com sucesso!", "usuario_id": novo_usuario.id}