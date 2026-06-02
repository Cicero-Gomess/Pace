/* ===== FOTO GLOBAL ===== */
(function () {
  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const userData = usuarios[user.username];
  const foto = userData?.foto || user.foto || "../Images/avatar-placeholder.svg";

  document.querySelectorAll(".foto-perfil").forEach(f => {
    f.src = foto;
  });
})();

/* ===== DARK MODE ===== */
const darkMode = localStorage.getItem("darkMode");
if (darkMode === "true") {
  document.body.classList.add("dark");
}

lucide.createIcons();

/* ===== CONFIGURAÇÃO DE API ===== */
const API_URL = "http://127.0.0.1:8000";
let profilesData = [];

const fallbackProfiles = [
  {
    nome: "Lara Mendes",
    username: "@laradisciplina",
    bio: "Transformando rotina em resultado com constância, treino e estudo diário.",
    avatar: "../Images/avatar-placeholder.svg",
    tags: ["Disciplina", "Mindset", "Consistência"]
  },
  {
    nome: "Caio Rocha",
    username: "@caioprodutivo",
    bio: "Foco, deep work e sistemas simples para render mais sem se perder.",
    avatar: "../Images/avatar-placeholder.svg",
    tags: ["Produtividade", "Estudos", "Foco"]
  },
  {
    nome: "Ana Beatriz",
    username: "@anaemmovimento",
    bio: "Academia, energia e pequenos hábitos que melhoram o dia inteiro.",
    avatar: "../Images/avatar-placeholder.svg",
    tags: ["Academia", "Rotina", "Energia"]
  },
  {
    nome: "Rafael Costa",
    username: "@rafamind",
    bio: "Mentalidade forte, clareza e evolução pessoal sem romantizar o caos.",
    avatar: "../Images/avatar-placeholder.svg",
    tags: ["Mindset", "Disciplina", "Clareza"]
  },
  {
    nome: "Julia Alves",
    username: "@juliaestuda",
    bio: "Organização real para quem quer estudar melhor e viver com mais leveza.",
    avatar: "../Images/avatar-placeholder.svg",
    tags: ["Estudos", "Planejamento", "Rotina"]
  },
  {
    nome: "Victor Hugo",
    username: "@victorflow",
    bio: "Construindo hábitos sólidos e compartilhando os bastidores da evolução.",
    avatar: "../Images/avatar-placeholder.svg",
    tags: ["Produtividade", "Mindset", "Hábitos"]
  }
];

function buildProfileFromAPI(user) {
  const rawUsername = user.username || "Perfil Pace";
  const withoutAt = rawUsername.replace(/^@/, "");

  return {
    nome: withoutAt,
    username: `@${withoutAt}`,
    bio: user.email ? user.email : "Perfil criado no Pace",
    avatar: user.foto_perfil || "../Images/avatar-placeholder.svg",
    tags: []
  };
}

function loadSavedProfiles() {
  const savedUsers = JSON.parse(localStorage.getItem("usuarios")) || {};

  return Object.entries(savedUsers).map(([username, data]) => {
    const cleanUsername = username.replace(/^@/, "");
    return {
      nome: cleanUsername,
      username: `@${cleanUsername}`,
      bio: data.bio || data.email || "Perfil salvo no navegador",
      avatar: data.foto || data.foto_perfil || "../Images/avatar-placeholder.svg",
      tags: []
    };
  });
}

function getToken() {
  return localStorage.getItem("token");
}

async function fetchProfiles(query = "") {
  const term = query && query.trim().length ? query.trim() : "";
  const token = getToken();

  try {
    // Construir URL com parâmetros de busca e paginação
    let url = `${API_URL}/profile/buscar_por_username/?skip=0&limit=100`;
    
    if (term) {
      url += `&username=${encodeURIComponent(term)}`;
    }

    const headers = {
      "Content-Type": "application/json"
    };

    // Adicionar token de autenticação se disponível
    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }

    const response = await fetch(url, { headers });

    if (!response.ok) {
      throw new Error("Falha ao buscar perfis");
    }

    const data = await response.json();

    if (Array.isArray(data) && data.length) {
      profilesData = data.map(buildProfileFromAPI);
      return;
    }

    profilesData = loadSavedProfiles();
    if (!profilesData.length) {
      profilesData = fallbackProfiles;
    }
  } catch (error) {
    console.error("Erro ao buscar perfis:", error);
    profilesData = loadSavedProfiles();
    if (!profilesData.length) {
      profilesData = fallbackProfiles;
    }
  }
}


