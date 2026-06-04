/** Configuração central do front-end Pace */

/**
 * API no mesmo host do front (localhost ↔ localhost, 127.0.0.1 ↔ 127.0.0.1).
 * Necessário para cookies HttpOnly entre portas 5500 (front) e 8000 (API).
 */
export const API_BASE_URL =
  (typeof window !== "undefined" && window.location?.hostname
    ? `http://${window.location.hostname}:8000`
    : null) || "http://127.0.0.1:8000";

export const STORAGE_KEYS = {
  user: "usuarioLogado",
  usersCache: "usuarios",
  darkMode: "darkMode",
  perfilStats: "perfilStatsCache",
};

/** Páginas relativas à pasta Html/ */
export const LOGIN_PAGE = "entrar.html";
export const FEED_PAGE = "feed.html";

export const AVATAR_PLACEHOLDER = "../Images/avatar-placeholder.svg";
