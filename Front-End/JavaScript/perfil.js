/* ===== DARK MODE ===== */
const darkMode = localStorage.getItem("darkMode");
if (darkMode === "true") {
  document.body.classList.add("dark");
}

lucide.createIcons();

/* ===== API ===== */
const API_URL = "http://127.0.0.1:8000";
const PERFIL_STATS_CACHE_KEY = "perfilStatsCache";

/* ===== USUARIO ===== */
let usuario = JSON.parse(localStorage.getItem("usuarioLogado"));

if (!usuario) {
  alert("Voce precisa estar logado.");
  window.location.href = "login.html";
}

/* ===== ELEMENTOS ===== */
const nomeEl = document.getElementById("nomeUsuario");
const emailEl = document.getElementById("emailUsuario");
const fotoEl = document.getElementById("fotoPerfil");
const inputFoto = document.getElementById("inputFoto");
const bioInput = document.getElementById("bioUsuario");
const btnSalvarBio = document.getElementById("salvarBio");

const modal = document.getElementById("modalPost");
const modalImg = document.getElementById("modalImg");
const modalTexto = document.getElementById("modalTexto");
const modalLikes = document.getElementById("modalLikes");
const modalComentarios = document.getElementById("modalComentarios");
const fecharModal = document.getElementById("fecharModal");

/* ===== TOAST ===== */
function mostrarToast(mensagem, tipo = "success") {
  const toast = document.getElementById("toast");
  if (!toast) return;

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
    }, 280);
  }, 2500);
}

/* ===== HELPERS ===== */
function getToken() {
  return localStorage.getItem("token");
}

function tratarErroAuth(error) {
  if (error.message === "AUTH_401") {
    mostrarToast("Sessao expirada. Faca login novamente.", "error");
    localStorage.removeItem("token");
    localStorage.removeItem("usuarioLogado");

    setTimeout(() => {
      window.location.href = "login.html";
    }, 1000);

    return true;
  }

  return false;
}

async function parseResponse(response, fallbackMessage) {
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
      throw new Error("AUTH_401");
    }

    throw new Error(data?.detail || fallbackMessage);
  }

  return data;
}

function formatarData(dataISO) {
  if (!dataISO) return "";

  const data = new Date(dataISO);
  if (Number.isNaN(data.getTime())) return "";

  return data.toLocaleDateString("pt-BR", {
    day: "2-digit",
    month: "short",
    year: "numeric"
  });
}

