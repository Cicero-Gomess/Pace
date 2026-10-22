from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from dependencies import pegar_sessao, pegar_usuario_atual
from models import Comunidade, MembroComunidade, User
from schemas import (
    ComunidadeCreateSchema,
    ComunidadeResponseSchema,
    ComunidadeUpdateSchema,
    MembroComunidadeResponseSchema,
)


comunidades_router = APIRouter(prefix="/comunidades", tags=["comunidades"])


def _comunidade_response(
    comunidade: Comunidade,
    usuario_id: int,
    membros_count: int,
    sou_membro: bool,
) -> ComunidadeResponseSchema:
    return ComunidadeResponseSchema(
        id=comunidade.id,
        nome=comunidade.nome,
        descricao=comunidade.descricao,
        topicos=comunidade.topicos or [],
        privacidade=comunidade.privacidade,
        criador_id=comunidade.criador_id,
        data_criacao=comunidade.data_criacao,
        membros_count=membros_count,
        sou_membro=sou_membro,
        sou_criador=comunidade.criador_id == usuario_id,
    )


def _comunidade_por_id(
    session: Session,
    comunidade_id: int,
) -> Comunidade:
    comunidade = (
        session.query(Comunidade)
        .filter(Comunidade.id == comunidade_id, Comunidade.ativa.is_(True))
        .first()
    )
    if comunidade is None:
        raise HTTPException(status_code=404, detail="Comunidade não encontrada.")
    return comunidade


def _exigir_admin(
    session: Session,
    comunidade: Comunidade,
    usuario_id: int,
) -> None:
    if comunidade.criador_id == usuario_id:
        return
    membro = (
        session.query(MembroComunidade)
        .filter(
            MembroComunidade.comunidade_id == comunidade.id,
            MembroComunidade.usuario_id == usuario_id,
            MembroComunidade.cargo == "admin",
        )
        .first()
    )
    if membro is None:
        raise HTTPException(status_code=403, detail="Somente admins podem realizar esta ação.")


def _nome_duplicado(session: Session, nome: str, comunidade_id: int | None = None) -> bool:
    consulta = session.query(Comunidade.id).filter(
        func.lower(Comunidade.nome) == nome.casefold(),
        Comunidade.ativa.is_(True),
    )
    if comunidade_id is not None:
        consulta = consulta.filter(Comunidade.id != comunidade_id)
    return consulta.first() is not None


