import {
  login,
  redirectIfAuthenticated
} from "./shared/auth.js";

import {
  setFormMessage
} from "./shared/ui.js";

import {
  ApiError
} from "./shared/api.js";


/* =========================================================
   CONFIGURAÇÕES
========================================================= */

const REMEMBER_EMAIL_KEY = "pace_login_email";
const REMEMBER_ENABLED_KEY = "pace_login_remember";


/* =========================================================
   ELEMENTOS
========================================================= */

const formLogin =
  document.getElementById("loginForm");

const mensagem =
  document.getElementById("loginMensagem");

const emailInput =
  document.getElementById("loginEmail");

const senhaInput =
  document.getElementById("loginSenha");

const lembrarUsuario =
  document.getElementById("lembrarUsuario");

const forgotPasswordButton =
  document.getElementById("forgotPasswordButton");

const recoveryModal =
  document.getElementById("forgotPasswordModal");

const recoveryClose =
  document.getElementById("recoveryClose");

const recoveryEmail =
  document.getElementById("recoveryEmail");

const recoverySubmit =
  document.getElementById("recoverySubmit");

const recoveryMessage =
  document.getElementById("recoveryMessage");


/* =========================================================
   VERIFICA SESSÃO EXISTENTE
========================================================= */

redirectIfAuthenticated();


/* =========================================================
   LEMBRAR DE MIM
========================================================= */

function carregarLoginLembrado() {
  if (!emailInput || !lembrarUsuario) return;

  const lembrar =
    localStorage.getItem(REMEMBER_ENABLED_KEY) === "true";

  const emailSalvo =
    localStorage.getItem(REMEMBER_EMAIL_KEY);

  if (lembrar && emailSalvo) {
    emailInput.value = emailSalvo;
    lembrarUsuario.checked = true;
  }
}


function salvarPreferenciaLogin() {
  if (!emailInput || !lembrarUsuario) return;

  if (lembrarUsuario.checked) {
    localStorage.setItem(
      REMEMBER_EMAIL_KEY,
      emailInput.value.trim()
    );

    localStorage.setItem(
      REMEMBER_ENABLED_KEY,
      "true"
    );

    return;
  }

  localStorage.removeItem(REMEMBER_EMAIL_KEY);
  localStorage.removeItem(REMEMBER_ENABLED_KEY);
}


function limparLoginLembradoSeNecessario() {
  if (!lembrarUsuario) return;

  if (!lembrarUsuario.checked) {
    localStorage.removeItem(REMEMBER_EMAIL_KEY);
    localStorage.removeItem(REMEMBER_ENABLED_KEY);
  }
}


carregarLoginLembrado();


lembrarUsuario?.addEventListener(
  "change",
  limparLoginLembradoSeNecessario
);


/* =========================================================
   LOGIN
========================================================= */

if (formLogin) {
  formLogin.addEventListener("submit", async (e) => {
    e.preventDefault();

    const usuario =
      emailInput?.value.trim() || "";

    const senha =
      senhaInput?.value || "";

    if (!usuario || !senha) {
      setFormMessage(
        mensagem,
        "Preencha todos os campos."
      );

      return;
    }

    const submitButton =
      formLogin.querySelector(".login-submit");

    try {
      if (submitButton) {
        submitButton.disabled = true;
        submitButton.classList.add("is-loading");

        submitButton.querySelector("span:first-child").textContent =
          "Entrando...";
      }

      setFormMessage(mensagem, "");

      await login(usuario, senha);

      salvarPreferenciaLogin();

      setFormMessage(
        mensagem,
        "Login realizado com sucesso!",
        "sucesso"
      );

      setTimeout(() => {
        window.location.href = "feed.html";
      }, 500);

    } catch (error) {
      const texto =
        error instanceof ApiError
          ? error.message
          : error?.detail ||
            error?.message ||
            "Erro ao fazer login.";

      setFormMessage(
        mensagem,
        texto
      );

    } finally {
      if (submitButton) {
        submitButton.disabled = false;
        submitButton.classList.remove("is-loading");

        submitButton.querySelector("span:first-child").textContent =
          "Entrar";
      }
    }
  });
}


/* =========================================================
   MODAL — ESQUECI MINHA SENHA
========================================================= */

function abrirRecoveryModal() {
  if (!recoveryModal) return;

  recoveryModal.classList.add("is-open");
  recoveryModal.setAttribute(
    "aria-hidden",
    "false"
  );

  document.body.classList.add(
    "modal-open"
  );

  if (recoveryEmail) {
    recoveryEmail.value =
      emailInput?.value.trim() || "";

    setTimeout(() => {
      recoveryEmail.focus();
    }, 100);
  }

  if (recoveryMessage) {
    recoveryMessage.textContent = "";
    recoveryMessage.className =
      "recovery-message";
  }
}


function fecharRecoveryModal() {
  if (!recoveryModal) return;

  recoveryModal.classList.remove("is-open");

  recoveryModal.setAttribute(
    "aria-hidden",
    "true"
  );

  document.body.classList.remove(
    "modal-open"
  );

  forgotPasswordButton?.focus();
}


forgotPasswordButton?.addEventListener(
  "click",
  abrirRecoveryModal
);


recoveryClose?.addEventListener(
  "click",
  fecharRecoveryModal
);


recoveryModal
  ?.querySelector("[data-close-recovery]")
  ?.addEventListener(
    "click",
    fecharRecoveryModal
  );


document.addEventListener(
  "keydown",
  (event) => {
    if (
      event.key === "Escape" &&
      recoveryModal?.classList.contains("is-open")
    ) {
      fecharRecoveryModal();
    }
  }
);


/* =========================================================
   RECUPERAÇÃO DE SENHA
========================================================= */

function emailValido(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}


async function solicitarRecuperacao() {
  if (!recoveryEmail || !recoveryMessage) {
    return;
  }

  const email =
    recoveryEmail.value.trim();

  recoveryMessage.className =
    "recovery-message";

  if (!email) {
    recoveryMessage.textContent =
      "Informe o email cadastrado.";

    recoveryMessage.classList.add(
      "error"
    );

    recoveryEmail.focus();

    return;
  }

  if (!emailValido(email)) {
    recoveryMessage.textContent =
      "Digite um email válido.";

    recoveryMessage.classList.add(
      "error"
    );

    recoveryEmail.focus();

    return;
  }

  /*
   * IMPORTANTE:
   *
   * O backend atual enviado não possui uma rota
   * de recuperação de senha.
   *
   * Quando existir algo como:
   *
   * POST /auth/esqueci_senha
   *
   * substituímos este bloco pela chamada da API.
   */

  recoveryMessage.textContent =
    "A recuperação automática de senha ainda não está disponível. Entre em contato com o responsável pelo sistema para recuperar seu acesso.";

  recoveryMessage.classList.add(
    "info"
  );
}


recoverySubmit?.addEventListener(
  "click",
  solicitarRecuperacao
);


recoveryEmail?.addEventListener(
  "keydown",
  (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      solicitarRecuperacao();
    }
  }
);