function escaparHTML(valor) {
  return String(valor ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function normalizarComentario(comentario) {
  return {
    id: comentario.id,
    texto: comentario.conteudo ?? comentario.texto ?? comentario.comentario ?? "",
    userId: comentario.usuario?.id ?? comentario.usuario_id ?? null,
    username: comentario.usuario?.username ?? comentario.username ?? "Usuario",
    foto: comentario.usuario?.foto_perfil ?? comentario.foto_perfil ?? "../Images/image.person.png"
  };
}

function atualizarFotoGlobal() {
  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const userData = usuarios[user.username];

  const foto =
    user.foto_perfil ||
    user.foto ||
    userData?.foto ||
    "../Images/image.person.png";

  document.querySelectorAll(".foto-perfil").forEach((img) => {
    if (img.getAttribute("src") !== foto) {
      img.src = foto;
    }
  });

  if (fotoEl && fotoEl.getAttribute("src") !== foto) {
    fotoEl.src = foto;
  }
}

/* ===== PREENCHER PERFIL ===== */
function preencherDadosPerfil() {
  if (!usuario) return;

  if (nomeEl) nomeEl.innerText = usuario.username || "";
  if (emailEl) emailEl.innerText = usuario.email || "";

  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};
  if (bioInput) {
    bioInput.value = usuarios[usuario.username]?.bio || "";
  }

  atualizarFotoGlobal();
}

/* ===== SALVAR BIO NO LOCAL STORAGE ===== */
btnSalvarBio?.addEventListener("click", () => {
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  usuarios[usuario.username] = {
    ...usuarios[usuario.username],
    username: usuario.username,
    bio: bioInput.value,
    foto: usuarios[usuario.username]?.foto || usuario.foto_perfil || usuario.foto || ""
  };

  localStorage.setItem("usuarios", JSON.stringify(usuarios));
  mostrarToast("Bio salva com sucesso!", "success");
});

/* ===== API PERFIL ===== */
async function trocarFotoAPI(fotoUrl) {
  const response = await fetch(`${API_URL}/profile/trocar_foto`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${getToken()}`
    },
    body: JSON.stringify({
      foto_url: fotoUrl
    })
  });

  return parseResponse(response, "Erro ao atualizar foto.");
}

async function buscarUsuarioAPI() {
  const response = await fetch(`${API_URL}/profile/me`, {
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  return parseResponse(response, "Erro ao buscar usuario.");
}

/* ===== API POSTS E COMENTARIOS ===== */
async function getPostsAPI() {
  const response = await fetch(`${API_URL}/post/feed`, {
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  const data = await parseResponse(response, "Erro ao buscar posts.");

  return Array.isArray(data)
    ? data.map((post) => ({
        id: post.id,
        userId: post.usuario?.id ?? null,
        nome: post.usuario?.username ?? "Usuario",
        usuario: `@${post.usuario?.username ?? "usuario"}`,
        texto: post.conteudo ?? "",
        imagem: post.imagem ?? "",
        likes: Number(post.likes ?? 0),
        liked: Boolean(post.liked ?? false),
        username: post.usuario?.username ?? "usuario",
        foto: post.usuario?.foto_perfil || "../Images/image.person.png",
        data: post.data_postagem ?? "",
        comentarios: []
      }))
    : [];
}

async function buscarComentariosAPI(postId) {
  const response = await fetch(`${API_URL}/comments/comentarios/${postId}`, {
    headers: {
      Authorization: `Bearer ${getToken()}`
    }
  });

  const data = await parseResponse(response, "Erro ao buscar comentarios.");
  return Array.isArray(data) ? data.map(normalizarComentario) : [];
}

/* ===== COMPACTAR IMAGEM ===== */
async function compactarImagem(file, maxWidth = 300, quality = 0.8) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => {
      const img = new Image();

      img.onload = () => {
        const canvas = document.createElement("canvas");
        const scale = Math.min(1, maxWidth / img.width);

        canvas.width = Math.round(img.width * scale);
        canvas.height = Math.round(img.height * scale);

        const ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

        const imagemCompactada = canvas.toDataURL("image/jpeg", quality);
        resolve(imagemCompactada);
      };

      img.onerror = () => reject(new Error("Erro ao processar imagem."));
      img.src = reader.result;
    };

    reader.onerror = () => reject(new Error("Erro ao ler arquivo."));
    reader.readAsDataURL(file);
  });
}

/* ===== TROCAR FOTO ===== */
inputFoto?.addEventListener("change", async () => {
  const file = inputFoto.files?.[0];
  if (!file) return;

  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};
  const userAtual = JSON.parse(localStorage.getItem("usuarioLogado"));

  if (!userAtual) return;

  const fotoAnterior =
    userAtual.foto_perfil ||
    userAtual.foto ||
    usuarios[userAtual.username]?.foto ||
    "../Images/image.person.png";

  try {
    const novaFoto = await compactarImagem(file);
    const resposta = await trocarFotoAPI(novaFoto);

    usuarios[userAtual.username] = {
      ...usuarios[userAtual.username],
      username: userAtual.username,
      foto: resposta.foto_perfil || novaFoto,
      bio: usuarios[userAtual.username]?.bio || ""
    };

    localStorage.setItem("usuarios", JSON.stringify(usuarios));

    userAtual.foto = resposta.foto_perfil || novaFoto;
    userAtual.foto_perfil = resposta.foto_perfil || novaFoto;

    localStorage.setItem("usuarioLogado", JSON.stringify(userAtual));

    usuario = userAtual;
    atualizarFotoGlobal();
    mostrarToast("Foto atualizada com sucesso!", "success");
  } catch (error) {
    console.error("Erro completo ao trocar foto:", error);

    if (fotoEl) {
      fotoEl.src = fotoAnterior;
    }

    if (!tratarErroAuth(error)) {
      mostrarToast(error.message || "Erro ao atualizar foto.", "error");
    }
  } finally {
    inputFoto.value = "";
  }
});

/* ===== CACHE DE STATS ===== */
function carregarStatsCache() {
  const cache = JSON.parse(localStorage.getItem(PERFIL_STATS_CACHE_KEY));

  if (!cache || cache.userId !== usuario.id) return;

  const totalPostsEl = document.getElementById("totalPosts");
  const totalLikesEl = document.getElementById("totalLikes");
  const totalComentariosEl = document.getElementById("totalComentarios");

  if (totalPostsEl) totalPostsEl.innerText = cache.totalPosts ?? 0;
  if (totalLikesEl) totalLikesEl.innerText = cache.totalLikes ?? 0;
  if (totalComentariosEl) totalComentariosEl.innerText = cache.totalComentarios ?? 0;
}

function salvarStatsCache(stats) {
  localStorage.setItem(
    PERFIL_STATS_CACHE_KEY,
    JSON.stringify({
      userId: usuario.id,
      ...stats
    })
  );
}

/* ===== STATS ===== */
async function carregarStatsUsuario(postsUsuario = null) {
  const meusPosts = postsUsuario || [];
  let totalLikes = 0;
  let totalComentarios = 0;

  meusPosts.forEach((post) => {
    totalLikes += post.likes || 0;
    totalComentarios += (post.comentarios || []).length;
  });

  const stats = {
    totalPosts: meusPosts.length,
    totalLikes,
    totalComentarios
  };

  const totalPostsEl = document.getElementById("totalPosts");
  const totalLikesEl = document.getElementById("totalLikes");
  const totalComentariosEl = document.getElementById("totalComentarios");

  if (totalPostsEl) totalPostsEl.innerText = stats.totalPosts;
  if (totalLikesEl) totalLikesEl.innerText = stats.totalLikes;
  if (totalComentariosEl) totalComentariosEl.innerText = stats.totalComentarios;

  salvarStatsCache(stats);
}

/* ===== POSTS ===== */
function abrirModal(post) {
  if (!modal) return;

  if (modalImg) modalImg.src = post.imagem || "";
  if (modalTexto) modalTexto.innerText = post.texto || "";
  if (modalLikes) modalLikes.innerText = post.likes || 0;
  if (modalComentarios) modalComentarios.innerText = (post.comentarios || []).length;

  if (modalImg) {
    modalImg.style.display = post.imagem ? "block" : "none";
  }

  modal.classList.remove("hidden");
}

async function carregarPostsUsuario() {
  const imagensContainer = document.getElementById("postsImagem");
  const textoContainer = document.getElementById("postsTexto");

  if (!imagensContainer || !textoContainer) return [];

  imagensContainer.innerHTML = "";
  textoContainer.innerHTML = "";

  const posts = await getPostsAPI();
  const meusPostsBase = posts.filter((p) => p.userId === usuario.id);

  const meusPosts = await Promise.all(
    meusPostsBase.map(async (post) => {
      try {
        const comentarios = await buscarComentariosAPI(post.id);
        return {
          ...post,
          comentarios
        };
      } catch (error) {
        if (error.message === "AUTH_401") {
          throw error;
        }

        console.error(`Erro ao buscar comentarios do post ${post.id}:`, error);
        return {
          ...post,
          comentarios: []
        };
      }
    })
  );

  meusPosts.forEach((post) => {
    if (post.imagem) {
      const div = document.createElement("div");
      div.classList.add("post-item");

      div.innerHTML = `
        <img src="${escaparHTML(post.imagem)}" alt="Post com imagem">
        <div class="post-overlay">
          ❤️ ${post.likes || 0} • 💬 ${(post.comentarios || []).length}
        </div>
      `;

      div.onclick = () => abrirModal(post);
      imagensContainer.appendChild(div);
    }

    if (post.texto) {
      const div = document.createElement("div");
      div.classList.add("post-texto-card");

      div.innerHTML = `
        <p>${escaparHTML(post.texto)}</p>
        <small>${escaparHTML(formatarData(post.data))} • ❤️ ${post.likes || 0} • 💬 ${(post.comentarios || []).length}</small>
      `;

      div.onclick = () => abrirModal(post);
      textoContainer.appendChild(div);
    }
  });

  return meusPosts;
}

/* ===== MODAL ===== */
if (fecharModal) {
  fecharModal.onclick = () => modal?.classList.add("hidden");
}

if (modal) {
  modal.onclick = (e) => {
    if (e.target === modal) modal.classList.add("hidden");
  };
}

/* ===== INIT ===== */
async function initPerfil() {
  preencherDadosPerfil();
  carregarStatsCache();

  try {
    const userAPI = await buscarUsuarioAPI();

    usuario = userAPI;
    localStorage.setItem("usuarioLogado", JSON.stringify(userAPI));

    const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};
    usuarios[userAPI.username] = {
      ...usuarios[userAPI.username],
      username: userAPI.username,
      foto: userAPI.foto_perfil || userAPI.foto || "",
      bio: usuarios[userAPI.username]?.bio || ""
    };
    localStorage.setItem("usuarios", JSON.stringify(usuarios));

    preencherDadosPerfil();
  } catch (err) {
    console.error("Erro ao carregar usuario:", err);

    if (tratarErroAuth(err)) {
      return;
    }
  }

  try {
    const meusPosts = await carregarPostsUsuario();
    await carregarStatsUsuario(meusPosts);
  } catch (err) {
    console.error("Erro ao carregar perfil:", err);

    if (tratarErroAuth(err)) {
      return;
    }

    mostrarToast(err.message || "Erro ao carregar perfil.", "error");
  }
}

initPerfil();
