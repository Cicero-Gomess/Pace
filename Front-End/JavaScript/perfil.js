/* ===== DARK MODE ===== */
const darkMode = localStorage.getItem("darkMode");
if (darkMode === "true") {
  document.body.classList.add("dark");
}

lucide.createIcons();

/* ===== USUÁRIO ===== */
let usuario = JSON.parse(localStorage.getItem("usuarioLogado"));

if (!usuario) {
  alert("Você precisa estar logado.");
  window.location.href = "login.html";
}

/* ===== ELEMENTOS ===== */
const nomeEl = document.getElementById("nomeUsuario");
const emailEl = document.getElementById("emailUsuario");
const fotoEl = document.getElementById("fotoPerfil");
const inputFoto = document.getElementById("inputFoto");

const bioInput = document.getElementById("bioUsuario");
const btnSalvarBio = document.getElementById("salvarBio");

/* ===== FOTO GLOBAL ===== */
function atualizarFotoGlobal() {

  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const userData = usuarios[user.username];
  const foto = userData?.foto || "../Images/image.person.png";

  document.querySelectorAll(".foto-perfil").forEach(f => {
    f.src = foto;
  });

  if (fotoEl) fotoEl.src = foto;
}

/* ===== MOSTRAR DADOS ===== */
nomeEl.innerText = usuario.username;
emailEl.innerText = usuario.email;

/* ===== BIO ===== */
const usuariosStorage = JSON.parse(localStorage.getItem("usuarios")) || {};

if (usuariosStorage[usuario.username]?.bio) {
  bioInput.value = usuariosStorage[usuario.username].bio;
}

btnSalvarBio.addEventListener("click", () => {

  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  usuarios[usuario.username] = {
    ...usuarios[usuario.username],
    username: usuario.username,
    bio: bioInput.value,
    foto: usuarios[usuario.username]?.foto || usuario.foto
  };

  localStorage.setItem("usuarios", JSON.stringify(usuarios));
});

/* ===== TROCAR FOTO ===== */
inputFoto.addEventListener("change", () => {

  const file = inputFoto.files[0];
  if (!file) return;

  const reader = new FileReader();

  reader.onload = () => {

    const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};
    const userAtual = JSON.parse(localStorage.getItem("usuarioLogado"));

    if (!userAtual) return;

    usuarios[userAtual.username] = {
      ...usuarios[userAtual.username],
      username: userAtual.username,
      foto: reader.result,
      bio: usuarios[userAtual.username]?.bio || ""
    };

    localStorage.setItem("usuarios", JSON.stringify(usuarios));

    userAtual.foto = reader.result;
    localStorage.setItem("usuarioLogado", JSON.stringify(userAtual));

    atualizarFotoGlobal();
  };

  reader.readAsDataURL(file);
});

/* ===== STATS ===== */
function carregarStatsUsuario(){

  const posts = JSON.parse(localStorage.getItem("posts")) || [];

  const meusPosts = posts.filter(p => p.userId === usuario.id);

  let totalLikes = 0;
  let totalComentarios = 0;

  meusPosts.forEach(post => {
    totalLikes += post.likes || 0;
    totalComentarios += (post.comentarios || []).length;
  });

  document.getElementById("totalPosts").innerText = meusPosts.length;
  document.getElementById("totalLikes").innerText = totalLikes;
  document.getElementById("totalComentarios").innerText = totalComentarios;
}

/* ===== POSTS SEPARADOS ===== */
function carregarPostsUsuario(){

  const posts = JSON.parse(localStorage.getItem("posts")) || [];

  const imagensContainer = document.getElementById("postsImagem");
  const textoContainer = document.getElementById("postsTexto");

  if (!imagensContainer || !textoContainer) return;

  imagensContainer.innerHTML = "";
  textoContainer.innerHTML = "";

  const meusPosts = posts.filter(p => p.userId === usuario.id);

  meusPosts.forEach(post => {

    /* IMAGENS */
    if (post.imagem) {
      const div = document.createElement("div");
      div.classList.add("post-item");

      div.innerHTML = `
        <img src="${post.imagem}">
        <div class="post-overlay">
          ❤️ ${post.likes || 0} • 💬 ${(post.comentarios || []).length}
        </div>
      `;

      div.onclick = () => abrirModal(post);

      imagensContainer.appendChild(div);
    }

    /* TEXTO */
    if (post.texto) {
      const div = document.createElement("div");
      div.classList.add("post-texto-card");

      div.innerHTML = `
        <p>${post.texto}</p>
        <small>❤️ ${post.likes || 0} • 💬 ${(post.comentarios || []).length}</small>
      `;

      textoContainer.appendChild(div);
    }

  });
}

/* ===== MODAL ===== */
const modal = document.getElementById("modalPost");
const modalImg = document.getElementById("modalImg");
const modalTexto = document.getElementById("modalTexto");
const modalLikes = document.getElementById("modalLikes");
const modalComentarios = document.getElementById("modalComentarios");
const fecharModal = document.getElementById("fecharModal");

function abrirModal(post){
  modalImg.src = post.imagem || "";
  modalTexto.innerText = post.texto || "";
  modalLikes.innerText = post.likes || 0;
  modalComentarios.innerText = (post.comentarios || []).length;

  modal.classList.remove("hidden");
}

fecharModal.onclick = () => modal.classList.add("hidden");

modal.onclick = (e) => {
  if (e.target === modal) modal.classList.add("hidden");
};

/* ===== INIT ===== */
atualizarFotoGlobal();
carregarStatsUsuario();
carregarPostsUsuario();