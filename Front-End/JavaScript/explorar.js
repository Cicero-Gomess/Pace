import { initAppShell } from "./shared/app-shell.js";
import { isAuthenticated } from "./shared/auth.js";
import { initLucide } from "./shared/ui.js";
import {
  escaparHTML,
  normalizarTexto,
  formatarDataRelativa,
} from "./shared/utils.js";
import { AVATAR_PLACEHOLDER } from "./shared/config.js";
import { getUsersCache } from "./shared/users-cache.js";
import { searchProfiles } from "./shared/services/profile-service.js";
import { apiFetch } from "./shared/api.js";

await initAppShell({ requireLogin: false });

const fallbackProfiles = [
  {
    nome: "Lara Mendes",
    username: "@laradisciplina",
    bio: "Transformando rotina em resultado com constância.",
    avatar: AVATAR_PLACEHOLDER,
    tags: ["Disciplina", "Mindset"],
  },
];

let profilesData = [];
let modalPostsCache = [];

function buildProfileFromAPI(user) {
  const rawUsername = user.username || "Perfil Pace";
  const withoutAt = rawUsername.replace(/^@/, "");

  return {
    id: user.id,
    nome: withoutAt,
    username: `@${withoutAt}`,
    bio: user.email ? user.email : "Perfil no Pace",
    avatar: user.foto_perfil || AVATAR_PLACEHOLDER,
    tags: [],
  };
}

function loadSavedProfiles() {
  const savedUsers = getUsersCache();

  return Object.entries(savedUsers).map(([username, data]) => {
    const clean = username.replace(/^@/, "");

    return {
      nome: clean,
      username: `@${clean}`,
      bio: data.bio || data.email || "Perfil salvo localmente",
      avatar: data.foto || data.foto_perfil || AVATAR_PLACEHOLDER,
      tags: [],
    };
  });
}

async function fetchProfiles(query = "") {
  try {
    const data = await searchProfiles({ username: query });

    if (Array.isArray(data) && data.length) {
      profilesData = data.map(buildProfileFromAPI);
      return;
    }

    profilesData = loadSavedProfiles();
    if (!profilesData.length) profilesData = fallbackProfiles;
  } catch (error) {
    console.error("Erro ao buscar perfis:", error);
    profilesData = loadSavedProfiles();
    if (!profilesData.length) profilesData = fallbackProfiles;
  }
}

const profilesGrid = document.getElementById("profilesGrid");
const searchInput = document.getElementById("searchInput");
const chips = document.querySelectorAll(".chip");
const profileModal = document.getElementById("profileModal");
const closeProfileModal = document.getElementById("closeProfileModal");

let filtroAtual = "todos";
let termoAtual = "";

function combinarBusca(...campos) {
  return normalizarTexto(campos.join(" "));
}

function profileMatch(profile) {
  const base = combinarBusca(
    profile.nome,
    profile.username,
    profile.bio,
    profile.tags.join(" ")
  );

  const termoOk = !termoAtual || base.includes(normalizarTexto(termoAtual));
  const filtroOk =
    filtroAtual === "todos" ||
    profile.tags.some((tag) =>
      normalizarTexto(tag).includes(normalizarTexto(filtroAtual))
    ) ||
    base.includes(normalizarTexto(filtroAtual));

  return termoOk && filtroOk;
}

function renderEmpty(container, titulo, descricao) {
  container.innerHTML = `
    <div class="empty-state">
      <i data-lucide="search-x"></i>
      <h3>${escaparHTML(titulo)}</h3>
      <p>${escaparHTML(descricao)}</p>
    </div>
  `;

  initLucide();
}

async function fetchUserPosts(profile) {
  if (!isAuthenticated()) return null;

  try {
    const data = await apiFetch("/post/feed", {
      auth: true,
      fallbackMessage: "Falha ao carregar posts.",
    });

    if (!Array.isArray(data)) return [];

    const requestedUsername = String(profile.username)
      .replace(/^@/, "")
      .toLowerCase();

    return data.filter((post) => {
      const postUserId = String(post.usuario?.id ?? "");
      const postUsername = String(post.usuario?.username ?? "").toLowerCase();

      return (
        postUserId === String(profile.id) ||
        postUsername === requestedUsername
      );
    });
  } catch {
    return null;
  }
}

function normalizarPostModal(post) {
  return {
    ...post,
    id: Number(post.id),
    likes: Number(post.likes ?? 0),
    liked: post.liked === true,
  };
}

function atualizarBotaoLikeModal(post) {
  const button = document.querySelector(
    `.modal-like-btn[data-post-id="${post.id}"]`
  );

  if (!button) return;

  button.classList.toggle("liked", post.liked);
  button.innerHTML = `
    <i data-lucide="heart"></i>
    <span>${post.likes}</span>
  `;

  initLucide();
}

async function curtirPostModal(postId) {
  if (!isAuthenticated()) {
    alert("Faça login para curtir posts.");
    return;
  }

  const post = modalPostsCache.find((item) => item.id === Number(postId));
  if (!post) return;

  const likedAntes = post.liked;
  const likesAntes = post.likes;

  post.liked = !likedAntes;
  post.likes = likedAntes ? Math.max(0, likesAntes - 1) : likesAntes + 1;
  atualizarBotaoLikeModal(post);

  try {
    await apiFetch(
      likedAntes
        ? `/post/remover_curtida/${post.id}`
        : `/post/curtir/${post.id}`,
      {
        method: likedAntes ? "DELETE" : "POST",
        auth: true,
        fallbackMessage: "Erro ao curtir post.",
      }
    );
  } catch (error) {
    post.liked = likedAntes;
    post.likes = likesAntes;
    atualizarBotaoLikeModal(post);
    alert(error.message || "Erro ao curtir post.");
  }
}

