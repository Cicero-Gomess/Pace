from fastapi import APIRouter, HTTPException, Depends, Response
from schemas import UsuarioSchema, AtualizarSenhaSchema
from dependencies import pegar_sessao, pegar_usuario_atual, COOKIE_NAME
from sqlalchemy.orm import Session
from models import User
from pwdlib import PasswordHash
from fastapi.security import OAuth2PasswordRequestForm
from datetime import timedelta, datetime
from jose import jwt
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
COOKIE_SECURE = os.getenv("COOKIE_SECURE", "false").lower() == "true"
COOKIE_SAMESITE = os.getenv("COOKIE_SAMESITE", "lax")

password_hasher = PasswordHash.recommended()

auth_router = APIRouter(prefix="/auth", tags=["auth"])


def fazer_hash(senha: str) -> str:
    return password_hasher.hash(senha)


def verificar_senha(senha: str, senha_hash: str) -> bool:
    return password_hasher.verify(senha, senha_hash)


def criar_token(data: dict):
    dados = data.copy()
    expira = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    dados.update({"exp": expira})
    return jwt.encode(dados, SECRET_KEY, algorithm=ALGORITHM)


def _definir_cookie_token(response: Response, access_token: str) -> None:
    response.set_cookie(
        key=COOKIE_NAME,
        value=access_token,
        httponly=True,
        secure=COOKIE_SECURE,
        samesite=COOKIE_SAMESITE,
        max_age=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        path="/",
    )


def _remover_cookie_token(response: Response) -> None:
    response.delete_cookie(
        key=COOKIE_NAME,
        path="/",
        httponly=True,
        secure=COOKIE_SECURE,
        samesite=COOKIE_SAMESITE,
    )


@auth_router.post("/criar_usuario")
def criar_usuario(usuario_schema: UsuarioSchema, session: Session = Depends(pegar_sessao)):
    try:
        usuario_existente = session.query(User).filter(
            (User.username == usuario_schema.username) | (User.email == usuario_schema.email)
        ).first()

        if usuario_existente:
            raise HTTPException(status_code=400, detail="Nome de usuário ou email já existe.")

        senha_hash = fazer_hash(usuario_schema.senha)

        novo_usuario = User(
            username=usuario_schema.username,
            email=usuario_schema.email,
            senha_hash=senha_hash,
        )

        session.add(novo_usuario)
        session.commit()
        session.refresh(novo_usuario)

        return {
            "message": "Usuário criado com sucesso!",
            "usuario_id": novo_usuario.id,
        }
    except HTTPException:
        raise
    except Exception:
        session.rollback()
        raise HTTPException(status_code=500, detail="Erro ao criar o usuário")


@auth_router.post("/token")
def login(
    response: Response,
    form_data: OAuth2PasswordRequestForm = Depends(),
    session: Session = Depends(pegar_sessao),
):
    usuario = session.query(User).filter(
        (User.email == form_data.username) | (User.username == form_data.username)
    ).first()

    if not usuario or not verificar_senha(form_data.password, usuario.senha_hash):
        raise HTTPException(status_code=401, detail="Email, usuário ou senha inválidos.")

    access_token = criar_token(data={"sub": usuario.email})
    _definir_cookie_token(response, access_token)

    # access_token no JSON mantém compatibilidade com Flutter (Bearer no header)
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "message": "Login realizado com sucesso",
    }


@auth_router.post("/logout")
def logout(response: Response):
    _remover_cookie_token(response)
    return {"message": "Logout realizado com sucesso"}


@auth_router.get("/me")
def me(usuario: User = Depends(pegar_usuario_atual)):
    return {
        "id": usuario.id,
        "username": usuario.username,
        "email": usuario.email,
        "foto_perfil": usuario.foto_perfil,
    }


@auth_router.put("/atualizar_senha")
async def atualizar_senha(
    senha_schema: AtualizarSenhaSchema,
    usuario=Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    try:
        if not verificar_senha(senha_schema.senha_atual, usuario.senha_hash):
            raise HTTPException(status_code=400, detail="Senha atual incorreta.")
        if verificar_senha(senha_schema.nova_senha, usuario.senha_hash):
            raise HTTPException(400, "A nova senha não pode ser igual à atual")

        nova_senha_hash = fazer_hash(senha_schema.nova_senha)
        usuario.senha_hash = nova_senha_hash

        session.commit()
        session.refresh(usuario)

        return {"message": "Senha atualizada com sucesso!"}

    except HTTPException:
        raise
    except Exception:
        session.rollback()
        raise HTTPException(status_code=500, detail="Erro ao atualizar a senha")
