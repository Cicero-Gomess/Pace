import { apiFetch } from "../api.js";

export async function fetchCurrentProfile() {
  return apiFetch("/profile/me", {
    auth: true,
    fallbackMessage: "Erro ao buscar usuário.",
  });
}

export async function updateProfilePhoto(fotoUrl) {
  return apiFetch("/profile/trocar_foto", {
    method: "POST",
    auth: true,
    body: { foto_url: fotoUrl },
    fallbackMessage: "Erro ao atualizar foto.",
  });
}

export async function searchProfiles({ username = "", skip = 0, limit = 100 } = {}) {
  let path = `/profile/buscar_por_username/?skip=${skip}&limit=${limit}`;
  if (username.trim()) {
    path += `&username=${encodeURIComponent(username.trim())}`;
  }

  return apiFetch(path, {
    auth: "optional",
    fallbackMessage: "Falha ao buscar perfis.",
  });
}
