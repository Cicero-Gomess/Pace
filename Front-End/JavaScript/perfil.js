/* ===== DARK MODE ===== */
const darkMode = localStorage.getItem("darkMode");
if (darkMode === "true") {
  document.body.classList.add("dark");
}

lucide.createIcons();

/* ===== USUÁRIO ===== */
let usuario = JSON.parse(localStorage.getItem("usuarioLogado"));

const nomeEl = document.getElementById("nomeUsuario");
const emailEl = document.getElementById("emailUsuario");
const fotoEl = document.getElementById("fotoPerfil");
const inputFoto = document.getElementById("inputFoto");

/* ===== FUNÇÃO GLOBAL DE FOTO ===== */
function atualizarFotoGlobal() {

  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const userData = usuarios[user.username];

  const foto = userData?.foto || "../Images/image.person.png";

  // atualiza sidebar
  document.querySelectorAll(".foto-perfil").forEach(f => {
    f.src = foto;
  });

  // atualiza perfil
  if (fotoEl) {
    fotoEl.src = foto;
  }
}

/* ===== MOSTRAR DADOS ===== */
if (usuario) {
  nomeEl.innerText = usuario.username;
  emailEl.innerText = usuario.email;
}

/* inicial */
atualizarFotoGlobal();

/* ===== TROCAR FOTO ===== */
inputFoto.addEventListener("change", () => {

  const file = inputFoto.files[0];
  if (!file) return;

  const reader = new FileReader();

  reader.onload = () => {

    const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

    const user = JSON.parse(localStorage.getItem("usuarioLogado"));

    // 🔥 salva por usuário
    usuarios[user.username] = {
      ...usuarios[user.username],
      username: user.username,
      foto: reader.result
    };

    localStorage.setItem("usuarios", JSON.stringify(usuarios));

    // atualiza usuário logado
    user.foto = reader.result;
    localStorage.setItem("usuarioLogado", JSON.stringify(user));

    atualizarFotoGlobal();
  };

  reader.readAsDataURL(file);
});