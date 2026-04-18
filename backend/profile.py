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
    if not usuario_atual:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")

    usuario_atual.foto_perfil = dados.foto_url
    session.commit()

    return {
        "message": "Foto de perfil atualizada com sucesso"
    }

