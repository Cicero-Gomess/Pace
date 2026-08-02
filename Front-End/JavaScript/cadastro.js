import { register } from "./shared/auth.js";
import { setFormMessage } from "./shared/ui.js";
import { ApiError } from "./shared/api.js";

const formCadastro = document.getElementById("cadastroForm");

const usuarioInput = document.getElementById("cadastroUsuario");
const emailInput = document.getElementById("cadastroEmail");
const senhaInput = document.getElementById("cadastroSenha");
const confirmarSenhaInput = document.getElementById(
  "cadastroConfirmarSenha"
);

const mensagem = document.getElementById("cadastroMensagem");
const submitButton = document.getElementById("cadastroSubmit");

const strengthBar = document.getElementById("strengthBar");
const strengthText = document.getElementById("strengthText");
const passwordMatch = document.getElementById("passwordMatch");

const regrasSenha = {
  length: (senha) => senha.length >= 8,
  uppercase: (senha) => /[A-Z]/.test(senha),
  number: (senha) => /\d/.test(senha),
  symbol: (senha) => /[^A-Za-z0-9]/.test(senha),
};

function alterarEstadoBotao(estado = "normal") {
  if (!submitButton) {
    return;
  }

  submitButton.classList.remove("is-loading", "is-success");
  submitButton.disabled = false;

  if (estado === "loading") {
    submitButton.classList.add("is-loading");
    submitButton.disabled = true;
  }

  if (estado === "success") {
    submitButton.classList.add("is-success");
    submitButton.disabled = true;
  }
}

function atualizarRequisitosSenha(senha) {
  Object.entries(regrasSenha).forEach(([nome, validar]) => {
    const elemento = document.querySelector(
      `[data-rule="${nome}"]`
    );

    if (!elemento) {
      return;
    }

    elemento.classList.toggle("is-valid", validar(senha));
  });
}

function calcularForcaSenha(senha) {
  return Object.values(regrasSenha).filter((validar) =>
    validar(senha)
  ).length;
}

function atualizarForcaSenha() {
  if (!senhaInput || !strengthBar || !strengthText) {
    return;
  }

  const senha = senhaInput.value;
  const pontuacao = calcularForcaSenha(senha);

  atualizarRequisitosSenha(senha);

  const estados = [
    {
      texto: "Muito fraca",
      largura: "0%",
      cor: "#c4cdd9",
    },
    {
      texto: "Fraca",
      largura: "25%",
      cor: "#c84040",
    },
    {
      texto: "Média",
      largura: "50%",
      cor: "#d89032",
    },
    {
      texto: "Boa",
      largura: "75%",
      cor: "#4c8ccf",
    },
    {
      texto: "Forte",
      largura: "100%",
      cor: "#1f9d72",
    },
  ];

  const estadoAtual = estados[pontuacao];

  strengthText.textContent = senha
    ? estadoAtual.texto
    : "Muito fraca";

  strengthText.style.color = senha
    ? estadoAtual.cor
    : "#8b98a9";

  strengthBar.style.width = senha
    ? estadoAtual.largura
    : "0%";

  strengthBar.style.backgroundColor =
    estadoAtual.cor;

  atualizarConfirmacaoSenha();
}

function atualizarConfirmacaoSenha() {
  if (
    !senhaInput ||
    !confirmarSenhaInput ||
    !passwordMatch
  ) {
    return;
  }

  const senha = senhaInput.value;
  const confirmacao = confirmarSenhaInput.value;

  passwordMatch.classList.remove(
    "is-valid",
    "is-invalid"
  );

  confirmarSenhaInput.classList.remove(
    "is-valid",
    "is-invalid"
  );

  if (!confirmacao) {
    passwordMatch.textContent = "";
    return;
  }

  if (senha === confirmacao) {
    passwordMatch.textContent =
      "As senhas coincidem.";

    passwordMatch.classList.add("is-valid");
    confirmarSenhaInput.classList.add("is-valid");
  } else {
    passwordMatch.textContent =
      "As senhas não coincidem.";

    passwordMatch.classList.add("is-invalid");
    confirmarSenhaInput.classList.add("is-invalid");
  }
}

function senhaCumpreRequisitos(senha) {
  return Object.values(regrasSenha).every(
    (validar) => validar(senha)
  );
}

function configurarBotoesDeSenha() {
  const botoes = document.querySelectorAll(
    ".password-toggle"
  );

  botoes.forEach((botao) => {
    botao.addEventListener("click", () => {
      const inputId = botao.dataset.target;
      const input = document.getElementById(inputId);

      if (!input) {
        return;
      }

      const senhaEstaOculta =
        input.type === "password";

      input.type = senhaEstaOculta
        ? "text"
        : "password";

      botao.classList.toggle(
        "is-visible",
        senhaEstaOculta
      );

      botao.setAttribute(
        "aria-pressed",
        String(senhaEstaOculta)
      );

      botao.setAttribute(
        "aria-label",
        senhaEstaOculta
          ? "Ocultar senha"
          : "Mostrar senha"
      );
    });
  });
}

senhaInput?.addEventListener(
  "input",
  atualizarForcaSenha
);

confirmarSenhaInput?.addEventListener(
  "input",
  atualizarConfirmacaoSenha
);

configurarBotoesDeSenha();

if (formCadastro) {
  formCadastro.addEventListener(
    "submit",
    async (evento) => {
      evento.preventDefault();

      const usuario =
        usuarioInput?.value.trim() ?? "";

      const email =
        emailInput?.value.trim() ?? "";

      const senha =
        senhaInput?.value ?? "";

      const confirmarSenha =
        confirmarSenhaInput?.value ?? "";

      alterarEstadoBotao("normal");

      if (
        !usuario ||
        !email ||
        !senha ||
        !confirmarSenha
      ) {
        setFormMessage(
          mensagem,
          "Preencha todos os campos."
        );

        return;
      }

      if (!senhaCumpreRequisitos(senha)) {
        setFormMessage(
          mensagem,
          "A senha precisa cumprir todos os requisitos de segurança."
        );

        senhaInput?.focus();
        return;
      }

      if (senha !== confirmarSenha) {
        setFormMessage(
          mensagem,
          "As senhas não coincidem."
        );

        confirmarSenhaInput?.focus();
        return;
      }

      try {
        alterarEstadoBotao("loading");

        await register({
          username: usuario,
          email,
          senha,
        });

        setFormMessage(
          mensagem,
          "Cadastro realizado com sucesso!",
          "sucesso"
        );

        alterarEstadoBotao("success");

        setTimeout(() => {
          window.location.href = "entrar.html";
        }, 1100);
      } catch (error) {
        alterarEstadoBotao("normal");

        const texto =
          error instanceof ApiError
            ? error.message
            : error?.detail ||
              "Erro ao cadastrar.";

        setFormMessage(mensagem, texto);
      }
    }
  );
}