import { login, redirectIfAuthenticated } from "./shared/auth.js";
import { setFormMessage } from "./shared/ui.js";
import { ApiError } from "./shared/api.js";

redirectIfAuthenticated();

const formLogin = document.getElementById("loginForm");
const mensagem = document.getElementById("loginMensagem");

if (formLogin) {
  formLogin.addEventListener("submit", async (e) => {
    e.preventDefault();

    const usuario = document.getElementById("loginEmail").value.trim();
    const senha = document.getElementById("loginSenha").value.trim();

    if (!usuario || !senha) {
      setFormMessage(mensagem, "Preencha todos os campos.");
      return;
    }

    try {
      await login(usuario, senha);
      setFormMessage(mensagem, "Login realizado com sucesso!", "sucesso");

      setTimeout(() => {
        window.location.href = "feed.html";
      }, 800);
    } catch (error) {
      const texto =
        error instanceof ApiError
          ? error.message
          : error?.detail || "Erro ao fazer login.";
      setFormMessage(mensagem, texto);
    }
  });
}
