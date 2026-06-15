import { initAppShell } from "./shared/app-shell.js";
import {
  getCurrentUser,
  saveCurrentUser,
  handleAuthError,
} from "./shared/auth.js";
import { showToast, updateSidebarPhoto, initLucide } from "./shared/ui.js";
import { escaparHTML } from "./shared/utils.js";
import {
  fetchCurrentProfile,
  fetchFollowing,
  followUser,
  unfollowUser,
} from "./shared/services/profile-service.js";
import {
  fetchFeed,
  fetchPostById,
  likePost,
  unlikePost,
  updatePost,
  deletePost,
  formatarDataRelativa,
} from "./shared/services/post-service.js";
import {
  fetchComments,
  createComment,
  updateComment,
  deleteComment,
} from "./shared/services/comment-service.js";
import { AVATAR_PLACEHOLDER } from "./shared/config.js";

const shellOk = await initAppShell();

if (shellOk) {
  let usuario = getCurrentUser() || {};
  let postsCarregados = [];
  let seguindoIds = new Set();

  let postEmEdicao = null;
  let postParaExcluir = null;
  let comentarioParaExcluir = null;
  let comentarioEmEdicao = null;

  const feedEl = document.getElementById("feed");
  const confirmDeleteModal = document.getElementById("confirmDeleteModal");
  const cancelDeleteBtn = document.getElementById("cancelDelete");
  const confirmDeleteBtn = document.getElementById("confirmDelete");
  const confirmDeleteCommentModal = document.getElementById("confirmDeleteCommentModal");
  const cancelDeleteCommentBtn = document.getElementById("cancelDeleteComment");
  const confirmDeleteCommentBtn = document.getElementById("confirmDeleteComment");
  const modalEditarPost = document.getElementById("modalEditarPost");
  const editPostTexto = document.getElementById("editPostTexto");
  const fecharEditarPost = document.getElementById("fecharEditarPost");
  const cancelarEditarPost = document.getElementById("cancelarEditarPost");
  const salvarEditarPost = document.getElementById("salvarEditarPost");
  const editCommentModal = document.getElementById("editCommentModal");
  const editCommentInput = document.getElementById("editCommentInput");
  const cancelEditCommentBtn = document.getElementById("cancelEditComment");
  const confirmEditCommentBtn = document.getElementById("confirmEditComment");

  function encontrarPost(postId) {
    return postsCarregados.find((post) => post.id === postId);
  }

  function abrirModal(el) {
    el?.classList.remove("hidden");
  }

  function fecharModal(el) {
    el?.classList.add("hidden");
  }

  function atualizarPostNaLista(postAtualizado) {
    postsCarregados = postsCarregados.map((post) =>
      post.id === postAtualizado.id ? { ...post, ...postAtualizado } : post
    );
  }

  function renderEmptyFeed() {
    feedEl.innerHTML = `
      <div class="empty-feed">
        <div class="empty-icon"><i data-lucide="sparkles"></i></div>
        <h3>Nenhum post por enquanto</h3>
        <p>Quando a comunidade começar a publicar, tudo vai aparecer aqui.</p>
        <a href="postar.html" class="empty-btn">
          <i data-lucide="square-pen"></i><span>Criar post</span>
        </a>
      </div>
    `;
    initLucide();
  }

  function criarComentarioHTML(post, comentario) {
    const ehDono = comentario.userId === usuario.id;

    return `
      <div class="comentario" data-comment-id="${comentario.id}">
        <img class="comentario-avatar" src="${escaparHTML(comentario.foto || AVATAR_PLACEHOLDER)}" alt="">
        <div class="comentario-bloco">
          <div class="comentario-conteudo">
            <div class="comentario-topo">
              <strong class="comentario-nome">${escaparHTML(comentario.username)}</strong>
              ${
                ehDono
                  ? `<div class="comentario-acoes">
                      <button class="btn-icon" type="button" data-action="abrir-editar-comentario" data-post-id="${post.id}" data-comment-id="${comentario.id}">
                        <i data-lucide="pencil"></i>
                      </button>
                      <button class="btn-icon" type="button" data-action="abrir-excluir-comentario" data-post-id="${post.id}" data-comment-id="${comentario.id}">
                        <i data-lucide="trash-2"></i>
                      </button>
                    </div>`
                  : ""
              }
            </div>
            <span class="comentario-texto">${escaparHTML(comentario.texto)}</span>
          </div>
        </div>
      </div>
    `;
  }

  function criarBotaoSeguir(post) {
    const seguindo = seguindoIds.has(post.userId) || post.seguindo;

    return `
      <button
        class="btn-seguir-post ${seguindo ? "seguindo" : ""}"
        type="button"
        data-action="toggle-follow"
        data-user-id="${post.userId}"
      >
        ${seguindo ? "Seguindo" : "Seguir"}
      </button>
    `;
  }

  function criarPostHTML(post) {
    const ehMeuPost = post.userId === usuario.id;

    return `
      <article class="card" data-post-id="${post.id}">
        <div class="post-topo">
          <img class="avatar" src="${escaparHTML(post.foto || AVATAR_PLACEHOLDER)}" alt="">
          <div class="info">
            <strong>${escaparHTML(post.nome)}</strong>
            <span>${escaparHTML(post.usuario)}${post.data ? ` • ${escaparHTML(formatarDataRelativa(post.data))}` : ""}</span>
          </div>
          ${
            ehMeuPost
              ? `<div class="post-topo-acoes">
                  <button class="btn-icon" type="button" data-action="abrir-editar-post" data-post-id="${post.id}">
                    <i data-lucide="pencil"></i>
                  </button>
                  <button class="btn-icon" type="button" data-action="abrir-excluir-post" data-post-id="${post.id}">
                    <i data-lucide="trash-2"></i>
                  </button>
                </div>`
              : criarBotaoSeguir(post)
          }
        </div>

        ${post.texto ? `<p class="post-texto">${escaparHTML(post.texto)}</p>` : ""}
        ${post.imagem ? `<div class="post-img-wrap"><img class="post-img" src="${escaparHTML(post.imagem)}" alt=""></div>` : ""}

        <div class="post-acoes">
          <button class="like ${post.liked ? "liked" : ""}" type="button" data-action="toggle-like" data-post-id="${post.id}">
            <i data-lucide="heart"></i><span>${post.likes}</span>
          </button>
          <div class="comment-badge">
            <i data-lucide="message-circle"></i><span>${post.comentarios.length}</span>
          </div>
        </div>

        <div class="comentarios">
          ${post.comentarios.map((c) => criarComentarioHTML(post, c)).join("")}
        </div>

        <div class="add-comentario">
          <input class="input-comentario" type="text" placeholder="Compartilhe algo..." data-role="comment-input" data-post-id="${post.id}">
          <button class="btn-comentar" type="button" data-action="criar-comentario" data-post-id="${post.id}">
            <i data-lucide="send"></i>
          </button>
        </div>
      </article>
    `;
  }

  function renderFeed() {
    if (!postsCarregados.length) {
      renderEmptyFeed();
      return;
    }

    feedEl.innerHTML = postsCarregados.map(criarPostHTML).join("");
    initLucide();
  }

  async function alternarFollow(userId, button) {
    if (!userId || !button || button.disabled || userId === usuario.id) return;

    const jaSegue = seguindoIds.has(userId);
    button.disabled = true;

    try {
      if (jaSegue) {
        await unfollowUser(userId);
        seguindoIds.delete(userId);
      } else {
        await followUser(userId);
        seguindoIds.add(userId);
      }

      postsCarregados = postsCarregados.map((post) =>
        post.userId === userId ? { ...post, seguindo: seguindoIds.has(userId) } : post
      );

      renderFeed();
    } catch (error) {
      if (!handleAuthError(error, showToast)) {
        showToast(error.message || "Erro ao atualizar seguimento.", "error");
      }
    } finally {
      button.disabled = false;
    }
  }

  async function alternarLike(postId, likeButton) {
    const post = encontrarPost(postId);
    if (!post || !likeButton || likeButton.disabled) return;

    const curtidoAntes = post.liked;
    const likesAntes = post.likes;
    const contador = likeButton.querySelector("span");

    likeButton.disabled = true;
    post.liked = !post.liked;
    post.likes = post.liked ? post.likes + 1 : Math.max(0, post.likes - 1);

    likeButton.classList.toggle("liked", post.liked);
    if (contador) contador.textContent = String(post.likes);

    try {
      if (curtidoAntes) await unlikePost(postId);
      else await likePost(postId);

      const atualizado = await fetchPostById(postId);

      atualizarPostNaLista({
        id: postId,
        liked: atualizado.liked,
        likes: atualizado.likes,
      });

      likeButton.classList.toggle("liked", atualizado.liked);
      if (contador) contador.textContent = String(atualizado.likes);
    } catch (error) {
      post.liked = curtidoAntes;
      post.likes = likesAntes;

      likeButton.classList.toggle("liked", post.liked);
      if (contador) contador.textContent = String(post.likes);

      if (!handleAuthError(error, showToast)) {
        showToast(error.message || "Erro ao curtir post.", "error");
      }
    } finally {
      likeButton.disabled = false;
    }
  }

  async function criarComentarioNoPost(postId, input) {
    const texto = input.value.trim();

    if (!texto) {
      showToast("Escreva um comentário antes de enviar.", "error");
      return;
    }

    const post = encontrarPost(postId);
    if (!post) return;

    input.disabled = true;

    try {
      const comentario = await createComment(postId, texto);

      post.comentarios.push(comentario);
      input.value = "";

      renderFeed();
      showToast("Comentário publicado!", "success");
    } catch (error) {
      if (!handleAuthError(error, showToast)) {
        showToast(error.message || "Erro ao comentar.", "error");
      }
    } finally {
      input.disabled = false;
    }
  }

  async function salvarEdicaoComentario() {
    if (!comentarioEmEdicao) return;

    const novoTexto = editCommentInput.value.trim();

    if (!novoTexto) {
      showToast("O comentário não pode ficar vazio.", "error");
      return;
    }

    const { postId, commentId } = comentarioEmEdicao;
    const post = encontrarPost(postId);

    if (!post) return;

    confirmEditCommentBtn.disabled = true;

    try {
      const atualizado = await updateComment(commentId, novoTexto);

      post.comentarios = post.comentarios.map((c) =>
        c.id === commentId ? { ...c, ...atualizado } : c
      );

      comentarioEmEdicao = null;
      editCommentInput.value = "";

      fecharModal(editCommentModal);
      renderFeed();
      showToast("Comentário atualizado!", "success");
    } catch (error) {
      if (!handleAuthError(error, showToast)) {
        showToast(error.message || "Erro ao editar comentário.", "error");
      }
    } finally {
      confirmEditCommentBtn.disabled = false;
    }
  }

  async function excluirComentarioConfirmado() {
    if (!comentarioParaExcluir) return;

    const { postId, commentId } = comentarioParaExcluir;
    const post = encontrarPost(postId);

    if (!post) return;

    confirmDeleteCommentBtn.disabled = true;

    try {
      await deleteComment(commentId);

      post.comentarios = post.comentarios.filter((c) => c.id !== commentId);
      comentarioParaExcluir = null;

      fecharModal(confirmDeleteCommentModal);
      renderFeed();
      showToast("Comentário excluído!", "success");
    } catch (error) {
      if (!handleAuthError(error, showToast)) {
        showToast(error.message || "Erro ao excluir comentário.", "error");
      }
    } finally {
      confirmDeleteCommentBtn.disabled = false;
    }
  }

  async function salvarEdicaoPost() {
    if (!postEmEdicao) return;

    const novoTexto = editPostTexto.value.trim();

    if (!novoTexto) {
      showToast("O texto do post não pode ficar vazio.", "error");
      return;
    }

    salvarEditarPost.disabled = true;

    try {
      const resposta = await updatePost(
        postEmEdicao.id,
        novoTexto,
        postEmEdicao.imagem || ""
      );

      postEmEdicao.texto = resposta.conteudo ?? novoTexto;
      postEmEdicao = null;
      editPostTexto.value = "";

      fecharModal(modalEditarPost);
      renderFeed();
      showToast("Post atualizado!", "success");
    } catch (error) {
      if (!handleAuthError(error, showToast)) {
        showToast(error.message || "Erro ao editar post.", "error");
      }
    } finally {
      salvarEditarPost.disabled = false;
    }
  }

  async function excluirPostConfirmado() {
    if (!postParaExcluir) return;

    confirmDeleteBtn.disabled = true;

    try {
      await deletePost(postParaExcluir.id);

      postsCarregados = postsCarregados.filter((p) => p.id !== postParaExcluir.id);
      postParaExcluir = null;

      fecharModal(confirmDeleteModal);
      renderFeed();
      showToast("Post excluído!", "success");
    } catch (error) {
      if (!handleAuthError(error, showToast)) {
        showToast(error.message || "Erro ao excluir post.", "error");
      }
    } finally {
      confirmDeleteBtn.disabled = false;
    }
  }

  feedEl?.addEventListener("click", async (event) => {
    const button = event.target.closest("button");
    if (!button) return;

    const action = button.dataset.action;
    const postId = Number(button.dataset.postId);
    const commentId = Number(button.dataset.commentId);
    const userId = Number(button.dataset.userId);

    if (action === "toggle-follow") return alternarFollow(userId, button);
    if (action === "toggle-like") return alternarLike(postId, button);

    if (action === "criar-comentario") {
      const input = feedEl.querySelector(
        `[data-role="comment-input"][data-post-id="${postId}"]`
      );

      if (input) await criarComentarioNoPost(postId, input);
      return;
    }

    if (action === "abrir-editar-post") {
      const post = encontrarPost(postId);
      if (!post) return;

      postEmEdicao = post;
      editPostTexto.value = post.texto || "";
      abrirModal(modalEditarPost);
      return;
    }

    if (action === "abrir-excluir-post") {
      postParaExcluir = encontrarPost(postId);
      abrirModal(confirmDeleteModal);
      return;
    }

    if (action === "abrir-editar-comentario") {
      comentarioEmEdicao = { postId, commentId };

      const post = encontrarPost(postId);
      const comentario = post?.comentarios.find((c) => c.id === commentId);

      editCommentInput.value = comentario?.texto || "";
      abrirModal(editCommentModal);
      return;
    }

    if (action === "abrir-excluir-comentario") {
      comentarioParaExcluir = { postId, commentId };
      abrirModal(confirmDeleteCommentModal);
    }
  });

  feedEl?.addEventListener("keydown", async (event) => {
    const input = event.target.closest('[data-role="comment-input"]');

    if (input && event.key === "Enter") {
      event.preventDefault();
      await criarComentarioNoPost(Number(input.dataset.postId), input);
    }
  });

  cancelDeleteBtn?.addEventListener("click", () => {
    postParaExcluir = null;
    fecharModal(confirmDeleteModal);
  });

  confirmDeleteBtn?.addEventListener("click", excluirPostConfirmado);

  cancelDeleteCommentBtn?.addEventListener("click", () => {
    comentarioParaExcluir = null;
    fecharModal(confirmDeleteCommentModal);
  });

  confirmDeleteCommentBtn?.addEventListener("click", excluirComentarioConfirmado);

  fecharEditarPost?.addEventListener("click", () => {
    postEmEdicao = null;
    fecharModal(modalEditarPost);
  });

  cancelarEditarPost?.addEventListener("click", () => {
    postEmEdicao = null;
    fecharModal(modalEditarPost);
  });

  salvarEditarPost?.addEventListener("click", salvarEdicaoPost);

  cancelEditCommentBtn?.addEventListener("click", () => {
    comentarioEmEdicao = null;
    fecharModal(editCommentModal);
  });

  confirmEditCommentBtn?.addEventListener("click", salvarEdicaoComentario);

  async function initFeed() {
    try {
      const userAPI = await fetchCurrentProfile();

      usuario = { ...usuario, ...userAPI };
      saveCurrentUser(usuario);
      updateSidebarPhoto(usuario);

      try {
        const seguindoResposta = await fetchFollowing(usuario.id);
        seguindoIds = new Set((seguindoResposta?.usuarios || []).map((u) => u.id));
      } catch (error) {
        seguindoIds = new Set();
      }

      postsCarregados = (await fetchFeed()).map((post) => ({
        ...post,
        seguindo: seguindoIds.has(post.userId),
      }));

      postsCarregados = await Promise.all(
        postsCarregados.map(async (post) => {
          try {
            const comentarios = await fetchComments(post.id);
            return { ...post, comentarios };
          } catch (error) {
            if (handleAuthError(error, showToast)) throw error;
            return { ...post, comentarios: [] };
          }
        })
      );

      renderFeed();
    } catch (error) {
      if (!handleAuthError(error, showToast)) {
        showToast(error.message || "Não foi possível carregar o feed.", "error");
        renderEmptyFeed();
      }
    }
  }

  initFeed();
}