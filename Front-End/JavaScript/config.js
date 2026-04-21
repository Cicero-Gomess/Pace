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

lucide.createIcons();

/* ===== TEMA ===== */
const toggle = document.getElementById("darkToggle");

if (localStorage.getItem("darkMode") === "true") {
  document.body.classList.add("dark");
  if (toggle) toggle.checked = true;
}

toggle?.addEventListener("change", () => {
  if (toggle.checked) {
    document.body.classList.add("dark");
    localStorage.setItem("darkMode", "true");
  } else {
    document.body.classList.remove("dark");
    localStorage.setItem("darkMode", "false");
  }
});

/* ===== DADOS DO USUÁRIO ===== */
const usuarioLogado = JSON.parse(localStorage.getItem("usuarioLogado"));
const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

const usernameInput = document.getElementById("usernameInput");
const emailInput = document.getElementById("emailInput");
const salvarContaBtn = document.getElementById("salvarConta");

const senhaAtualInput = document.getElementById("senhaAtual");
const novaSenhaInput = document.getElementById("novaSenha");
const confirmarSenhaInput = document.getElementById("confirmarSenha");
const alterarSenhaBtn = document.getElementById("alterarSenha");

const logoutBtn = document.querySelector(".logout");

if (usuarioLogado) {
  if (usernameInput) {
    usernameInput.value = usuarioLogado.username || "";
  }

  if (emailInput) {
    emailInput.value = usuarioLogado.email || "";
  }
}

/* ===== SALVAR CONTA ===== */
salvarContaBtn?.addEventListener("click", () => {
  if (!usuarioLogado) {
    alert("Nenhum usuário logado.");
    return;
  }

  const novoUsername = usernameInput.value.trim();
  const novoEmail = emailInput.value.trim();

  if (!novoUsername || !novoEmail) {
    alert("Preencha nome de usuário e email.");
    return;
  }

  const usernameAntigo = usuarioLogado.username;
  const dadosUsuario = usuarios[usernameAntigo] || {};

  delete usuarios[usernameAntigo];

  usuarios[novoUsername] = {
    ...dadosUsuario,
    username: novoUsername,
    email: novoEmail,
    foto: dadosUsuario.foto || usuarioLogado.foto || "../Images/image.person.png",
    bio: dadosUsuario.bio || ""
  };

  const atualizado = {
    ...usuarioLogado,
    username: novoUsername,
    email: novoEmail,
    foto: usuarios[novoUsername].foto
  };

  localStorage.setItem("usuarios", JSON.stringify(usuarios));
  localStorage.setItem("usuarioLogado", JSON.stringify(atualizado));

  alert("Alterações salvas com sucesso.");
});

/* ===== ALTERAR SENHA ===== */
alterarSenhaBtn?.addEventListener("click", () => {
  const senhaAtual = senhaAtualInput.value.trim();
  const novaSenha = novaSenhaInput.value.trim();
  const confirmarSenha = confirmarSenhaInput.value.trim();

  if (!senhaAtual || !novaSenha || !confirmarSenha) {
    alert("Preencha todos os campos de senha.");
    return;
  }

  if (novaSenha.length < 6) {
    alert("A nova senha deve ter pelo menos 6 caracteres.");
    return;
  }

  if (novaSenha !== confirmarSenha) {
    alert("As novas senhas não coincidem.");
    return;
  }

  if (senhaAtual === novaSenha) {
    alert("A nova senha precisa ser diferente da senha atual.");
    return;
  }

  alert("Senha validada no front. Quando a API estiver pronta, essa troca será persistida.");

  senhaAtualInput.value = "";
  novaSenhaInput.value = "";
  confirmarSenhaInput.value = "";
});

/* ===== LOGOUT ===== */
logoutBtn?.addEventListener("click", () => {
  localStorage.removeItem("token");
  localStorage.removeItem("usuarioLogado");
  sessionStorage.removeItem("logado");
  window.location.href = "entrar.html";
});
