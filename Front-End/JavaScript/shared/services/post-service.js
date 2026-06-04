import { apiFetch } from "../api.js";
import { formatarDataRelativa } from "../utils.js";
import { AVATAR_PLACEHOLDER } from "../config.js";

export function normalizarComentario(comentario) {
  return {
    id: comentario.id,
    texto: comentario.conteudo ?? comentario.texto ?? comentario.comentario ?? "",
    userId: comentario.usuario?.id ?? comentario.usuario_id ?? null,
    username: comentario.usuario?.username ?? comentario.username ?? "Usuario",
    foto: comentario.usuario?.foto_perfil ?? comentario.foto_perfil ?? AVATAR_PLACEHOLDER,
  };
}

export function normalizarPost(post) {
  return {
    id: post.id,
    userId: post.usuario?.id ?? post.usuario_id ?? null,
    nome: post.usuario?.username ?? "Usuario",
    usuario: `@${post.usuario?.username ?? "usuario"}`,
    texto: post.conteudo ?? post.texto ?? "",
    imagem: post.imagem ?? "",
    likes: Number(post.likes ?? 0),
    liked: Boolean(post.liked ?? false),
    foto: post.usuario?.foto_perfil ?? AVATAR_PLACEHOLDER,
    data: post.data_postagem ?? post.data ?? "",
    comentarios: Array.isArray(post.comentarios)
      ? post.comentarios.map(normalizarComentario)
      : [],
  };
}

export async function fetchFeed() {
  const data = await apiFetch("/post/feed", {
    auth: true,
    fallbackMessage: "Erro ao buscar posts.",
  });
  return Array.isArray(data) ? data.map(normalizarPost) : [];
}

export async function fetchPostById(postId) {
  const data = await apiFetch(`/post/${postId}`, {
    auth: true,
    fallbackMessage: "Não foi possível buscar o post.",
  });
  return normalizarPost(data);
}

export async function createPost(conteudo, imagem = null) {
  return apiFetch("/post/criar_post", {
    method: "POST",
    auth: true,
    body: { conteudo, imagem },
    fallbackMessage: "Erro ao publicar.",
  });
}

export async function likePost(postId) {
  return apiFetch(`/post/curtir/${postId}`, {
    method: "POST",
    auth: true,
    fallbackMessage: "Não foi possível curtir o post.",
  });
}

export async function unlikePost(postId) {
  return apiFetch(`/post/remover_curtida/${postId}`, {
    method: "DELETE",
    auth: true,
    fallbackMessage: "Não foi possível remover a curtida.",
  });
}

export async function updatePost(postId, conteudo, imagem = "") {
  return apiFetch(`/post/atualizar_post/${postId}`, {
    method: "PUT",
    auth: true,
    body: { conteudo, imagem },
    fallbackMessage: "Não foi possível editar o post.",
  });
}

export async function deletePost(postId) {
  return apiFetch(`/post/deletar/${postId}`, {
    method: "DELETE",
    auth: true,
    fallbackMessage: "Não foi possível excluir o post.",
  });
}

export { formatarDataRelativa };
