import { apiFetch } from "../api.js";

export function normalizarComunidade(comunidade) {
  if (!comunidade) return null;

  return {
    id: comunidade.id,
    nome: comunidade.nome ?? "Comunidade",
    descricao: comunidade.descricao ?? "",
    topicos: Array.isArray(comunidade.topicos) ? comunidade.topicos : [],
    privacidade: comunidade.privacidade ?? "publica",
    criadorId: comunidade.criador_id ?? null,
    dataCriacao: comunidade.data_criacao ?? null,
    membrosCount: Number(comunidade.membros_count ?? 0),
    souMembro: Boolean(comunidade.sou_membro ?? false),
    souCriador: Boolean(comunidade.sou_criador ?? false),
  };
}

export function normalizarMembroComunidade(membro) {
  return {
    usuarioId: membro.usuario_id ?? null,
    username: membro.username ?? "Usuario",
    fotoPerfil: membro.foto_perfil ?? null,
    cargo: membro.cargo ?? "membro",
    dataEntrada: membro.data_entrada ?? null,
  };
}

export async function fetchComunidades(termo = "", limit = 20) {
  const q = String(termo || "").trim();

  if (!q) {
    return [];
  }

  const params = new URLSearchParams({
    q,
    limit: String(limit),
  });

  const data = await apiFetch(
    `/comunidades?${params.toString()}`,
    {
      auth: true,
      fallbackMessage: "Erro ao buscar comunidades.",
    }
  );

  return Array.isArray(data)
    ? data.map(normalizarComunidade)
    : [];
}

export async function fetchMinhasComunidades() {
  const data = await apiFetch(
    "/comunidades/minhas",
    {
      auth: true,
      fallbackMessage: "Erro ao buscar suas comunidades.",
    }
  );

  return Array.isArray(data)
    ? data.map(normalizarComunidade)
    : [];
}

export async function fetchComunidadeById(comunidadeId) {
  if (comunidadeId === null || comunidadeId === undefined) {
    return null;
  }

  const data = await apiFetch(
    `/comunidades/${comunidadeId}`,
    {
      auth: true,
      fallbackMessage: "Erro ao buscar comunidade.",
    }
  );

  return normalizarComunidade(data);
}

export async function createComunidade({
  nome,
  descricao,
  topicos,
  privacidade = "publica",
}) {
  const data = await apiFetch(
    "/comunidades",
    {
      method: "POST",
      auth: true,
      body: { nome, descricao, topicos, privacidade },
      fallbackMessage: "Erro ao criar comunidade.",
    }
  );

  return normalizarComunidade(data);
}

export async function joinComunidade(comunidadeId) {
  return apiFetch(
    `/comunidades/${comunidadeId}/participar`,
    {
      method: "POST",
      auth: true,
      fallbackMessage: "Erro ao entrar na comunidade.",
    }
  );
}

export async function leaveComunidade(comunidadeId) {
  return apiFetch(
    `/comunidades/${comunidadeId}/participar`,
    {
      method: "DELETE",
      auth: true,
      fallbackMessage: "Erro ao sair da comunidade.",
    }
  );
}

export async function updateComunidade(comunidadeId, alteracoes) {
  const body = {};

  for (const campo of ["nome", "descricao", "topicos", "privacidade"]) {
    if (Object.prototype.hasOwnProperty.call(alteracoes, campo)) {
      body[campo] = alteracoes[campo];
    }
  }

  const data = await apiFetch(
    `/comunidades/${comunidadeId}`,
    {
      method: "PUT",
      auth: true,
      body,
      fallbackMessage: "Erro ao atualizar comunidade.",
    }
  );

  return normalizarComunidade(data);
}

export async function fetchMembrosComunidade(comunidadeId) {
  const data = await apiFetch(
    `/comunidades/${comunidadeId}/membros`,
    {
      auth: true,
      fallbackMessage: "Erro ao buscar membros da comunidade.",
    }
  );

  return Array.isArray(data)
    ? data.map(normalizarMembroComunidade)
    : [];
}

export async function removeMembroComunidade(comunidadeId, usuarioId) {
  return apiFetch(
    `/comunidades/${comunidadeId}/membros/${usuarioId}`,
    {
      method: "DELETE",
      auth: true,
      fallbackMessage: "Erro ao remover membro da comunidade.",
    }
  );
}

export async function deleteComunidade(comunidadeId) {
  return apiFetch(
    `/comunidades/${comunidadeId}`,
    {
      method: "DELETE",
      auth: true,
      fallbackMessage: "Erro ao excluir comunidade.",
    }
  );
}