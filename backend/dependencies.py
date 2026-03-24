from fastapi import Depends
from database import db
from sqlalchemy.orm import sessionmaker, Session    
from auth import oauth2_scheme

def pegar_sessao():
    try:
        Session = sessionmaker(bind=db)
        session = Session()
        yield session
    finally:
        session.close()

def pegar_usuario_atual(token: str = Depends(oauth2_scheme), session: Session = Depends(pegar_sessao)):
    # Aqui você pode implementar a lógica para decodificar o token e obter o usuário atual
    # Por exemplo, você pode usar JWT para decodificar o token e buscar o usuário no banco de dados
    pass