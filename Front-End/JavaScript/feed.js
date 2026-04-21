/* ===== SINCRONIZAR FOTO GLOBAL ===== */
(function () {
  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const userData = usuarios[user.username];
  const foto = userData?.foto || user.foto || "../Images/image.person.png";

  document.querySelectorAll(".foto-perfil").forEach(f => {
    f.src = foto;
  });
})();

/* ===== DARK MODE ===== */
const darkMode = localStorage.getItem("darkMode");
if (darkMode === "true") {
  document.body.classList.add("dark");
}

lucide.createIcons();

/* ===== USUÁRIO LOGADO ===== */
const usuarioLogado = JSON.parse(localStorage.getItem("usuarioLogado"));

let postParaExcluirId = null;
let postParaExcluirIndex = null;
let comentarioParaExcluirId = null;
let postDoComentarioId = null;

/* ===== CACHE LOCAL DO FEED ===== */
let postsCache = [];

/* ===== ELEMENTOS ===== */
const confirmDeleteModal = document.getElementById("confirmDeleteModal");
const confirmDeleteBtn = document.getElementById("confirmDelete");
const cancelDeleteBtn = document.getElementById("cancelDelete");

const confirmDeleteCommentModal = document.getElementById("confirmDeleteCommentModal");
const confirmDeleteCommentBtn = document.getElementById("confirmDeleteComment");
const cancelDeleteCommentBtn = document.getElementById("cancelDeleteComment");

/* ===== API ===== */
const API_URL = "http://127.0.0.1:8000";
const DEFAULT_AVATAR = "../Images/image.person.png";

/* ===== HELPERS ===== */
function getToken() {
  return localStorage.getItem("token");
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

async function parseResponse(response, mensagemPadrao) {
  const texto = await response.text();
  let data = {};

  try {
    data = texto ? JSON.parse(texto) : {};
  } catch {
    data = { detail: texto };
  }

  if (!response.ok) {
    console.error("Erro da API:", {
      url: response.url,
      status: response.status,
      data
    });
    throw new Error(data.detail || mensagemPadrao);
  }

  return data;
}

function formatarComentarioAPI(comentario) {
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};
  const fotoUsuarioLogado =
    usuarioLogado?.foto ||
    usuarios[usuarioLogado?.username]?.foto ||
    DEFAULT_AVATAR;

  const nomeComentario =
    comentario.nome ||
    comentario.username ||
    (usuarioLogado && comentario.usuario_id === usuarioLogado.id
      ? usuarioLogado.username
      : "Usuário");

  const fotoComentario =
    comentario.foto ||
    comentario.foto_perfil ||
    (usuarioLogado && comentario.usuario_id === usuarioLogado.id
      ? fotoUsuarioLogado
      : DEFAULT_AVATAR);

  return {
    id: comentario.id,
    userId: comentario.usuario_id ?? null,
    nome: nomeComentario,
    texto: comentario.comentario || comentario.conteudo || comentario.texto || "",
    foto: fotoComentario,
    data: comentario.data_comentario || null
  };
}

/* ===== API COMENTÁRIOS ===== */
async function buscarComentariosPost(postId) {
  try {
    const response = await fetch(`${API_URL}/comments/comentarios/${postId}`, {
      method: "GET"
    });

    const data = await parseResponse(response, "Erro ao buscar comentários.");
    return Array.isArray(data) ? data.map(formatarComentarioAPI) : [];
  } catch (erro) {
    console.error(`Falha ao buscar comentários do post ${postId}:`, erro);
    return [];
  }
}

async function adicionarComentarioAPI(postId, conteudo) {
  const token = getToken();

  const response = await fetch(`${API_URL}/comments/adicionar_comentario/${postId}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`
    },
    body: JSON.stringify({ conteudo })
  });

  const data = await parseResponse(response, "Erro ao adicionar comentário.");
  return formatarComentarioAPI(data);
}

async function deletarComentarioAPI(comentarioId) {
  const token = getToken();

  const response = await fetch(`${API_URL}/comments/deletar_comentario/${comentarioId}`, {
    method: "DELETE",
    headers: {
      "Authorization": `Bearer ${token}`
    }
  });

  return await parseResponse(response, "Erro ao deletar comentário.");
}

