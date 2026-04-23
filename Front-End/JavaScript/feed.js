/* ===== CONFIG ===== */
const API_URL = "http://127.0.0.1:8000";

/* ===== DARK MODE ===== */
if (localStorage.getItem("darkMode") === "true") {
  document.body.classList.add("dark");
}

lucide.createIcons();

/* ===== AUTH ===== */
let usuario = JSON.parse(localStorage.getItem("usuarioLogado"));

if (!usuario) {
  window.location.href = "login.html";
}

/* ===== ELEMENTOS ===== */
const feedEl = document.getElementById("feed");
const fotoSidebarEl = document.getElementById("fotoSidebar");

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

/* ===== ESTADO ===== */
let postsCarregados = [];
let postEmEdicao = null;
let postParaExcluir = null;
let comentarioParaExcluir = null;
let comentarioEmEdicao = null;

/* ===== TOAST ===== */
function garantirToast() {
  let toast = document.getElementById("toast");

  if (!toast) {
    toast = document.createElement("div");
    toast.id = "toast";
    toast.className = "toast hidden";
    document.body.appendChild(toast);
  }

  return toast;
}

function mostrarToast(mensagem, tipo = "success") {
  const toast = garantirToast();

  toast.textContent = mensagem;
  toast.className = `toast ${tipo}`;
  toast.classList.remove("hidden");

  requestAnimationFrame(() => {
    toast.classList.add("show");
  });

  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => {
    toast.classList.remove("show");

    setTimeout(() => {
      toast.className = "toast hidden";
    }, 250);
  }, 2600);
}

/* ===== HELPERS ===== */
function getToken() {
  return localStorage.getItem("token");
}

function limparSessaoERedirecionar() {
  localStorage.removeItem("token");
  localStorage.removeItem("usuarioLogado");
  window.location.href = "login.html";
}

async function parseResponse(response, fallbackMessage) {
  const contentType = response.headers.get("content-type") || "";
  let data = null;

  if (contentType.includes("application/json")) {
    try {
      data = await response.json();
    } catch {
      data = null;
    }
  } else {
    try {
      const text = await response.text();
      data = text ? { detail: text } : null;
    } catch {
      data = null;
    }
  }

  if (!response.ok) {
    const mensagem = data?.detail || fallbackMessage;

    if (response.status === 401) {
      throw new Error("AUTH_401");
    }

    throw new Error(mensagem);
  }

  return data;
}

function formatarData(dataISO) {
  if (!dataISO) return "";

  const data = new Date(dataISO);
  if (Number.isNaN(data.getTime())) return "";

  return data.toLocaleDateString("pt-BR", {
    day: "2-digit",
    month: "short",
    year: "numeric"
  });
}

