from fastapi import Depends, HTTPException, Request
from database import db
from sqlalchemy.orm import sessionmaker, Session
from jose import jwt, JWTError
from fastapi.security import OAuth2PasswordBearer
import os
from dotenv import load_dotenv
from models import User

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")
ACCESS_TOKEN_EXPIRE_MINUTES = os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES")

COOKIE_NAME = "access_token"

# auto_error=False: permite autenticação via cookie HttpOnly (web) ou Bearer (Flutter)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token", auto_error=False)


def pegar_sessao():
    try:
        Session = sessionmaker(bind=db)
        session = Session()
        yield session
    finally:
        session.close()


def _extrair_token(request: Request, bearer_token: str | None) -> str | None:
    if bearer_token:
        return bearer_token
    return request.cookies.get(COOKIE_NAME)


def pegar_usuario_atual(
    request: Request,
    token: str | None = Depends(oauth2_scheme),
    session: Session = Depends(pegar_sessao),
):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Não foi possível validar as credenciais",
        headers={"WWW-Authenticate": "Bearer"},
    )

    jwt_token = _extrair_token(request, token)

    if not jwt_token:
        raise credentials_exception

    try:
        payload = jwt.decode(jwt_token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")

        if email is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    usuario = session.query(User).filter(User.email == email).first()

    if usuario is None:
        raise credentials_exception

    return usuario
