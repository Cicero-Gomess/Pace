import { ensureAuth, checkSession } from "./auth.js";
import {
  initDarkMode,
  initDarkModeToggle,
  initLucide,
  initSidebarPhoto,
  syncProfilePhotos,
} from "./ui.js";

/**
 * Inicialização comum das páginas autenticadas (sidebar, tema, fotos).
 */
export async function initAppShell({ requireLogin = true } = {}) {
  initDarkMode();
  initLucide();

  if (requireLogin) {
    const ok = await ensureAuth();
    if (!ok) return false;
  } else {
    await checkSession();
  }

  syncProfilePhotos();
  initSidebarPhoto();
  return true;
}

export { initDarkModeToggle };