function attachModalLikeButtons() {
  document.querySelectorAll(".modal-like-btn").forEach((button) => {
    button.addEventListener("click", () => {
      curtirPostModal(button.dataset.postId);
    });
  });
}

function attachProfileButtons() {
  document.querySelectorAll(".profile-btn").forEach((button) => {
    button.addEventListener("click", async () => {
      const username = button.dataset.profileUsername;
      const profile = profilesData.find((item) => item.username === username);

      if (profile) await openProfileModal(profile);
    });
  });
}

async function openProfileModal(profile) {
  if (!profileModal) return;

  const body = profileModal.querySelector(".modal-body");
  if (!body) return;

  body.innerHTML = `
    <div class="modal-header">
      <img class="modal-avatar" src="${escaparHTML(profile.avatar)}" alt="">
      <div class="modal-meta">
        <h2>${escaparHTML(profile.nome)}</h2>
        <p>${escaparHTML(profile.username)}</p>
        <p>${escaparHTML(profile.bio)}</p>
      </div>
    </div>

    <div class="modal-section">
      <h3>Postagens</h3>
      <div class="modal-posts">
        <div class="modal-loading">Carregando...</div>
      </div>
    </div>
  `;

  profileModal.classList.remove("hidden");
  document.body.classList.add("modal-open");
  initLucide();

  const posts = await fetchUserPosts(profile);
  const postsContainer = body.querySelector(".modal-posts");

  if (!postsContainer) return;

  if (posts === null) {
    postsContainer.innerHTML = `
      <div class="modal-empty">Faça login para ver as postagens.</div>
    `;
    return;
  }

  if (!posts.length) {
    postsContainer.innerHTML = `
      <div class="modal-empty">Nenhuma postagem encontrada.</div>
    `;
    return;
  }

  modalPostsCache = posts.map(normalizarPostModal);

  postsContainer.innerHTML = modalPostsCache
    .map((post) => {
      const content = post.conteudo || "Sem descrição";
      const dataFmt = post.data_postagem
        ? formatarDataRelativa(post.data_postagem)
        : "";

      return `
        <article class="modal-post-card">
          <h4>${escaparHTML(content.substring(0, 120))}${
            content.length > 120 ? "..." : ""
          }</h4>

          <p>${escaparHTML(content)}</p>

          ${
            post.imagem
              ? `<img src="${escaparHTML(post.imagem)}" alt="" class="modal-post-image">`
              : ""
          }

          <div class="modal-post-meta">
            <span>${escaparHTML(dataFmt)}</span>

            <button
              type="button"
              class="modal-like-btn ${post.liked ? "liked" : ""}"
              data-post-id="${post.id}"
            >
              <i data-lucide="heart"></i>
              <span>${post.likes}</span>
            </button>
          </div>
        </article>
      `;
    })
    .join("");

  initLucide();
  attachModalLikeButtons();
}

async function renderProfiles() {
  profilesGrid.innerHTML = `
    <div class="empty-state loading-state">
      <i data-lucide="refresh-cw"></i>
      <h3>Buscando perfis</h3>
      <p>Aguarde um momento...</p>
    </div>
  `;

  initLucide();

  await fetchProfiles(termoAtual);
  const filtrados = profilesData.filter(profileMatch);

  if (!filtrados.length) {
    renderEmpty(
      profilesGrid,
      "Nenhum perfil encontrado",
      "Tente outro termo ou filtro."
    );
    return;
  }

  profilesGrid.innerHTML = filtrados
    .map(
      (profile, index) => `
        <article class="profile-card" style="animation-delay:${0.04 + index * 0.04}s">
          <div class="profile-topo">
            <img src="${escaparHTML(profile.avatar)}" alt="" class="profile-avatar">
            <div>
              <h3 class="profile-nome">${escaparHTML(profile.nome)}</h3>
              <p class="profile-user">${escaparHTML(profile.username)}</p>
            </div>
          </div>

          <p class="profile-bio">${escaparHTML(profile.bio)}</p>

          <div class="profile-stats">
            ${profile.tags
              .map((tag) => `<span class="profile-pill">${escaparHTML(tag)}</span>`)
              .join("")}
          </div>

          <button
            class="profile-btn"
            data-profile-username="${escaparHTML(profile.username)}"
          >
            Ver perfil
          </button>
        </article>
      `
    )
    .join("");

  initLucide();
  attachProfileButtons();
}

closeProfileModal?.addEventListener("click", () => {
  profileModal?.classList.add("hidden");
  document.body.classList.remove("modal-open");
});

profileModal?.addEventListener("click", (event) => {
  if (event.target === profileModal) {
    profileModal.classList.add("hidden");
    document.body.classList.remove("modal-open");
  }
});

searchInput?.addEventListener("input", async (event) => {
  termoAtual = event.target.value.trim();
  await renderProfiles();
});

chips.forEach((chip) => {
  chip.addEventListener("click", async () => {
    chips.forEach((btn) => btn.classList.remove("active"));
    chip.classList.add("active");
    filtroAtual = chip.dataset.filter;
    await renderProfiles();
  });
});

renderProfiles();