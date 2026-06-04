import { STORAGE_KEYS, AVATAR_PLACEHOLDER } from "./config.js";
import { getCurrentUser } from "./auth.js";
import { resolveUserPhoto } from "./users-cache.js";

export function initDarkMode() {
  if (localStorage.getItem(STORAGE_KEYS.darkMode) === "true") {
    document.body.classList.add("dark");
  }
}

export function initDarkModeToggle(toggleId = "darkModeToggle") {
  const toggle = document.getElementById(toggleId);
  if (!toggle) return;

  toggle.checked = localStorage.getItem(STORAGE_KEYS.darkMode) === "true";

  toggle.addEventListener("change", () => {
    const ativado = toggle.checked;
    document.body.classList.toggle("dark", ativado);
    localStorage.setItem(STORAGE_KEYS.darkMode, String(ativado));
  });
}

export function initLucide() {
  if (typeof lucide !== "undefined") {
    lucide.createIcons();
  }
}

export function syncProfilePhotos() {
  const user = getCurrentUser();
  if (!user) return;

  const foto = resolveUserPhoto(user);

  document.querySelectorAll(".foto-perfil").forEach((img) => {
    img.src = foto;
  });

  const fotoAutor = document.getElementById("fotoAutor");
  if (fotoAutor) fotoAutor.src = foto;
}

export function initSidebarPhoto(elementId = "fotoSidebar") {
  const el = document.getElementById(elementId);
  const user = getCurrentUser();
  if (!el || !user) return;

  el.src = resolveUserPhoto(user);
}

export function updateSidebarPhoto(user) {
  const el = document.getElementById("fotoSidebar");
  if (!el || !user) return;
  el.src = resolveUserPhoto(user);
}

function garantirToast() {
  let toast = document.getElementById("toast");

  if (!toast) {
    toast = document.createElement("div");
    toast.id = "toast";
    toast.className = "toast hidden";
    document.body.appendChild(toast);
  }

  return toast;
}

export function showToast(mensagem, tipo = "success") {
  const toast = garantirToast();

  toast.textContent = mensagem;
  toast.className = `toast ${tipo}`;
  toast.classList.remove("hidden");

  requestAnimationFrame(() => {
    toast.classList.add("show");
  });

  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => {
    toast.classList.remove("show");
    setTimeout(() => {
      toast.className = "toast hidden";
    }, 250);
  }, 2600);
}

export function setFormMessage(element, texto, tipo = "erro") {
  if (!element) return;

  element.innerText = texto;
  element.style.color =
    tipo === "sucesso" ? "green" : tipo === "info" ? "#555" : "red";
}
