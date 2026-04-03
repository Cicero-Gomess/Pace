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

/* ===== COMUNIDADE ATIVA ===== */
let comunidadeAtiva = "todas";

/* ===== POSTS ===== */
function getPosts(){
  return JSON.parse(localStorage.getItem("posts")) || [];
}

/* ===== RENDER ===== */
function renderPosts(){
  const feed = document.getElementById("feed");
  feed.innerHTML = "";

  let posts = getPosts();

  /* 🔥 FILTRO DE COMUNIDADE */
  if (comunidadeAtiva !== "todas") {
    posts = posts.filter(p => p.comunidade === comunidadeAtiva);
  }

  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  posts.forEach(post => {

    const card = document.createElement("div");
    card.classList.add("card");

    /* ===== NOME ===== */
    const nomeExibido =
      usuarioLogado && post.userId === usuarioLogado.id
        ? "Você"
        : post.nome;

    /* ===== FOTO DINÂMICA ===== */
    const fotoUsuario =
      usuarios[post.username]?.foto || "../Images/image.person.png";

    /* ===== EXCLUIR POST ===== */
    const botaoExcluir =
      usuarioLogado && post.userId === usuarioLogado.id
        ? `<button class="btn-excluir">
             <i data-lucide="trash-2"></i>
           </button>`
        : "";

    /* ===== COMENTÁRIOS ===== */
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

  /* recria ícones */
  lucide.createIcons();
}

renderPosts();

/* ===== EVENTOS ===== */
document.addEventListener("click", (e) => {

  /* LIKE */
  const like = e.target.closest(".like");
  if (like) {

    const posts = getPosts();
    const cards = document.querySelectorAll(".card");
    const index = Array.from(cards).indexOf(like.closest(".card"));

    if (index === -1) return;

    posts[index].liked = !posts[index].liked;
    posts[index].likes += posts[index].liked ? 1 : -1;

    localStorage.setItem("posts", JSON.stringify(posts));
    renderPosts();
  }

  /* COMENTAR */
  if (e.target.classList.contains("btn-comentar")) {

    const card = e.target.closest(".card");
    const input = card.querySelector(".input-comentario");

    const texto = input.value.trim();
    if (!texto) return;

    const posts = getPosts();
    const cards = document.querySelectorAll(".card");
    const index = Array.from(cards).indexOf(card);

    if (index === -1) return;

    const comentario = {
      userId: usuarioLogado ? usuarioLogado.id : null,
      nome: usuarioLogado ? usuarioLogado.username : "Usuário",
      texto: texto
    };

    if (!posts[index].comentarios) {
      posts[index].comentarios = [];
    }

    posts[index].comentarios.push(comentario);

    localStorage.setItem("posts", JSON.stringify(posts));
    renderPosts();
  }

  /* EXCLUIR POST */
  if (e.target.closest(".btn-excluir")) {

    const card = e.target.closest(".card");
    const posts = getPosts();
    const cards = document.querySelectorAll(".card");
    const index = Array.from(cards).indexOf(card);

    if (index === -1) return;

    if (posts[index].userId !== usuarioLogado.id) {
      alert("Você não pode excluir este post.");
      return;
    }

    posts.splice(index, 1);

    localStorage.setItem("posts", JSON.stringify(posts));
    renderPosts();
  }

  /* EXCLUIR COMENTÁRIO */
  if (e.target.closest(".btn-excluir-comentario")) {

    const comentarioEl = e.target.closest(".comentario");
    const card = e.target.closest(".card");

    const posts = getPosts();
    const cards = document.querySelectorAll(".card");
    const postIndex = Array.from(cards).indexOf(card);

    if (postIndex === -1) return;

    const comentarios = posts[postIndex].comentarios || [];
    const comentariosEls = card.querySelectorAll(".comentario");
    const comentarioIndex = Array.from(comentariosEls).indexOf(comentarioEl);

    if (comentarioIndex === -1) return;

    if (comentarios[comentarioIndex].userId !== usuarioLogado.id) {
      alert("Você não pode excluir este comentário.");
      return;
    }

    comentarios.splice(comentarioIndex, 1);

    localStorage.setItem("posts", JSON.stringify(posts));
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