import { AVATAR_PLACEHOLDER, STORAGE_KEYS } from "./config.js";

export function getUsersCache() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEYS.usersCache)) || {};
  } catch {
    return {};
  }
}

export function saveUsersCache(cache) {
  localStorage.setItem(STORAGE_KEYS.usersCache, JSON.stringify(cache));
}

export function upsertUserCache(username, data) {
  const cache = getUsersCache();
  cache[username] = { ...cache[username], ...data, username };
  saveUsersCache(cache);
  return cache;
}

export function resolveUserPhoto(user) {
  if (!user) return AVATAR_PLACEHOLDER;

  const cache = getUsersCache();
  const cached = user.username ? cache[user.username] : null;

  return (
    user.foto_perfil ||
    user.foto ||
    cached?.foto ||
    cached?.foto_perfil ||
    AVATAR_PLACEHOLDER
  );
}
