(function () {
  const API_URL = "http://127.0.0.1:8000";

  const usuarioLogado = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};
  const darkMode = localStorage.getItem("darkMode") === "true";

  const fotoSidebar = document.getElementById("fotoSidebar");
  const darkModeToggle = document.getElementById("darkModeToggle");
  const logoutBtn = document.getElementById("logoutBtn");

  const senhaForm = document.getElementById("senhaForm");
  const senhaAtualInput = document.getElementById("senhaAtual");
  const novaSenhaInput = document.getElementById("novaSenha");
  const confirmarSenhaInput = document.getElementById("confirmarSenha");
  const senhaMensagem = document.getElementById("senhaMensagem");
  const salvarSenhaBtn = document.getElementById("salvarSenhaBtn");

  function definirMensagem(texto, tipo, titulo) {
    senhaMensagem.classList.remove("hidden", "erro", "sucesso", "info");

    const icone =
      tipo === "sucesso"
        ? "check-circle-2"
        : tipo === "erro"
          ? "alert-circle"
          : "info";

    senhaMensagem.classList.add(tipo);
    senhaMensagem.innerHTML = `
      <div class="mensagem-icone">
        <i data-lucide="${icone}"></i>
      </div>
      <div class="mensagem-conteudo">
        <strong>${titulo}</strong>
        <span>${texto}</span>
      </div>
    `;

    lucide.createIcons();
  }

  function mostrarErro(texto) {
    definirMensagem(texto, "erro", "Não foi possível concluir");
  }

  function mostrarSucesso(texto) {
    definirMensagem(texto, "sucesso", "Tudo certo");
  }

  function esconderMensagem() {
    senhaMensagem.innerHTML = "";
    senhaMensagem.classList.add("hidden");
    senhaMensagem.classList.remove("erro", "sucesso", "info");
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
      throw new Error(data.detail || mensagemPadrao);
    }

    return data;
  }

  if (darkMode) {
    document.body.classList.add("dark");
  }

  if (darkModeToggle) {
    darkModeToggle.checked = darkMode;
  }

  if (usuarioLogado) {
    const userData = usuarios[usuarioLogado.username] || {};
    const foto = userData.foto || usuarioLogado.foto || "../Images/image.person.png";

    if (fotoSidebar) {
      fotoSidebar.src = foto;
    }
  }

  darkModeToggle?.addEventListener("change", () => {
    const ativado = darkModeToggle.checked;
    document.body.classList.toggle("dark", ativado);
    localStorage.setItem("darkMode", String(ativado));
  });

  logoutBtn?.addEventListener("click", () => {
    localStorage.removeItem("token");
    localStorage.removeItem("usuarioLogado");
    localStorage.removeItem("darkMode");
    window.location.href = "./entrar.html";
  });

  senhaForm?.addEventListener("submit", async event => {
    event.preventDefault();
    esconderMensagem();

    const senhaAtual = senhaAtualInput.value.trim();
    const novaSenha = novaSenhaInput.value.trim();
    const confirmarSenha = confirmarSenhaInput.value.trim();
    const token = localStorage.getItem("token");

    if (!senhaAtual || !novaSenha || !confirmarSenha) {
      mostrarErro("Preencha todos os campos antes de continuar.");
      return;
    }

    if (novaSenha.length < 6) {
      mostrarErro("A nova senha deve ter pelo menos 6 caracteres.");
      return;
    }

    if (novaSenha !== confirmarSenha) {
      mostrarErro("A confirmação da nova senha não confere.");
      return;
    }

    if (!token) {
      mostrarErro("Sua sessão expirou. Faça login novamente para alterar a senha.");
      return;
    }

    salvarSenhaBtn.disabled = true;

    try {
      const response = await fetch(`${API_URL}/auth/atualizar_senha`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`
        },
        body: JSON.stringify({
          senha_atual: senhaAtual,
          nova_senha: novaSenha
        })
      });

      const data = await parseResponse(response, "Erro ao atualizar a senha.");
      mostrarSucesso(data.message || "Senha atualizada com sucesso!");
      senhaForm.reset();
    } catch (error) {
      mostrarErro(error.message || "Erro ao atualizar a senha.");
    } finally {
      salvarSenhaBtn.disabled = false;
    }
  });

  lucide.createIcons();
})();
