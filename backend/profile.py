from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from dependencies import pegar_sessao, pegar_usuario_atual
from models import User
from pydantic import BaseModel

class fotoUpdate(BaseModel):
    foto_url: str

profile_router = APIRouter(prefix="/profile", tags=["profile"])

@profile_router.post("/trocar_foto")
async def trocar_foto(dados: fotoUpdate,session: Session = Depends(pegar_sessao),usuario_atual = Depends(pegar_usuario_atual)
 ):
    if not dados.foto_url:
        raise HTTPException(status_code=400, detail="URL da foto inválida")
    

    usuario_atual.foto_perfil = dados.foto_url
    session.commit()
    session.refresh(usuario_atual)
    return {
        "message": "Foto de perfil atualizada com sucesso"
    }

