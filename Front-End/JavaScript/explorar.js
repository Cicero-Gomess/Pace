/* ===== FOTO GLOBAL ===== */
(function () {
  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const userData = usuarios[user.username];
  const foto = userData?.foto || user.foto || "../Images/image.person.png";

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

/* ===== DADOS MOCKADOS ===== */
const profilesData = [
  {
    nome: "Lara Mendes",
    username: "@laradisciplina",
    bio: "Transformando rotina em resultado com constância, treino e estudo diário.",
    avatar: "../Images/image.person.png",
    tags: ["Disciplina", "Mindset", "Consistência"]
  },
  {
    nome: "Caio Rocha",
    username: "@caioprodutivo",
    bio: "Foco, deep work e sistemas simples para render mais sem se perder.",
    avatar: "../Images/image.person.png",
    tags: ["Produtividade", "Estudos", "Foco"]
  },
  {
    nome: "Ana Beatriz",
    username: "@anaemmovimento",
    bio: "Academia, energia e pequenos hábitos que melhoram o dia inteiro.",
    avatar: "../Images/image.person.png",
    tags: ["Academia", "Rotina", "Energia"]
  },
  {
    nome: "Rafael Costa",
    username: "@rafamind",
    bio: "Mentalidade forte, clareza e evolução pessoal sem romantizar o caos.",
    avatar: "../Images/image.person.png",
    tags: ["Mindset", "Disciplina", "Clareza"]
  },
  {
    nome: "Julia Alves",
    username: "@juliaestuda",
    bio: "Organização real para quem quer estudar melhor e viver com mais leveza.",
    avatar: "../Images/image.person.png",
    tags: ["Estudos", "Planejamento", "Rotina"]
  },
  {
    nome: "Victor Hugo",
    username: "@victorflow",
    bio: "Construindo hábitos sólidos e compartilhando os bastidores da evolução.",
    avatar: "../Images/image.person.png",
    tags: ["Produtividade", "Mindset", "Hábitos"]
  }
];

const ideasData = [
  {
    titulo: "Rotina de 20 minutos para sair da inércia",
    descricao: "Uma trilha curta de ativação para quando o dia começa travado e sem ritmo.",
    categoria: "Disciplina",
    meta: "Leitura rápida"
  },
  {
    titulo: "Checklist de foco para estudar melhor",
    descricao: "Pequenas ações antes da sessão de estudo que melhoram muito sua concentração.",
    categoria: "Estudos",
    meta: "Aplicação imediata"
  },
  {
    titulo: "Como manter energia no meio da semana",
    descricao: "Ajustes simples em sono, movimento e organização para não quebrar no processo.",
    categoria: "Mindset",
    meta: "Constância"
  },
  {
    titulo: "Treinos curtos que mantêm a rotina viva",
    descricao: "Quando o tempo está apertado, o segredo é continuar em movimento sem sumir.",
    categoria: "Academia",
    meta: "Energia"
  },
  {
    titulo: "Sistema leve para organizar o dia",
    descricao: "Um jeito mais limpo de lidar com prioridades sem montar uma agenda impossível.",
    categoria: "Produtividade",
    meta: "Clareza"
  },
  {
    titulo: "Identidade antes de motivação",
    descricao: "Como parar de depender de pico emocional e construir uma presença mais estável.",
    categoria: "Mindset",
    meta: "Profundidade"
  }
];

/* ===== ELEMENTOS ===== */
const profilesGrid = document.getElementById("profilesGrid");
const ideasGrid = document.getElementById("ideasGrid");
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
    profile.tags.some(tag => normalizar(tag).includes(normalizar(filtroAtual)));

  return termoOk && filtroOk;
}

function ideaMatch(idea) {
  const base = combinarBusca(
    idea.titulo,
    idea.descricao,
    idea.categoria,
    idea.meta
  );

  const termoOk = !termoAtual || base.includes(normalizar(termoAtual));
  const filtroOk =
    filtroAtual === "todos" ||
    normalizar(idea.categoria).includes(normalizar(filtroAtual));

  return termoOk && filtroOk;
}

/* ===== RENDER PERFIS ===== */
function renderProfiles() {
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

      <button class="profile-btn">Ver perfil</button>
    </article>
  `).join("");

  lucide.createIcons();
}

/* ===== RENDER IDEIAS ===== */
function renderIdeas() {
  const filtradas = ideasData.filter(ideaMatch);

  if (!filtradas.length) {
    renderEmpty(
      ideasGrid,
      "Nada combinou com a sua busca",
      "Refine menos a pesquisa ou volte para “Tudo” para abrir mais possibilidades."
    );
    lucide.createIcons();
    return;
  }

  ideasGrid.innerHTML = filtradas.map((idea, index) => `
    <article class="idea-card" style="animation-delay:${0.05 + index * 0.04}s">
      <span class="idea-badge">
        <i data-lucide="sparkles"></i>
        ${idea.categoria}
      </span>

      <h3>${idea.titulo}</h3>
      <p>${idea.descricao}</p>

      <div class="idea-footer">
        <span>${idea.meta}</span>
        <span>Explorar</span>
      </div>
    </article>
  `).join("");

  lucide.createIcons();
}

/* ===== RENDER GERAL ===== */
function renderTudo() {
  renderProfiles();
  renderIdeas();
}

/* ===== EVENTOS ===== */
searchInput.addEventListener("input", e => {
  termoAtual = e.target.value.trim();
  renderTudo();
});

chips.forEach(chip => {
  chip.addEventListener("click", () => {
    chips.forEach(btn => btn.classList.remove("active"));
    chip.classList.add("active");
    filtroAtual = chip.dataset.filter;
    renderTudo();
  });
});

/* ===== INIT ===== */
renderTudo();
