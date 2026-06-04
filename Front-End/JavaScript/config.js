import { initAppShell, initDarkModeToggle } from "./shared/app-shell.js";
import { logout, updatePassword, handleAuthError } from "./shared/auth.js";
import { initLucide } from "./shared/ui.js";
import { ApiError } from "./shared/api.js";

const shellOk = await initAppShell();

if (shellOk) {
  initDarkModeToggle();
  initLucide();

  const senhaForm = document.getElementById("senhaForm");
  const senhaAtualInput = document.getElementById("senhaAtual");
  const novaSenhaInput = document.getElementById("novaSenha");
  const confirmarSenhaInput = document.getElementById("confirmarSenha");
  const senhaMensagem = document.getElementById("senhaMensagem");
  const salvarSenhaBtn = document.getElementById("salvarSenhaBtn");
  const logoutBtn = document.getElementById("logoutBtn");

  function definirMensagem(texto, tipo, titulo) {
    senhaMensagem.classList.remove("hidden", "erro", "sucesso", "info");

    const icone =
      tipo === "sucesso" ? "check-circle-2" : tipo === "erro" ? "alert-circle" : "info";

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

  logoutBtn?.addEventListener("click", () => {
    logout();
  });

  senhaForm?.addEventListener("submit", async (event) => {
    event.preventDefault();
    esconderMensagem();

    const senhaAtual = senhaAtualInput.value.trim();
    const novaSenha = novaSenhaInput.value.trim();
    const confirmarSenha = confirmarSenhaInput.value.trim();

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

    salvarSenhaBtn.disabled = true;

    try {
      const data = await updatePassword(senhaAtual, novaSenha);
      mostrarSucesso(data.message || "Senha atualizada com sucesso!");
      senhaForm.reset();
    } catch (error) {
      if (handleAuthError(error, (msg) => mostrarErro(msg))) return;
      mostrarErro(
        error instanceof ApiError ? error.message : "Erro ao atualizar a senha."
      );
    } finally {
      salvarSenhaBtn.disabled = false;
    }
  });
}