function escaparHTML(valor) {
  return String(valor ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function atualizarFotoSidebar() {
  if (!fotoSidebarEl || !usuario) return;

  fotoSidebarEl.src =
    usuario.foto_perfil ||
    usuario.foto ||
    "../Images/image.person.png";
}

function normalizarComentario(comentario) {
  return {
    id: comentario.id,
    texto: comentario.conteudo ?? comentario.texto ?? comentario.comentario ?? "",
    userId: comentario.usuario?.id ?? comentario.usuario_id ?? null,
    username: comentario.usuario?.username ?? comentario.username ?? "Usuario",
    foto: comentario.usuario?.foto_perfil ?? comentario.foto_perfil ?? "../Images/image.person.png"
  };
}

function normalizarPost(post) {
  return {
    id: post.id,
    userId: post.usuario?.id ?? post.usuario_id ?? null,
    nome: post.usuario?.username ?? "Usuario",
    usuario: `@${post.usuario?.username ?? "usuario"}`,
    texto: post.conteudo ?? post.texto ?? "",
    imagem: post.imagem ?? "",
    likes: Number(post.likes ?? 0),
    liked: Boolean(post.liked ?? false),
    foto: post.usuario?.foto_perfil ?? "../Images/image.person.png",
    data: post.data_postagem ?? post.data ?? "",
    comentarios: Array.isArray(post.comentarios)
      ? post.comentarios.map(normalizarComentario)
      : []
  };
}

function encontrarPost(postId) {
  return postsCarregados.find((post) => post.id === postId);
}

function abrirModal(el) {
  if (!el) return;
  el.classList.remove("hidden");
}

function fecharModal(el) {
  if (!el) return;
  el.classList.add("hidden");
}

function atualizarPostNaLista(postAtualizado) {
  postsCarregados = postsCarregados.map((post) =>
    post.id === postAtualizado.id ? { ...post, ...postAtualizado } : post
  );
}

/* ===== API ===== */
async function buscarUsuarioAPI() {
  const response = await fetch(`${API_URL}/profile/me`, {
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  return parseResponse(response, "Erro ao buscar usuario.");
}

async function getPostsAPI() {
  const response = await fetch(`${API_URL}/post/feed`, {
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  const data = await parseResponse(response, "Erro ao buscar posts.");
  return Array.isArray(data) ? data.map(normalizarPost) : [];
}

async function buscarPostPorIdAPI(postId) {
  const response = await fetch(`${API_URL}/post/${postId}`, {
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  const data = await parseResponse(response, "Nao foi possivel buscar o post.");
  return normalizarPost(data);
}

async function buscarComentariosAPI(postId) {
  const response = await fetch(`${API_URL}/comments/comentarios/${postId}`, {
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  const data = await parseResponse(response, "Nao foi possivel buscar comentarios.");
  return Array.isArray(data) ? data.map(normalizarComentario) : [];
}

async function curtirPostAPI(postId) {
  const response = await fetch(`${API_URL}/post/curtir/${postId}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  return parseResponse(response, "Nao foi possivel curtir o post.");
}

async function removerCurtidaAPI(postId) {
  const response = await fetch(`${API_URL}/post/remover_curtida/${postId}`, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  return parseResponse(response, "Nao foi possivel remover a curtida.");
}

async function editarPostAPI(postId, novoTexto, imagemAtual = "") {
  const response = await fetch(`${API_URL}/post/atualizar_post/${postId}`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${getToken()}`
    },
    body: JSON.stringify({
      conteudo: novoTexto,
      imagem: imagemAtual
    })
  });

  return parseResponse(response, "Nao foi possivel editar o post.");
}

async function excluirPostAPI(postId) {
  const response = await fetch(`${API_URL}/post/deletar/${postId}`, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  return parseResponse(response, "Nao foi possivel excluir o post.");
}

async function criarComentarioAPI(postId, texto) {
  const response = await fetch(`${API_URL}/comments/adicionar_comentario/${postId}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${getToken()}`
    },
    body: JSON.stringify({
      conteudo: texto
    })
  });

  const data = await parseResponse(response, "Nao foi possivel comentar.");
  return normalizarComentario(data);
}

async function editarComentarioAPI(commentId, texto) {
  const response = await fetch(`${API_URL}/comments/atualizar_comentario/${commentId}`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${getToken()}`
    },
    body: JSON.stringify({
      conteudo: texto
    })
  });

  const data = await parseResponse(response, "Nao foi possivel editar o comentario.");
  return normalizarComentario(data);
}

async function excluirComentarioAPI(commentId) {
  const response = await fetch(`${API_URL}/comments/deletar_comentario/${commentId}`, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  return parseResponse(response, "Nao foi possivel excluir o comentario.");
}

/* ===== EMPTY ===== */
function renderEmptyFeed() {
  feedEl.innerHTML = `
    <div class="empty-feed">
      <div class="empty-icon">
        <i data-lucide="sparkles"></i>
      </div>
      <h3>Nenhum post por enquanto</h3>
      <p>
        Quando a comunidade começar a publicar, tudo vai aparecer aqui.
        Se quiser abrir os trabalhos, crie o primeiro post agora.
      </p>
      <a href="postar.html" class="empty-btn">
        <i data-lucide="square-pen"></i>
        <span>Criar post</span>
      </a>
    </div>
  `;

  lucide.createIcons();
}

/* ===== TEMPLATE ===== */
function criarComentarioHTML(post, comentario) {
  const ehDono = comentario.userId === usuario.id;

  return `
    <div class="comentario" data-comment-id="${comentario.id}">
      <img
        class="comentario-avatar"
        src="${escaparHTML(comentario.foto || "../Images/image.person.png")}"
        alt="Foto de ${escaparHTML(comentario.username)}"
      >

      <div class="comentario-bloco">
        <div class="comentario-conteudo">
          <div class="comentario-topo">
            <strong class="comentario-nome">${escaparHTML(comentario.username)}</strong>

            ${
              ehDono
                ? `
                  <div class="comentario-acoes">
                    <button
                      class="btn-icon btn-editar-comentario"
                      type="button"
                      data-action="abrir-editar-comentario"
                      data-post-id="${post.id}"
                      data-comment-id="${comentario.id}"
                      title="Editar comentario"
                    >
                      <i data-lucide="pencil"></i>
                    </button>

                    <button
                      class="btn-icon btn-excluir-comentario"
                      type="button"
                      data-action="abrir-excluir-comentario"
                      data-post-id="${post.id}"
                      data-comment-id="${comentario.id}"
                      title="Excluir comentario"
                    >
                      <i data-lucide="trash-2"></i>
                    </button>
                  </div>
                `
                : ""
            }
          </div>

          <span class="comentario-texto">${escaparHTML(comentario.texto)}</span>
        </div>
      </div>
    </div>
  `;
}

function criarPostHTML(post) {
  const ehMeuPost = post.userId === usuario.id;

  return `
    <article class="card" data-post-id="${post.id}">
      <div class="post-topo">
        <img class="avatar" src="${escaparHTML(post.foto)}" alt="Foto de ${escaparHTML(post.nome)}">

        <div class="info">
          <strong>${escaparHTML(post.nome)}</strong>
          <span>${escaparHTML(post.usuario)}${post.data ? ` • ${escaparHTML(formatarData(post.data))}` : ""}</span>
        </div>

        ${
          ehMeuPost
            ? `
              <div class="post-topo-acoes">
                <button
                  class="btn-icon btn-editar-post"
                  type="button"
                  data-action="abrir-editar-post"
                  data-post-id="${post.id}"
                  title="Editar post"
                >
                  <i data-lucide="pencil"></i>
                </button>

                <button
                  class="btn-icon btn-excluir"
                  type="button"
                  data-action="abrir-excluir-post"
                  data-post-id="${post.id}"
                  title="Excluir post"
                >
                  <i data-lucide="trash-2"></i>
                </button>
              </div>
            `
            : ""
        }
      </div>

      ${post.texto ? `<p class="post-texto">${escaparHTML(post.texto)}</p>` : ""}

      ${
        post.imagem
          ? `
            <div class="post-img-wrap">
              <img class="post-img" src="${escaparHTML(post.imagem)}" alt="Imagem do post">
            </div>
          `
          : ""
      }

      <div class="post-acoes">
        <button
          class="like ${post.liked ? "liked" : ""}"
          type="button"
          data-action="toggle-like"
          data-post-id="${post.id}"
          aria-pressed="${post.liked ? "true" : "false"}"
          title="${post.liked ? "Descurtir" : "Curtir"}"
        >
          <i data-lucide="heart"></i>
          <span>${post.likes}</span>
        </button>

        <div class="comment-badge" title="Comentarios">
          <i data-lucide="message-circle"></i>
          <span>${post.comentarios.length}</span>
        </div>
      </div>

      <div class="comentarios">
        ${post.comentarios.map((comentario) => criarComentarioHTML(post, comentario)).join("")}
      </div>

      <div class="add-comentario">
        <input
          class="input-comentario"
          type="text"
          placeholder="Compartilhe algo..."
          data-role="comment-input"
          data-post-id="${post.id}"
        >

        <button
          class="btn-comentar"
          type="button"
          data-action="criar-comentario"
          data-post-id="${post.id}"
          title="Enviar comentario"
        >
          <i data-lucide="send"></i>
        </button>
      </div>
    </article>
  `;
}

/* ===== RENDER ===== */
function renderFeed() {
  if (!feedEl) return;

  if (!postsCarregados.length) {
    renderEmptyFeed();
    return;
  }

  feedEl.innerHTML = postsCarregados.map(criarPostHTML).join("");
  lucide.createIcons();
}

/* ===== LIKE ===== */
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
  likeButton.setAttribute("aria-pressed", String(post.liked));
  likeButton.title = post.liked ? "Descurtir" : "Curtir";

  if (contador) {
    contador.textContent = String(post.likes);
  }

  likeButton.classList.remove("like-bump");
  void likeButton.offsetWidth;
  likeButton.classList.add("like-bump");

  try {
    if (curtidoAntes) {
      await removerCurtidaAPI(postId);
    } else {
      await curtirPostAPI(postId);
    }

    const postAtualizado = await buscarPostPorIdAPI(postId);

    atualizarPostNaLista({
      id: postId,
      liked: postAtualizado.liked,
      likes: postAtualizado.likes
    });

    likeButton.classList.toggle("liked", postAtualizado.liked);
    likeButton.setAttribute("aria-pressed", String(postAtualizado.liked));
    likeButton.title = postAtualizado.liked ? "Descurtir" : "Curtir";

    if (contador) {
      contador.textContent = String(postAtualizado.likes);
    }
  } catch (error) {
    post.liked = curtidoAntes;
    post.likes = likesAntes;

    likeButton.classList.toggle("liked", post.liked);
    likeButton.setAttribute("aria-pressed", String(post.liked));
    likeButton.title = post.liked ? "Descurtir" : "Curtir";

    if (contador) {
      contador.textContent = String(post.likes);
    }

    if (error.message === "AUTH_401") {
      mostrarToast("Sessao expirada. Faca login novamente.", "error");
      setTimeout(limparSessaoERedirecionar, 1000);
      return;
    }

    mostrarToast(error.message || "Erro ao curtir post.", "error");
  } finally {
    likeButton.disabled = false;
  }
}

/* ===== COMENTARIOS ===== */
async function criarComentario(postId, input) {
  const texto = input.value.trim();

  if (!texto) {
    mostrarToast("Escreva um comentario antes de enviar.", "error");
    return;
  }

  const post = encontrarPost(postId);
  if (!post) return;

  const textoOriginal = input.value;
  const botao = feedEl.querySelector(`button[data-action="criar-comentario"][data-post-id="${postId}"]`);

  input.disabled = true;
  if (botao) botao.disabled = true;

  try {
    const comentarioCriado = await criarComentarioAPI(postId, texto);
    post.comentarios.push(comentarioCriado);
    input.value = "";
    renderFeed();
    mostrarToast("Comentario publicado com sucesso!", "success");
  } catch (error) {
    input.value = textoOriginal;

    if (error.message === "AUTH_401") {
      mostrarToast("Sessao expirada. Faca login novamente.", "error");
      setTimeout(limparSessaoERedirecionar, 1000);
      return;
    }

    mostrarToast(error.message || "Erro ao comentar.", "error");
  } finally {
    input.disabled = false;
    if (botao) botao.disabled = false;
  }
}

function abrirModalEditarComentario(postId, commentId) {
  comentarioEmEdicao = { postId, commentId };

  const post = encontrarPost(postId);
  const comentario = post?.comentarios.find((item) => item.id === commentId);

  if (!comentario) return;

  editCommentInput.value = comentario.texto || "";
  abrirModal(editCommentModal);

  setTimeout(() => {
    editCommentInput.focus();
    editCommentInput.setSelectionRange(editCommentInput.value.length, editCommentInput.value.length);
  }, 30);
}

function fecharModalEditarComentario() {
  comentarioEmEdicao = null;
  editCommentInput.value = "";
  fecharModal(editCommentModal);
}

async function salvarEdicaoComentario() {
  if (!comentarioEmEdicao) return;

  const novoTexto = editCommentInput.value.trim();
  if (!novoTexto) {
    mostrarToast("O comentario nao pode ficar vazio.", "error");
    return;
  }

  const { postId, commentId } = comentarioEmEdicao;
  const post = encontrarPost(postId);
  if (!post) return;

  confirmEditCommentBtn.disabled = true;

  try {
    const comentarioAtualizado = await editarComentarioAPI(commentId, novoTexto);

    post.comentarios = post.comentarios.map((comentario) =>
      comentario.id === commentId ? { ...comentario, ...comentarioAtualizado } : comentario
    );

    fecharModalEditarComentario();
    renderFeed();
    mostrarToast("Comentario atualizado com sucesso!", "success");
  } catch (error) {
    if (error.message === "AUTH_401") {
      mostrarToast("Sessao expirada. Faca login novamente.", "error");
      setTimeout(limparSessaoERedirecionar, 1000);
      return;
    }

    mostrarToast(error.message || "Erro ao editar comentario.", "error");
  } finally {
    confirmEditCommentBtn.disabled = false;
  }
}

function abrirModalExcluirComentario(postId, commentId) {
  comentarioParaExcluir = { postId, commentId };
  abrirModal(confirmDeleteCommentModal);
}

function fecharModalExcluirComentario() {
  comentarioParaExcluir = null;
  fecharModal(confirmDeleteCommentModal);
}

async function excluirComentarioConfirmado() {
  if (!comentarioParaExcluir) return;

  const { postId, commentId } = comentarioParaExcluir;
  const post = encontrarPost(postId);
  if (!post) return;

  confirmDeleteCommentBtn.disabled = true;

  try {
    await excluirComentarioAPI(commentId);
    post.comentarios = post.comentarios.filter((comentario) => comentario.id !== commentId);
    fecharModalExcluirComentario();
    renderFeed();
    mostrarToast("Comentario excluido com sucesso!", "success");
  } catch (error) {
    if (error.message === "AUTH_401") {
      mostrarToast("Sessao expirada. Faca login novamente.", "error");
      setTimeout(limparSessaoERedirecionar, 1000);
      return;
    }

    mostrarToast(error.message || "Erro ao excluir comentario.", "error");
  } finally {
    confirmDeleteCommentBtn.disabled = false;
  }
}

/* ===== POSTS ===== */
function abrirModalEditarPost(postId) {
  const post = encontrarPost(postId);
  if (!post) return;

  postEmEdicao = post;
  editPostTexto.value = post.texto || "";
  abrirModal(modalEditarPost);

  setTimeout(() => {
    editPostTexto.focus();
    editPostTexto.setSelectionRange(editPostTexto.value.length, editPostTexto.value.length);
  }, 30);
}

function fecharModalEditarPost() {
  postEmEdicao = null;
  editPostTexto.value = "";
  fecharModal(modalEditarPost);
}

async function salvarEdicaoPost() {
  if (!postEmEdicao) return;

  const novoTexto = editPostTexto.value.trim();

  if (!novoTexto) {
    mostrarToast("O texto do post nao pode ficar vazio.", "error");
    return;
  }

  salvarEditarPost.disabled = true;

  try {
    const resposta = await editarPostAPI(
      postEmEdicao.id,
      novoTexto,
      postEmEdicao.imagem || ""
    );

    postEmEdicao.texto = resposta.conteudo ?? novoTexto;
    postEmEdicao.imagem = resposta.imagem ?? postEmEdicao.imagem ?? "";

    fecharModalEditarPost();
    renderFeed();
    mostrarToast("Post atualizado com sucesso!", "success");
  } catch (error) {
    if (error.message === "AUTH_401") {
      mostrarToast("Sessao expirada. Faca login novamente.", "error");
      setTimeout(limparSessaoERedirecionar, 1000);
      return;
    }

    mostrarToast(error.message || "Erro ao editar post.", "error");
  } finally {
    salvarEditarPost.disabled = false;
  }
}

function abrirModalExcluirPost(postId) {
  postParaExcluir = encontrarPost(postId);
  if (!postParaExcluir) return;
  abrirModal(confirmDeleteModal);
}

function fecharModalExcluirPost() {
  postParaExcluir = null;
  fecharModal(confirmDeleteModal);
}

async function excluirPostConfirmado() {
  if (!postParaExcluir) return;

  confirmDeleteBtn.disabled = true;

  try {
    await excluirPostAPI(postParaExcluir.id);
    postsCarregados = postsCarregados.filter((post) => post.id !== postParaExcluir.id);
    fecharModalExcluirPost();
    renderFeed();
    mostrarToast("Post excluido com sucesso!", "success");
  } catch (error) {
    if (error.message === "AUTH_401") {
      mostrarToast("Sessao expirada. Faca login novamente.", "error");
      setTimeout(limparSessaoERedirecionar, 1000);
      return;
    }

    mostrarToast(error.message || "Erro ao excluir post.", "error");
  } finally {
    confirmDeleteBtn.disabled = false;
  }
}

/* ===== EVENTOS ===== */
feedEl?.addEventListener("click", async (event) => {
  const button = event.target.closest("button");
  if (!button) return;

  const action = button.dataset.action;
  const postId = Number(button.dataset.postId);
  const commentId = Number(button.dataset.commentId);

  if (action === "toggle-like") {
    await alternarLike(postId, button);
    return;
  }

  if (action === "criar-comentario") {
    const input = feedEl.querySelector(`[data-role="comment-input"][data-post-id="${postId}"]`);
    if (input) {
      await criarComentario(postId, input);
    }
    return;
  }

  if (action === "abrir-editar-post") {
    abrirModalEditarPost(postId);
    return;
  }

  if (action === "abrir-excluir-post") {
    abrirModalExcluirPost(postId);
    return;
  }

  if (action === "abrir-editar-comentario") {
    abrirModalEditarComentario(postId, commentId);
    return;
  }

  if (action === "abrir-excluir-comentario") {
    abrirModalExcluirComentario(postId, commentId);
  }
});

feedEl?.addEventListener("keydown", async (event) => {
  const input = event.target.closest('[data-role="comment-input"]');
  if (!input) return;

  if (event.key === "Enter") {
    event.preventDefault();
    const postId = Number(input.dataset.postId);
    await criarComentario(postId, input);
  }
});

cancelDeleteBtn?.addEventListener("click", fecharModalExcluirPost);
confirmDeleteBtn?.addEventListener("click", excluirPostConfirmado);

confirmDeleteModal?.addEventListener("click", (event) => {
  if (event.target === confirmDeleteModal) {
    fecharModalExcluirPost();
  }
});

cancelDeleteCommentBtn?.addEventListener("click", fecharModalExcluirComentario);
confirmDeleteCommentBtn?.addEventListener("click", excluirComentarioConfirmado);

confirmDeleteCommentModal?.addEventListener("click", (event) => {
  if (event.target === confirmDeleteCommentModal) {
    fecharModalExcluirComentario();
  }
});

fecharEditarPost?.addEventListener("click", fecharModalEditarPost);
cancelarEditarPost?.addEventListener("click", fecharModalEditarPost);
salvarEditarPost?.addEventListener("click", salvarEdicaoPost);

modalEditarPost?.addEventListener("click", (event) => {
  if (event.target === modalEditarPost) {
    fecharModalEditarPost();
  }
});

cancelEditCommentBtn?.addEventListener("click", fecharModalEditarComentario);
confirmEditCommentBtn?.addEventListener("click", salvarEdicaoComentario);

editCommentModal?.addEventListener("click", (event) => {
  if (event.target === editCommentModal) {
    fecharModalEditarComentario();
  }
});

/* ===== INIT ===== */
async function initFeed() {
  const token = getToken();

  if (!token) {
    mostrarToast("Sua sessao expirou. Faca login novamente.", "error");
    setTimeout(limparSessaoERedirecionar, 1000);
    return;
  }

  try {
    const userAPI = await buscarUsuarioAPI();
    usuario = { ...usuario, ...userAPI };
    localStorage.setItem("usuarioLogado", JSON.stringify(usuario));
    atualizarFotoSidebar();

    postsCarregados = await getPostsAPI();

    postsCarregados = await Promise.all(
      postsCarregados.map(async (post) => {
        try {
          const comentarios = await buscarComentariosAPI(post.id);
          return { ...post, comentarios };
        } catch (error) {
          if (error.message === "AUTH_401") {
            throw error;
          }

          console.error(`Erro ao buscar comentarios do post ${post.id}:`, error);
          return { ...post, comentarios: [] };
        }
      })
    );

    renderFeed();
  } catch (error) {
    console.error(error);

    if (error.message === "AUTH_401") {
      mostrarToast("Sua sessao expirou. Faca login novamente.", "error");
      setTimeout(limparSessaoERedirecionar, 1000);
      return;
    }

    mostrarToast(error.message || "Nao foi possivel carregar o feed.", "error");
    renderEmptyFeed();
  }
}

initFeed();
