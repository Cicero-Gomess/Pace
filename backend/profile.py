from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from dependencies import pegar_sessao, pegar_usuario_atual

profile_router = APIRouter(prefix="/profile", tags=["profile"])

@profile_router.post("/trocar_foto")
async def trocar_foto(session: Session = Depends(pegar_sessao), usuario_atual = Depends(pegar_usuario_atual)):
    pass