/* ===== ELEMENTOS ===== */
const profilesGrid = document.getElementById("profilesGrid");
const searchInput = document.getElementById("searchInput");
const chips = document.querySelectorAll(".chip");

let filtroAtual = "todos";
let termoAtual = "";

/* ===== HELPERS ===== */
function normalizar(texto) {
  return texto.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

function combinarBusca(...campos) {
  return normalizar(campos.join(" "));
}

function renderEmpty(container, titulo, descricao) {
  container.innerHTML = `
    <div class="empty-state">
      <i data-lucide="search-x"></i>
      <h3>${titulo}</h3>
      <p>${descricao}</p>
    </div>
  `;
}

function profileMatch(profile) {
  const base = combinarBusca(
    profile.nome,
    profile.username,
    profile.bio,
    profile.tags.join(" ")
  );

  const termoOk = !termoAtual || base.includes(normalizar(termoAtual));
  const filtroOk =
    filtroAtual === "todos" ||
    profile.tags.some(tag => normalizar(tag).includes(normalizar(filtroAtual))) ||
    base.includes(normalizar(filtroAtual));

  return termoOk && filtroOk;
}

/* ===== RENDER PERFIS ===== */
async function renderProfiles() {
  profilesGrid.innerHTML = `
    <div class="empty-state loading-state">
      <i data-lucide="refresh-cw"></i>
      <h3>Buscando perfis reais</h3>
      <p>Aguarde um momento enquanto carregamos perfis criados na API.</p>
    </div>
  `;
  lucide.createIcons();

  await fetchProfiles(termoAtual);

  const filtrados = profilesData.filter(profileMatch);

  if (!filtrados.length) {
    renderEmpty(
      profilesGrid,
      "Nenhum perfil encontrado",
      "Tente outro termo ou troque o filtro para descobrir novas pessoas dentro do Pace."
    );
    lucide.createIcons();
    return;
  }

  profilesGrid.innerHTML = filtrados.map((profile, index) => `
    <article class="profile-card" style="animation-delay:${0.04 + index * 0.04}s">
      <div class="profile-topo">
        <img src="${profile.avatar}" alt="${profile.nome}" class="profile-avatar">
        <div>
          <h3 class="profile-nome">${profile.nome}</h3>
          <p class="profile-user">${profile.username}</p>
        </div>
      </div>

      <p class="profile-bio">${profile.bio}</p>

      <div class="profile-stats">
        ${profile.tags.map(tag => `<span class="profile-pill">${tag}</span>`).join("")}
      </div>

      <button class="profile-btn" data-profile-id="${profile.id ?? ""}" data-profile-username="${profile.username}">Ver perfil</button>
    </article>
  `).join("");

  lucide.createIcons();
  attachProfileButtons();
}

/* ===== MODAL DE PERFIL ===== */
const profileModal = document.getElementById("profileModal");
const closeProfileModal = document.getElementById("closeProfileModal");

function getToken() {
  return localStorage.getItem("token");
}

function closeModal() {
  if (!profileModal) return;
  profileModal.classList.add("hidden");
  document.body.classList.remove("modal-open");
}

function attachProfileButtons() {
  document.querySelectorAll(".profile-btn").forEach((button) => {
    button.addEventListener("click", async () => {
      const profileId = button.dataset.profileId;
      const username = button.dataset.profileUsername;
      const profile = profilesData.find(
        (item) => item.username === username || String(item.id) === profileId
      );

      if (profile) {
        await openProfileModal(profile);
      }
    });
  });
}

async function fetchUserPosts(profile) {
  const token = getToken();
  if (!token) {
    return null;
  }

  try {
    const response = await fetch(`${API_URL}/post/feed`, {
      headers: {
        Authorization: `Bearer ${token}`
      }
    });

    if (!response.ok) {
      throw new Error("Falha ao carregar posts");
    }

    const data = await response.json();
    if (!Array.isArray(data)) {
      return [];
    }

    const requestedUsername = String(profile.username).replace(/^@/, "").toLowerCase();
    return data.filter((post) => {
      const postUserId = String(post.usuario?.id ?? "");
      const postUsername = String(post.usuario?.username ?? "").toLowerCase();
      return (
        postUserId === String(profile.id) ||
        postUsername === requestedUsername
      );
    });
  } catch (error) {
    return null;
  }
}

async function openProfileModal(profile) {
  if (!profileModal) return;

  const body = profileModal.querySelector(".modal-body");
  if (!body) return;

  const tagsMarkup = profile.tags?.length
    ? `<div class="profile-tags">${profile.tags
        .map((tag) => `<span class="profile-tag">${tag}</span>`)
        .join("")}</div>`
    : "";

  body.innerHTML = `
    <div class="modal-header">
      <img class="modal-avatar" src="${profile.avatar}" alt="${profile.nome}">
      <div class="modal-meta">
        <h2>${profile.nome}</h2>
        <p>${profile.username}</p>
        <p>${profile.bio}</p>
        ${tagsMarkup}
      </div>
    </div>

    <div class="modal-section">
      <h3>Postagens</h3>
      <div class="modal-posts">
        <div class="modal-loading">Carregando postagens...</div>
      </div>
    </div>
  `;

  profileModal.classList.remove("hidden");
  document.body.classList.add("modal-open");
  lucide.createIcons();

  const posts = await fetchUserPosts(profile);
  const postsContainer = body.querySelector(".modal-posts");

  if (!postsContainer) return;

  if (posts === null) {
    postsContainer.innerHTML = `
      <div class="modal-empty">
        Faça login para ver as postagens deste perfil.
      </div>
    `;
    return;
  }

  if (!posts.length) {
    postsContainer.innerHTML = `
      <div class="modal-empty">
        Nenhuma postagem encontrada para este perfil.
      </div>
    `;
    return;
  }

  function formatRelativeTime(dateString) {
    const date = new Date(dateString);
    if (Number.isNaN(date.getTime())) return "";

    const now = new Date();
    const diff = Math.max(0, now - date);
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    const weeks = Math.floor(days / 7);
    const months = Math.floor(days / 30);
    const years = Math.floor(days / 365);

    if (seconds < 60) {
      return "há poucos segundos";
    }
    if (minutes < 60) {
      return `há ${minutes} minuto${minutes === 1 ? "" : "s"}`;
    }
    if (hours < 24) {
      return `há ${hours} hora${hours === 1 ? "" : "s"}`;
    }
    if (days < 7) {
      return `há ${days} dia${days === 1 ? "" : "s"}`;
    }
    if (weeks < 5) {
      return `há ${weeks} semana${weeks === 1 ? "" : "s"}`;
    }
    if (months < 12) {
      return `há ${months} mês${months === 1 ? "" : "es"}`;
    }
    return `há ${years} ano${years === 1 ? "" : "s"}`;
  }

  postsContainer.innerHTML = posts
    .map((post) => {
      const content = post.conteudo || "Sem descrição";
      const formattedDate = post.data_postagem
        ? formatRelativeTime(post.data_postagem)
        : "";

      return `
        <article class="modal-post-card">
          <h4>${content.substring(0, 120)}${content.length > 120 ? "..." : ""}</h4>
          <p>${content}</p>
          ${post.imagem ? `<img src="${post.imagem}" alt="Imagem do post" class="modal-post-image">` : ""}
          <div class="modal-post-meta">
            <span>${formattedDate}</span>
            <span>❤️ ${post.likes ?? 0}</span>
          </div>
        </article>
      `;
    })
    .join("");

  lucide.createIcons();
}

closeProfileModal?.addEventListener("click", closeModal);
profileModal?.addEventListener("click", (event) => {
  if (event.target === profileModal) {
    closeModal();
  }
});

/* ===== RENDER GERAL ===== */
async function renderTudo() {
  await renderProfiles();
}

/* ===== EVENTOS ===== */
searchInput.addEventListener("input", async e => {
  termoAtual = e.target.value.trim();
  await renderTudo();
});

chips.forEach(chip => {
  chip.addEventListener("click", async () => {
    chips.forEach(btn => btn.classList.remove("active"));
    chip.classList.add("active");
    filtroAtual = chip.dataset.filter;
    await renderTudo();
  });
});

/* ===== INIT ===== */
renderTudo();

