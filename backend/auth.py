from fastapi import APIRouter, HTTPException, Depends
from schemas import UsuarioSchema
from dependencies import pegar_sessao
from sqlalchemy.orm import Session
from models import User
from pwdlib import PasswordHash
from fastapi.security import OAuth2PasswordBearer

password_hasher = PasswordHash.recommended()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def fazer_hash(senha: str) -> str:
    return password_hasher.hash(senha)

def verificar_senha(senha: str, senha_hash: str) -> bool:
    return password_hasher.verify(senha, senha_hash)

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
    senha_hash = fazer_hash(usuario_schema.senha)

    novo_usuario = User(
        username=usuario_schema.username,
        email=usuario_schema.email,
        senha_hash=senha_hash)  
    
    
    session.add(novo_usuario)
    session.commit()
    
    return {"message": "Usuário criado com sucesso!", "usuario_id": novo_usuario.id}

@auth_router.post("/login")
def login(username: str, senha: str, session: Session = Depends(pegar_sessao), token: str = Depends(oauth2_scheme)):
    usuario = session.query(User).filter(User.username == username).first()
    
    if not usuario or not verificar_senha(senha, usuario.senha_hash):
        raise HTTPException(status_code=401, detail="Credenciais inválidas.")
    
    return {"token": token}