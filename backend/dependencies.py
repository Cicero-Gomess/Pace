from fastapi import Depends, HTTPException
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


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")


def pegar_sessao():
    try:
        Session = sessionmaker(bind=db)
        session = Session()
        yield session
    finally:
        session.close()

def pegar_usuario_atual(token: str = Depends(oauth2_scheme), session: Session = Depends(pegar_sessao)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Não foi possível validar as credenciais",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        # 🔓 decodifica o token
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        username = payload.get("sub")

        if username is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    # 🔍 busca no banco
    usuario = session.query(User).filter(User.username == username).first()

    if usuario is None:
        raise credentials_exception

    return usuario

