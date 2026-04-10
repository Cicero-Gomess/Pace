/* ===== SINCRONIZAR FOTO GLOBAL ===== */
(function () {
  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const userData = usuarios[user.username];
  const foto = userData?.foto || "../Images/image.person.png";

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

const confirmDeleteModal = document.getElementById("confirmDeleteModal");
const confirmDeleteBtn = document.getElementById("confirmDelete");
const cancelDeleteBtn = document.getElementById("cancelDelete");

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
    const postsLocal = JSON.parse(localStorage.getItem("posts")) || [];
    const indiceRemocao = postParaExcluirIndex !== null && postParaExcluirIndex >= 0 && postParaExcluirIndex < postsLocal.length
      ? postParaExcluirIndex
      : postsLocal.findIndex(item => item.id === postParaExcluirId);
    if (indiceRemocao !== -1) {
      postsLocal.splice(indiceRemocao, 1);
      localStorage.setItem("posts", JSON.stringify(postsLocal));
    }
    fecharModalExcluir();
    renderPosts();
  } catch (err) {
    alert("Erro ao deletar: " + err.message);
    fecharModalExcluir();
  }
});

cancelDeleteBtn?.addEventListener("click", () => {
  fecharModalExcluir();
});

confirmDeleteModal?.addEventListener("click", (event) => {
  if (event.target === confirmDeleteModal) {
    fecharModalExcluir();
  }
});

/* ===== COMUNIDADE ATIVA ===== */
let comunidadeAtiva = "todas";

/* ===== BUSCAR POSTS DA API ===== */
async function getPosts(){
  try {
    const token = localStorage.getItem("token");

    const response = await fetch("http://127.0.0.1:8000/post/feed", {
      headers: {
        "Authorization": `Bearer ${token}`
      }
    });

    const data = await response.json();

    return data.map(post => ({
      id: post.id,
      userId: post.usuario.id,
      nome: post.usuario.username,
      usuario: `@${post.usuario.username}`,
      texto: post.conteudo,
      imagem: post.imagem,
      comunidade: "geral",
      likes: 0,
      liked: false,
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

/* ===== DELETAR POST NA API ===== */
async function deletarPostAPI(postId) {
  const token = localStorage.getItem("token");

  const response = await fetch(`http://127.0.0.1:8000/post/deletar/${postId}`, {
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

/* ===== RENDER ===== */
async function renderPosts(){
  const feed = document.getElementById("feed");
  feed.innerHTML = "";

  let posts = await getPosts();

  if (comunidadeAtiva !== "todas") {
    posts = posts.filter(p => p.comunidade === comunidadeAtiva);
  }

  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  posts.forEach(post => {

    const card = document.createElement("div");
    card.classList.add("card");

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
          <span class="tag-comunidade">${post.comunidade || "geral"}</span>
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

renderPosts();

/* ===== EVENTOS ===== */
document.addEventListener("click", async (e) => {

  let postsLocal = JSON.parse(localStorage.getItem("posts")) || [];

  /* LIKE */
  const like = e.target.closest(".like");
  if (like) {

    const cards = document.querySelectorAll(".card");
    const index = Array.from(cards).indexOf(like.closest(".card"));

    if (index === -1) return;

    postsLocal[index].liked = !postsLocal[index].liked;
    postsLocal[index].likes += postsLocal[index].liked ? 1 : -1;

    localStorage.setItem("posts", JSON.stringify(postsLocal));
    renderPosts();
  }

  /* COMENTAR */
  if (e.target.classList.contains("btn-comentar")) {

    const card = e.target.closest(".card");
    const input = card.querySelector(".input-comentario");

    const texto = input.value.trim();
    if (!texto) return;

    const cards = document.querySelectorAll(".card");
    const index = Array.from(cards).indexOf(card);

    if (index === -1) return;

    const comentario = {
      userId: usuarioLogado ? usuarioLogado.id : null,
      nome: usuarioLogado ? usuarioLogado.username : "Usuário",
      texto: texto
    };

    if (!postsLocal[index]?.comentarios) {
      postsLocal[index].comentarios = [];
    }

    postsLocal[index].comentarios.push(comentario);

    localStorage.setItem("posts", JSON.stringify(postsLocal));
    renderPosts();
  }

  /* EXCLUIR POST (AGORA API + LOCAL) */
  if (e.target.closest(".btn-excluir")) {

    const card = e.target.closest(".card");
    const cards = document.querySelectorAll(".card");
    const index = Array.from(cards).indexOf(card);

    if (index === -1) return;

    let postsAPI = await getPosts();
    const post = postsAPI[index];

    if (post.userId !== usuarioLogado.id) {
      alert("Você não pode excluir este post.");
      return;
    }
    abrirModalExcluir(post.id, index);
  }

  /* EXCLUIR COMENTÁRIO */
  if (e.target.closest(".btn-excluir-comentario")) {

    const comentarioEl = e.target.closest(".comentario");
    const card = e.target.closest(".card");

    const cards = document.querySelectorAll(".card");
    const postIndex = Array.from(cards).indexOf(card);

    if (postIndex === -1) return;

    const comentarios = postsLocal[postIndex]?.comentarios || [];
    const comentariosEls = card.querySelectorAll(".comentario");
    const comentarioIndex = Array.from(comentariosEls).indexOf(comentarioEl);

    if (comentarioIndex === -1) return;

    if (comentarios[comentarioIndex].userId !== usuarioLogado.id) {
      alert("Você não pode excluir este comentário.");
      return;
    }

    comentarios.splice(comentarioIndex, 1);

    localStorage.setItem("posts", JSON.stringify(postsLocal));
    renderPosts();
  }

});

/* ===== FILTRO DE COMUNIDADE ===== */
document.querySelectorAll(".filtro-comunidade button")
  .forEach(btn => {
    btn.addEventListener("click", () => {

      comunidadeAtiva = btn.dataset.com;

      document.querySelectorAll(".filtro-comunidade button")
        .forEach(b => b.classList.remove("active"));

      btn.classList.add("active");

      renderPosts();
    });
  });