/* ===== MODAIS ===== */
function abrirModalExcluir(postId, postIndex) {
  postParaExcluirId = postId;
  postParaExcluirIndex = postIndex;
  confirmDeleteModal.classList.remove("hidden");
}

function fecharModalExcluir() {
  postParaExcluirId = null;
  postParaExcluirIndex = null;
  confirmDeleteModal.classList.add("hidden");
}

function abrirModalExcluirComentario(comentarioId, postId) {
  comentarioParaExcluirId = comentarioId;
  postDoComentarioId = postId;
  confirmDeleteCommentModal.classList.remove("hidden");
}

function fecharModalExcluirComentario() {
  comentarioParaExcluirId = null;
  postDoComentarioId = null;
  confirmDeleteCommentModal.classList.add("hidden");
}

confirmDeleteBtn?.addEventListener("click", async () => {
  if (postParaExcluirId === null) return;

  try {
    await deletarPostAPI(postParaExcluirId);

    postsCache = postsCache.filter(post => post.id !== postParaExcluirId);

    const postsLocal = JSON.parse(localStorage.getItem("posts")) || [];
    const indiceRemocao =
      postParaExcluirIndex !== null &&
      postParaExcluirIndex >= 0 &&
      postParaExcluirIndex < postsLocal.length
        ? postParaExcluirIndex
        : postsLocal.findIndex(item => item.id === postParaExcluirId);

    if (indiceRemocao !== -1) {
      postsLocal.splice(indiceRemocao, 1);
      localStorage.setItem("posts", JSON.stringify(postsLocal));
    }

    fecharModalExcluir();
    renderPostsFromCache();
  } catch (err) {
    alert("Erro ao deletar: " + err.message);
    fecharModalExcluir();
  }
});

cancelDeleteBtn?.addEventListener("click", fecharModalExcluir);

confirmDeleteModal?.addEventListener("click", event => {
  if (event.target === confirmDeleteModal) {
    fecharModalExcluir();
  }
});

confirmDeleteCommentBtn?.addEventListener("click", async () => {
  if (comentarioParaExcluirId === null || postDoComentarioId === null) return;

  try {
    await deletarComentarioAPI(comentarioParaExcluirId);

    const post = postsCache.find(item => item.id === postDoComentarioId);
    if (post) {
      post.comentarios = (post.comentarios || []).filter(
        item => item.id !== comentarioParaExcluirId
      );
    }

    fecharModalExcluirComentario();
    renderPostsFromCache();
  } catch (err) {
    alert(err.message);
    fecharModalExcluirComentario();
  }
});

cancelDeleteCommentBtn?.addEventListener("click", fecharModalExcluirComentario);

confirmDeleteCommentModal?.addEventListener("click", event => {
  if (event.target === confirmDeleteCommentModal) {
    fecharModalExcluirComentario();
  }
});

/* ===== POSTS ===== */
async function getPosts() {
  try {
    const token = getToken();

    const response = await fetch(`${API_URL}/post/feed`, {
      headers: {
        "Authorization": `Bearer ${token}`
      }
    });

    const data = await parseResponse(response, "Erro ao buscar feed.");

    const postsBase = data.map(post => ({
      id: post.id,
      userId: post.usuario.id,
      nome: post.usuario.username,
      usuario: `@${post.usuario.username}`,
      texto: post.conteudo,
      imagem: post.imagem,
      likes: post.likes ?? 0,
      liked: post.liked ?? false,
      foto: post.usuario.foto_perfil || DEFAULT_AVATAR,
      data: post.data_postagem,
      comentarios: []
    }));

    const comentariosPorPost = await Promise.all(
      postsBase.map(post => buscarComentariosPost(post.id))
    );

    return postsBase.map((post, index) => ({
      ...post,
      comentarios: comentariosPorPost[index]
    }));
  } catch (e) {
    console.error("Erro ao buscar feed:", e);
    return JSON.parse(localStorage.getItem("posts")) || [];
  }
}

