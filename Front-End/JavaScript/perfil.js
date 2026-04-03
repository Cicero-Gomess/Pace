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

  // sidebar
  document.querySelectorAll(".foto-perfil").forEach(f => {
    f.src = foto;
  });

  // perfil
  if (fotoEl) {
    fotoEl.src = foto;
  }
}

/* ===== MOSTRAR DADOS ===== */
nomeEl.innerText = usuario.username;
emailEl.innerText = usuario.email;

/* ===== CARREGAR BIO ===== */
const usuariosStorage = JSON.parse(localStorage.getItem("usuarios")) || {};

if (usuariosStorage[usuario.username]?.bio) {
  bioInput.value = usuariosStorage[usuario.username].bio;
}

/* ===== SALVAR BIO ===== */
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

/* ===== POSTS DO USUÁRIO ===== */
function carregarPostsUsuario(){

  const posts = JSON.parse(localStorage.getItem("posts")) || [];
  const container = document.getElementById("postsUsuario");

  if (!container) return;

  container.innerHTML = "";

  const meusPosts = posts.filter(p => p.userId === usuario.id);

  meusPosts.forEach(post => {

    const div = document.createElement("div");
    div.classList.add("card");

    div.innerHTML = `
      <p>${post.texto || ""}</p>
      ${
        post.imagem
          ? `<img src="${post.imagem}" class="post-img">`
          : ""
      }
    `;

    container.appendChild(div);
  });
}

/* ===== INIT ===== */
atualizarFotoGlobal();
carregarStatsUsuario();
carregarPostsUsuario();