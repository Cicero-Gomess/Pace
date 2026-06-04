import { API_BASE_URL } from "./config.js";

export const AUTH_ERROR = "AUTH_401";

export class ApiError extends Error {
  constructor(message, { status = 0, code = null, isNetwork = false } = {}) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.isNetwork = isNetwork;
  }
}

function formatDetail(detail) {
  if (!detail) return null;
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail)) {
    return detail
      .map((item) => item.msg || item.message || JSON.stringify(item))
      .join(". ");
  }
  return String(detail);
}

export async function parseResponse(response, fallbackMessage = "Erro na requisição.") {
  const contentType = response.headers.get("content-type") || "";
  let data = null;

  if (contentType.includes("application/json")) {
    try {
      data = await response.json();
    } catch {
      data = null;
    }
  } else {
    try {
      const text = await response.text();
      data = text ? { detail: text } : null;
    } catch {
      data = null;
    }
  }

  if (!response.ok) {
    if (response.status === 401) {
      throw new ApiError("Sessão expirada. Faça login novamente.", {
        status: 401,
        code: AUTH_ERROR,
      });
    }

    throw new ApiError(formatDetail(data?.detail) || fallbackMessage, {
      status: response.status,
    });
  }

  return data;
}

/**
 * Cliente HTTP único. Autenticação web via cookie HttpOnly (credentials: include).
 * @param {string} path
 * @param {object} options
 * @param {boolean|string} [options.auth=false] - true: exige sessão | "optional": envia cookie se existir
 */
export async function apiFetch(path, options = {}) {
  const {
    auth = false,
    fallbackMessage = "Erro na requisição.",
    headers: extraHeaders = {},
    body,
    method = "GET",
    ...rest
  } = options;

  const headers = { ...extraHeaders };

  if (body !== undefined && !(body instanceof FormData) && !headers["Content-Type"]) {
    headers["Content-Type"] = "application/json";
  }

  const url = path.startsWith("http") ? path : `${API_BASE_URL}${path}`;

  const fetchOptions = {
    method,
    headers,
    credentials: "include",
    body:
      body !== undefined && headers["Content-Type"] === "application/json" && typeof body !== "string"
        ? JSON.stringify(body)
        : body,
    ...rest,
  };

  // Garante cookie HttpOnly mesmo quando options.credentials não é passado
  fetchOptions.credentials = "include";

  let response;
  try {
    response = await fetch(url, fetchOptions);
  } catch {
    throw new ApiError("Sem conexão com o servidor. Verifique sua internet.", {
      isNetwork: true,
    });
  }

  return parseResponse(response, fallbackMessage);
}

export function isAuthError(error) {
  return error instanceof ApiError && error.code === AUTH_ERROR;
}