async function carregarPosts() {
  postsCache = await getPosts();
  renderPostsFromCache();
}

/* ===== API POSTS ===== */
async function deletarPostAPI(postId) {
  const token = getToken();

  const response = await fetch(`${API_URL}/post/deletar/${postId}`, {
    method: "DELETE",
    headers: {
      "Authorization": `Bearer ${token}`
    }
  });

  return await parseResponse(response, "Erro ao deletar post.");
}

async function curtirPostAPI(postId) {
  const token = getToken();

  const response = await fetch(`${API_URL}/post/curtir/${postId}`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`
    }
  });

  return await parseResponse(response, "Erro ao curtir post.");
}

async function removerCurtidaAPI(postId) {
  const token = getToken();

  const response = await fetch(`${API_URL}/post/remover_curtida/${postId}`, {
    method: "DELETE",
    headers: {
      "Authorization": `Bearer ${token}`
    }
  });

  return await parseResponse(response, "Erro ao remover curtida.");
}

/* ===== EMPTY STATE ===== */
function renderEmptyFeed(feed) {
  feed.innerHTML = `
    <div class="empty-feed">
      <div class="empty-icon">
        <i data-lucide="sparkles"></i>
      </div>
      <h3>Nada por aqui ainda</h3>
      <p>
        Seu feed ainda está vazio. Crie seu primeiro post e comece a compartilhar
        sua evolução, rotina e conquistas com a comunidade do Pace.
      </p>
      <a href="postar.html" class="empty-btn">
        <i data-lucide="square-pen"></i>
        <span>Criar primeiro post</span>
      </a>
    </div>
  `;

  lucide.createIcons();
}

/* ===== RENDER ===== */
function renderPostsFromCache() {
  const feed = document.getElementById("feed");
  feed.innerHTML = "";

  if (!postsCache.length) {
    renderEmptyFeed(feed);
    return;
  }

  postsCache.forEach(post => {
    const card = document.createElement("article");
    card.classList.add("card");
    card.dataset.postId = post.id;

    const nomeExibido =
      usuarioLogado && post.userId === usuarioLogado.id
        ? "Você"
        : post.nome;

    const fotoUsuario = post.foto || DEFAULT_AVATAR;

    const botaoExcluir =
      usuarioLogado && post.userId === usuarioLogado.id
        ? `<button class="btn-excluir" type="button" aria-label="Excluir post">
             <i data-lucide="trash-2"></i>
           </button>`
        : "";

    const comentariosHTML = (post.comentarios || []).map(c => `
      <div class="comentario" data-comentario-id="${c.id ?? ""}">
        <img src="${escapeHtml(c.foto || DEFAULT_AVATAR)}" class="comentario-avatar" alt="Foto de ${escapeHtml(c.nome)}">

        <div class="comentario-bloco">
          <div class="comentario-conteudo">
            <div class="comentario-topo">
              <span class="comentario-nome">${escapeHtml(c.nome)}</span>
              ${
                usuarioLogado && c.userId === usuarioLogado.id
                  ? `<button class="btn-excluir-comentario" type="button" aria-label="Excluir comentário">
                       <i data-lucide="x"></i>
                     </button>`
                  : ""
              }
            </div>
            <span class="comentario-texto">${escapeHtml(c.texto)}</span>
          </div>
        </div>
      </div>
    `).join("");

    card.innerHTML = `
      <div class="post-topo">
        <img src="${escapeHtml(fotoUsuario)}" class="avatar">

        <div class="info">
          <strong>${escapeHtml(nomeExibido)}</strong>
          <span>${escapeHtml(post.usuario)}</span>
        </div>

        ${botaoExcluir}
      </div>

      <p class="post-texto">${escapeHtml(post.texto || "")}</p>

      ${
        post.imagem
          ? `<img src="${escapeHtml(post.imagem)}" class="post-img">`
          : ""
      }

      <div class="post-acoes">
        <span class="like ${post.liked ? "liked" : ""}">
          ❤️ <span class="count">${post.likes}</span>
        </span>
      </div>

      <div class="comentarios">
        ${comentariosHTML}
      </div>

      <div class="add-comentario">
        <input type="text" placeholder="Escreva um comentário..." class="input-comentario">
        <button class="btn-comentar" type="button" aria-label="Enviar comentário">➤</button>
      </div>
    `;

    feed.appendChild(card);
  });

  lucide.createIcons();
}

carregarPosts();

/* ===== EVENTOS ===== */
document.addEventListener("click", async e => {
  const like = e.target.closest(".like");
  if (like) {
    const card = like.closest(".card");
    const postId = Number(card.dataset.postId);

    if (!postId) return;

    const post = postsCache.find(p => p.id === postId);
    if (!post) return;

    const likedAnterior = post.liked;
    const likesAnterior = post.likes;

    post.liked = !post.liked;
    post.likes += post.liked ? 1 : -1;

    if (post.likes < 0) post.likes = 0;

    const countEl = like.querySelector(".count");
    if (countEl) countEl.textContent = post.likes;

    like.classList.toggle("liked", post.liked);

    try {
      if (likedAnterior) {
        await removerCurtidaAPI(postId);
      } else {
        await curtirPostAPI(postId);
      }
    } catch (err) {
      post.liked = likedAnterior;
      post.likes = likesAnterior;

      if (countEl) countEl.textContent = post.likes;
      like.classList.toggle("liked", post.liked);

      alert(err.message);
    }

    return;
  }

  const botaoComentar = e.target.closest(".btn-comentar");
  if (botaoComentar) {
    const card = botaoComentar.closest(".card");
    const input = card.querySelector(".input-comentario");
    const texto = input.value.trim();

    if (!texto) return;

    const postId = Number(card.dataset.postId);
    const post = postsCache.find(p => p.id === postId);

    if (!post) return;

    botaoComentar.disabled = true;

    try {
      const comentarioCriado = await adicionarComentarioAPI(postId, texto);
      const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

      if (!comentarioCriado.nome && usuarioLogado) {
        comentarioCriado.nome = usuarioLogado.username;
      }

      if (!comentarioCriado.foto) {
        comentarioCriado.foto =
          usuarioLogado?.foto ||
          usuarios[usuarioLogado?.username]?.foto ||
          DEFAULT_AVATAR;
      }

      if (!post.comentarios) {
        post.comentarios = [];
      }

      post.comentarios.unshift(comentarioCriado);
      input.value = "";
      renderPostsFromCache();
    } catch (err) {
      alert(err.message);
    } finally {
      botaoComentar.disabled = false;
    }

    return;
  }

  if (e.target.closest(".btn-excluir")) {
    const card = e.target.closest(".card");
    const postId = Number(card.dataset.postId);

    if (!postId) return;

    const cards = document.querySelectorAll(".card");
    const index = Array.from(cards).indexOf(card);

    const post = postsCache.find(p => p.id === postId);
    if (!post) return;

    if (post.userId !== usuarioLogado.id) {
      alert("Você não pode excluir este post.");
      return;
    }

    abrirModalExcluir(post.id, index);
    return;
  }

  const botaoExcluirComentario = e.target.closest(".btn-excluir-comentario");
  if (botaoExcluirComentario) {
    const comentarioEl = botaoExcluirComentario.closest(".comentario");
    const card = botaoExcluirComentario.closest(".card");
    const postId = Number(card.dataset.postId);
    const comentarioId = Number(comentarioEl.dataset.comentarioId);

    const post = postsCache.find(p => p.id === postId);
    if (!post) return;

    const comentario = (post.comentarios || []).find(item => item.id === comentarioId);
    if (!comentario) return;

    if (comentario.userId !== usuarioLogado.id) {
      alert("Você não pode excluir este comentário.");
      return;
    }

    abrirModalExcluirComentario(comentarioId, postId);
  }
});

document.addEventListener("keydown", e => {
  if (e.key !== "Enter" || !e.target.classList.contains("input-comentario")) {
    return;
  }

  e.preventDefault();
  const card = e.target.closest(".card");
  const botao = card?.querySelector(".btn-comentar");
  botao?.click();
});
