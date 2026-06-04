import { register } from "./shared/auth.js";
import { setFormMessage } from "./shared/ui.js";
import { ApiError } from "./shared/api.js";

const formCadastro = document.getElementById("cadastroForm");

if (formCadastro) {
  formCadastro.addEventListener("submit", async (e) => {
    e.preventDefault();

    const usuario = document.getElementById("cadastroUsuario").value.trim();
    const email = document.getElementById("cadastroEmail").value.trim();
    const senha = document.getElementById("cadastroSenha").value;
    const confirmar = document.getElementById("cadastroConfirmarSenha").value;
    const mensagem = document.getElementById("cadastroMensagem");

    if (!usuario || !email || !senha || !confirmar) {
      setFormMessage(mensagem, "Preencha todos os campos.");
      return;
    }

    if (senha.length < 6) {
      setFormMessage(mensagem, "A senha precisa ter pelo menos 6 caracteres.");
      return;
    }

    if (senha !== confirmar) {
      setFormMessage(mensagem, "As senhas não coincidem!");
      return;
    }

    try {
      await register({ username: usuario, email, senha });
      setFormMessage(mensagem, "Cadastro realizado com sucesso!", "sucesso");

      setTimeout(() => {
        window.location.href = "entrar.html";
      }, 1000);
    } catch (error) {
      const texto =
        error instanceof ApiError ? error.message : error?.detail || "Erro ao cadastrar.";
      setFormMessage(mensagem, texto);
    }
  });
}
