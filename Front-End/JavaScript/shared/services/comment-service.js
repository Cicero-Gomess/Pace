import { apiFetch } from "../api.js";
import { normalizarComentario } from "./post-service.js";

export async function fetchComments(postId) {
  const data = await apiFetch(`/comments/comentarios/${postId}`, {
    auth: true,
    fallbackMessage: "Não foi possível buscar comentários.",
  });
  return Array.isArray(data) ? data.map(normalizarComentario) : [];
}

export async function createComment(postId, texto) {
  const data = await apiFetch(`/comments/adicionar_comentario/${postId}`, {
    method: "POST",
    auth: true,
    body: { conteudo: texto },
    fallbackMessage: "Não foi possível comentar.",
  });
  return normalizarComentario(data);
}

export async function updateComment(commentId, texto) {
  const data = await apiFetch(`/comments/atualizar_comentario/${commentId}`, {
    method: "PUT",
    auth: true,
    body: { conteudo: texto },
    fallbackMessage: "Não foi possível editar o comentário.",
  });
  return normalizarComentario(data);
}

export async function deleteComment(commentId) {
  return apiFetch(`/comments/deletar_comentario/${commentId}`, {
    method: "DELETE",
    auth: true,
    fallbackMessage: "Não foi possível excluir o comentário.",
  });
}