@comunidades_router.post("", response_model=ComunidadeResponseSchema, status_code=201)
def criar_comunidade(
    dados: ComunidadeCreateSchema,
    usuario: User = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    if _nome_duplicado(session, dados.nome):
        raise HTTPException(status_code=409, detail="Já existe uma comunidade com esse nome.")

    comunidade = Comunidade(
        nome=dados.nome,
        descricao=dados.descricao,
        topicos=dados.topicos,
        privacidade=dados.privacidade,
        criador_id=usuario.id,
    )
    session.add(comunidade)
    try:
        session.flush()
        session.add(
            MembroComunidade(
                comunidade_id=comunidade.id,
                usuario_id=usuario.id,
                cargo="admin",
            )
        )
        session.commit()
    except IntegrityError as erro:
        session.rollback()
        if _nome_duplicado(session, dados.nome):
            raise HTTPException(
                status_code=409,
                detail="Já existe uma comunidade com esse nome.",
            ) from erro
        raise

    session.refresh(comunidade)
    return _comunidade_response(comunidade, usuario.id, 1, True)


@comunidades_router.get("", response_model=list[ComunidadeResponseSchema])
def listar_comunidades(
    usuario: User = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    membros_count = (
        session.query(func.count(MembroComunidade.usuario_id))
        .filter(MembroComunidade.comunidade_id == Comunidade.id)
        .correlate(Comunidade)
        .scalar_subquery()
    )
    sou_membro = (
        session.query(MembroComunidade.usuario_id)
        .filter(
            MembroComunidade.comunidade_id == Comunidade.id,
            MembroComunidade.usuario_id == usuario.id,
        )
        .correlate(Comunidade)
        .exists()
    )
    comunidades = (
        session.query(Comunidade, membros_count, sou_membro)
        .filter(Comunidade.ativa.is_(True))
        .order_by(Comunidade.data_criacao.desc(), Comunidade.id.desc())
        .all()
    )
    return [
        _comunidade_response(comunidade, usuario.id, count, membership)
        for comunidade, count, membership in comunidades
    ]


@comunidades_router.get("/minhas", response_model=list[ComunidadeResponseSchema])
def listar_minhas_comunidades(
    usuario: User = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    membros_count = (
        session.query(func.count(MembroComunidade.usuario_id))
        .filter(MembroComunidade.comunidade_id == Comunidade.id)
        .correlate(Comunidade)
        .scalar_subquery()
    )
    comunidades = (
        session.query(Comunidade, membros_count)
        .join(
            MembroComunidade,
            MembroComunidade.comunidade_id == Comunidade.id,
        )
        .filter(
            MembroComunidade.usuario_id == usuario.id,
            Comunidade.ativa.is_(True),
        )
        .order_by(Comunidade.data_criacao.desc(), Comunidade.id.desc())
        .all()
    )
    return [
        _comunidade_response(comunidade, usuario.id, count, True)
        for comunidade, count in comunidades
    ]


@comunidades_router.get(
    "/{comunidade_id}",
    response_model=ComunidadeResponseSchema,
)
def obter_comunidade(
    comunidade_id: int,
    usuario: User = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    comunidade = _comunidade_por_id(session, comunidade_id)
    membros_count = (
        session.query(func.count(MembroComunidade.usuario_id))
        .filter(MembroComunidade.comunidade_id == comunidade.id)
        .scalar()
    )
    sou_membro = (
        session.query(MembroComunidade.usuario_id)
        .filter(
            MembroComunidade.comunidade_id == comunidade.id,
            MembroComunidade.usuario_id == usuario.id,
        )
        .first()
        is not None
    )
    return _comunidade_response(comunidade, usuario.id, membros_count, sou_membro)


@comunidades_router.post("/{comunidade_id}/participar")
def participar_comunidade(
    comunidade_id: int,
    usuario: User = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    comunidade = _comunidade_por_id(session, comunidade_id)
    membro = (
        session.query(MembroComunidade)
        .filter(
            MembroComunidade.comunidade_id == comunidade.id,
            MembroComunidade.usuario_id == usuario.id,
        )
        .first()
    )
    if membro is None:
        session.add(
            MembroComunidade(
                comunidade_id=comunidade.id,
                usuario_id=usuario.id,
                cargo="membro",
            )
        )
        session.commit()
    return {"message": "Você participa desta comunidade.", "participando": True}


@comunidades_router.delete("/{comunidade_id}/participar")
def sair_comunidade(
    comunidade_id: int,
    usuario: User = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    comunidade = _comunidade_por_id(session, comunidade_id)
    if comunidade.criador_id == usuario.id:
        raise HTTPException(
            status_code=403,
            detail="O criador não pode sair da própria comunidade.",
        )

    membro = (
        session.query(MembroComunidade)
        .filter(
            MembroComunidade.comunidade_id == comunidade.id,
            MembroComunidade.usuario_id == usuario.id,
        )
        .first()
    )
    if membro is None:
        raise HTTPException(status_code=404, detail="Você não participa desta comunidade.")

    session.delete(membro)
    session.commit()
    return {"message": "Você saiu da comunidade.", "participando": False}


@comunidades_router.put(
    "/{comunidade_id}",
    response_model=ComunidadeResponseSchema,
)
def atualizar_comunidade(
    comunidade_id: int,
    dados: ComunidadeUpdateSchema,
    usuario: User = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    comunidade = _comunidade_por_id(session, comunidade_id)
    _exigir_admin(session, comunidade, usuario.id)

    alteracoes = dados.model_dump(exclude_unset=True)
    if not alteracoes:
        raise HTTPException(status_code=422, detail="Informe ao menos um campo para atualizar.")
    if any(
        alteracoes.get(campo) is None
        for campo in ("nome", "topicos", "privacidade")
        if campo in alteracoes
    ):
        raise HTTPException(
            status_code=422,
            detail="Nome, tópicos e privacidade não podem ser nulos.",
        )
    if "nome" in alteracoes and _nome_duplicado(
        session,
        alteracoes["nome"],
        comunidade.id,
    ):
        raise HTTPException(status_code=409, detail="Já existe uma comunidade com esse nome.")

    for campo, valor in alteracoes.items():
        setattr(comunidade, campo, valor)
    session.commit()
    session.refresh(comunidade)

    membros_count = (
        session.query(func.count(MembroComunidade.usuario_id))
        .filter(MembroComunidade.comunidade_id == comunidade.id)
        .scalar()
    )
    return _comunidade_response(comunidade, usuario.id, membros_count, True)


@comunidades_router.get(
    "/{comunidade_id}/membros",
    response_model=list[MembroComunidadeResponseSchema],
)
def listar_membros(
    comunidade_id: int,
    usuario: User = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    comunidade = _comunidade_por_id(session, comunidade_id)
    _exigir_admin(session, comunidade, usuario.id)
    membros = (
        session.query(MembroComunidade, User)
        .join(User, User.id == MembroComunidade.usuario_id)
        .filter(MembroComunidade.comunidade_id == comunidade.id)
        .order_by(MembroComunidade.data_entrada.asc(), User.id.asc())
        .all()
    )
    return [
        MembroComunidadeResponseSchema(
            usuario_id=membro.usuario_id,
            username=membro_usuario.nome_usuario,
            foto_perfil=membro_usuario.foto_perfil,
            cargo=membro.cargo,
            data_entrada=membro.data_entrada,
        )
        for membro, membro_usuario in membros
    ]


@comunidades_router.delete("/{comunidade_id}/membros/{usuario_id}")
def remover_membro(
    comunidade_id: int,
    usuario_id: int,
    usuario: User = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    comunidade = _comunidade_por_id(session, comunidade_id)
    _exigir_admin(session, comunidade, usuario.id)
    if usuario_id == comunidade.criador_id:
        raise HTTPException(
            status_code=403,
            detail="O criador não pode ser removido da própria comunidade.",
        )

    membro = (
        session.query(MembroComunidade)
        .filter(
            MembroComunidade.comunidade_id == comunidade.id,
            MembroComunidade.usuario_id == usuario_id,
        )
        .first()
    )
    if membro is None:
        raise HTTPException(status_code=404, detail="Membro não encontrado.")
    session.delete(membro)
    session.commit()
    return {"message": "Membro removido da comunidade.", "usuario_id": usuario_id}


@comunidades_router.delete("/{comunidade_id}")
def excluir_comunidade(
    comunidade_id: int,
    usuario: User = Depends(pegar_usuario_atual),
    session: Session = Depends(pegar_sessao),
):
    comunidade = _comunidade_por_id(session, comunidade_id)
    _exigir_admin(session, comunidade, usuario.id)
    session.delete(comunidade)
    session.commit()
    return {"message": "Comunidade excluída.", "comunidade_id": comunidade_id}
