import { STORAGE_KEYS, LOGIN_PAGE } from "./config.js";
import { apiFetch, isAuthError } from "./api.js";

let sessionActive = false;

/** Limpa tokens legados (migração localStorage/sessionStorage → cookie HttpOnly) */
function clearLegacyTokens() {
  sessionStorage.removeItem("pace_token");
  localStorage.removeItem("token");
}

clearLegacyTokens();

export function getCurrentUser() {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.user);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function saveCurrentUser(user) {
  localStorage.setItem(STORAGE_KEYS.user, JSON.stringify(user));
}

export function isAuthenticated() {
  return sessionActive;
}

export function clearSession() {
  sessionActive = false;
  clearLegacyTokens();
  localStorage.removeItem(STORAGE_KEYS.user);
  localStorage.removeItem("logado");
  localStorage.removeItem("usuario");
  localStorage.removeItem("usuarioNome");
}

/**
 * Valida sessão com o servidor (cookie HttpOnly).
 * @returns {Promise<object|null>} dados do usuário ou null
 */
export async function checkSession() {
  try {
    const user = await apiFetch("/auth/me", {
      auth: true,
      fallbackMessage: "Sessão inválida.",
    });

    sessionActive = true;
    saveCurrentUser({
      id: user.id,
      username: user.username,
      email: user.email,
      foto: user.foto_perfil || null,
      foto_perfil: user.foto_perfil || null,
    });

    return user;
  } catch {
    sessionActive = false;
    return null;
  }
}

export async function ensureAuth() {
  const user = await checkSession();
  if (!user) {
    clearSession();
    window.location.href = LOGIN_PAGE;
    return false;
  }
  return true;
}

export async function logout() {
  try {
    await apiFetch("/auth/logout", {
      method: "POST",
      auth: true,
      fallbackMessage: "Erro ao sair.",
    });
  } catch {
    // Mesmo com falha na API, limpa estado local
  }
  clearSession();
  window.location.href = LOGIN_PAGE;
}

export async function redirectIfAuthenticated(target = "feed.html") {
  const user = await checkSession();
  if (user) {
    window.location.href = target;
  }
}

export function handleAuthError(error, onToast) {
  if (!isAuthError(error)) return false;

  sessionActive = false;

  if (typeof onToast === "function") {
    onToast(error.message, "error");
  }

  setTimeout(() => {
    clearSession();
    window.location.href = LOGIN_PAGE;
  }, 1000);

  return true;
}

export async function login(username, password) {
  const body = new URLSearchParams({
    username,
    password,
  });

  await apiFetch("/auth/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString(),
    fallbackMessage: "Erro ao fazer login.",
  });

  const user = await checkSession();
  if (!user) {
    throw new Error("Login realizado, mas não foi possível validar a sessão.");
  }

  return user;
}

export async function register({ username, email, senha }) {
  return apiFetch("/auth/criar_usuario", {
    method: "POST",
    body: { username, email, senha },
    fallbackMessage: "Erro ao cadastrar.",
  });
}

export async function updatePassword(senhaAtual, novaSenha) {
  return apiFetch("/auth/atualizar_senha", {
    method: "PUT",
    auth: true,
    body: { senha_atual: senhaAtual, nova_senha: novaSenha },
    fallbackMessage: "Erro ao atualizar a senha.",
  });
}
