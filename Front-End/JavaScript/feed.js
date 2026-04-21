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

/* ===== CACHE LOCAL DO FEED ===== */
let postsCache = [];

/* ===== ELEMENTOS ===== */
const confirmDeleteModal = document.getElementById("confirmDeleteModal");
const confirmDeleteBtn = document.getElementById("confirmDelete");
const cancelDeleteBtn = document.getElementById("cancelDelete");

/* ===== API ===== */
const API_URL = "http://127.0.0.1:8000";

/* ===== MODAL EXCLUIR ===== */
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

cancelDeleteBtn?.addEventListener("click", () => {
  fecharModalExcluir();
});

confirmDeleteModal?.addEventListener("click", event => {
  if (event.target === confirmDeleteModal) {
    fecharModalExcluir();
  }
});

/* ===== POSTS ===== */
async function getPosts() {
  try {
    const token = localStorage.getItem("token");

    const response = await fetch(`${API_URL}/post/feed`, {
      headers: {
        "Authorization": `Bearer ${token}`
      }
    });

    if (!response.ok) {
      throw new Error("Erro ao buscar feed.");
    }

    const data = await response.json();

    return data.map(post => ({
      id: post.id,
      userId: post.usuario.id,
      nome: post.usuario.username,
      usuario: `@${post.usuario.username}`,
      texto: post.conteudo,
      imagem: post.imagem,
      likes: post.likes ?? 0,
      liked: post.liked ?? false,
      username: post.usuario.username,
      foto: post.usuario.foto_perfil || "../Images/image.person.png",
      data: post.data_postagem,
      comentarios: []
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
  const token = localStorage.getItem("token");

  const response = await fetch(`${API_URL}/post/deletar/${postId}`, {
    method: "DELETE",
    headers: {
      "Authorization": `Bearer ${token}`
    }
  });

  if (!response.ok) {
    const erro = await response.json();
    throw new Error(erro.detail || "Erro ao deletar");
  }

  return await response.json();
}

async function curtirPostAPI(postId) {
  const token = localStorage.getItem("token");

  const response = await fetch(`${API_URL}/post/curtir/${postId}`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`
    }
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.detail || "Erro ao curtir post.");
  }

  return data;
}

async function removerCurtidaAPI(postId) {
  const token = localStorage.getItem("token");

  const response = await fetch(`${API_URL}/post/remover_curtida/${postId}`, {
    method: "DELETE",
    headers: {
      "Authorization": `Bearer ${token}`
    }
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.detail || "Erro ao remover curtida.");
  }

  return data;
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

    const fotoUsuario = post.foto || "../Images/image.person.png";

    const botaoExcluir =
      usuarioLogado && post.userId === usuarioLogado.id
        ? `<button class="btn-excluir">
             <i data-lucide="trash-2"></i>
           </button>`
        : "";

    const comentariosHTML = (post.comentarios || []).map(c => `
      <div class="comentario">
        <img src="../Images/image.person.png" class="comentario-avatar">

        <div class="comentario-conteudo">
          <span class="comentario-nome">${c.nome}</span>
          <span class="comentario-texto">${c.texto}</span>
        </div>

        ${
          usuarioLogado && c.userId === usuarioLogado.id
            ? `<button class="btn-excluir-comentario">
                 <i data-lucide="x"></i>
               </button>`
            : ""
        }
      </div>
    `).join("");

    card.innerHTML = `
      <div class="post-topo">
        <img src="${fotoUsuario}" class="avatar">

        <div class="info">
          <strong>${nomeExibido}</strong>
          <span>${post.usuario}</span>
        </div>

        ${botaoExcluir}
      </div>

      <p class="post-texto">${post.texto || ""}</p>

      ${
        post.imagem
          ? `<img src="${post.imagem}" class="post-img">`
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
        <button class="btn-comentar">➤</button>
      </div>
    `;

    feed.appendChild(card);
  });

  lucide.createIcons();
}

carregarPosts();

/* ===== EVENTOS ===== */
document.addEventListener("click", async e => {
  const postsLocal = JSON.parse(localStorage.getItem("posts")) || [];

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

    if (post.likes < 0) {
      post.likes = 0;
    }

    const countEl = like.querySelector(".count");
    if (countEl) {
      countEl.textContent = post.likes;
    }

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

      if (countEl) {
        countEl.textContent = post.likes;
      }

      like.classList.toggle("liked", post.liked);
      alert(err.message);
    }

    return;
  }

  if (e.target.classList.contains("btn-comentar")) {
    const card = e.target.closest(".card");
    const input = card.querySelector(".input-comentario");

    const texto = input.value.trim();
    if (!texto) return;

    const postId = Number(card.dataset.postId);
    const post = postsCache.find(p => p.id === postId);

    if (!post) return;

    const comentario = {
      userId: usuarioLogado ? usuarioLogado.id : null,
      nome: usuarioLogado ? usuarioLogado.username : "Usuário",
      texto: texto
    };

    if (!post.comentarios) {
      post.comentarios = [];
    }

    post.comentarios.push(comentario);

    const cards = document.querySelectorAll(".card");
    const index = Array.from(cards).indexOf(card);

    if (index !== -1) {
      if (!postsLocal[index]?.comentarios) {
        postsLocal[index].comentarios = [];
      }

      postsLocal[index].comentarios.push(comentario);
      localStorage.setItem("posts", JSON.stringify(postsLocal));
    }

    renderPostsFromCache();
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
  }

  if (e.target.closest(".btn-excluir-comentario")) {
    const comentarioEl = e.target.closest(".comentario");
    const card = e.target.closest(".card");
    const postId = Number(card.dataset.postId);

    const post = postsCache.find(p => p.id === postId);
    if (!post) return;

    const comentariosEls = card.querySelectorAll(".comentario");
    const comentarioIndex = Array.from(comentariosEls).indexOf(comentarioEl);

    if (comentarioIndex === -1) return;

    const comentarios = post.comentarios || [];

    if (!comentarios[comentarioIndex]) return;

    if (comentarios[comentarioIndex].userId !== usuarioLogado.id) {
      alert("Você não pode excluir este comentário.");
      return;
    }

    comentarios.splice(comentarioIndex, 1);

    const cards = document.querySelectorAll(".card");
    const postIndex = Array.from(cards).indexOf(card);

    if (postIndex !== -1) {
      const postsLocalAtualizados = JSON.parse(localStorage.getItem("posts")) || [];
      const comentariosLocal = postsLocalAtualizados[postIndex]?.comentarios || [];

      comentariosLocal.splice(comentarioIndex, 1);

      if (postsLocalAtualizados[postIndex]) {
        postsLocalAtualizados[postIndex].comentarios = comentariosLocal;
      }

      localStorage.setItem("posts", JSON.stringify(postsLocalAtualizados));
    }

    renderPostsFromCache();
  }
});
