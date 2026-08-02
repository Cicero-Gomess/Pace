import { initDarkMode } from "./shared/ui.js";

initDarkMode();

const STORAGE_KEY = "pace_metas_local";

const elementos = {
  lista: document.getElementById("metasLista"),
  estadoVazio: document.getElementById("estadoVazio"),

  totalMetas: document.getElementById("totalMetas"),
  metasConcluidas: document.getElementById("metasConcluidas"),
  metasEmAndamento: document.getElementById("metasEmAndamento"),

  progressoGeral: document.getElementById("progressoGeral"),
  progressoGeralBarra: document.getElementById(
    "progressoGeralBarra"
  ),

  busca: document.getElementById("buscarMeta"),

  modal: document.getElementById("metaModal"),
  form: document.getElementById("metaForm"),

  metaId: document.getElementById("metaId"),
  titulo: document.getElementById("metaTitulo"),
  descricao: document.getElementById("metaDescricao"),
  categoria: document.getElementById("metaCategoria"),
  prazo: document.getElementById("metaPrazo"),
  progresso: document.getElementById("metaProgresso"),

  progressoValor: document.getElementById(
    "metaProgressoValor"
  ),

  modalTitulo: document.getElementById("metaModalTitulo"),

  confirmarExclusaoModal: document.getElementById(
    "confirmarExclusaoModal"
  ),

  cancelarExclusao: document.getElementById(
    "cancelarExclusao"
  ),

  confirmarExclusao: document.getElementById(
    "confirmarExclusao"
  ),

  abrirNovaMeta: document.getElementById(
    "abrirNovaMeta"
  ),

  abrirNovaMetaVazio: document.getElementById(
    "abrirNovaMetaVazio"
  ),

  fecharMetaModal: document.getElementById(
    "fecharMetaModal"
  ),

  cancelarMeta: document.getElementById(
    "cancelarMeta"
  ),
};

let metas = carregarMetas();
let filtroAtual = "todas";
let metaParaExcluir = null;

function iniciarIcones() {
  if (
    window.lucide &&
    typeof window.lucide.createIcons === "function"
  ) {
    window.lucide.createIcons();
  }
}

function gerarId() {
  if (
    window.crypto &&
    typeof window.crypto.randomUUID === "function"
  ) {
    return window.crypto.randomUUID();
  }

  return `meta-${Date.now()}-${Math.random()
    .toString(16)
    .slice(2)}`;
}

function normalizarMeta(meta) {
  const valorOriginal = Number(meta?.progresso ?? 0);

  const progresso = Math.min(
    100,
    Math.max(
      0,
      Number.isFinite(valorOriginal)
        ? valorOriginal
        : 0
    )
  );

  return {
    id: String(meta?.id || gerarId()),
    titulo: String(meta?.titulo || ""),
    descricao: String(meta?.descricao || ""),
    categoria: String(meta?.categoria || "Pessoal"),
    prazo: String(meta?.prazo || ""),
    progresso,

    concluida:
      Boolean(meta?.concluida) ||
      progresso === 100,

    criadaEm: String(
      meta?.criadaEm ||
      new Date().toISOString()
    ),
  };
}

function carregarMetas() {
  try {
    const conteudo = localStorage.getItem(STORAGE_KEY);

    if (!conteudo) {
      return [];
    }

    const dados = JSON.parse(conteudo);

    if (!Array.isArray(dados)) {
      return [];
    }

    return dados.map(normalizarMeta);
  } catch (erro) {
    console.error("Erro ao carregar metas:", erro);
    return [];
  }
}

function salvarMetas() {
  try {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify(metas)
    );
  } catch (erro) {
    console.error("Erro ao salvar metas:", erro);
  }
}

function escaparHTML(valor = "") {
  return String(valor)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function formatarPrazo(data) {
  if (!data) {
    return "Sem prazo";
  }

  const partes = data.split("-");

  if (partes.length !== 3) {
    return "Sem prazo";
  }

  const [ano, mes, dia] = partes;

  return `${dia}/${mes}/${ano}`;
}

function abrirModal(meta = null) {
  if (!elementos.modal || !elementos.form) {
    return;
  }

  elementos.form.reset();

  elementos.metaId.value = "";
  elementos.progresso.value = "0";
  elementos.progressoValor.textContent = "0%";
  elementos.modalTitulo.textContent = "Nova meta";

  if (meta) {
    elementos.metaId.value = meta.id;
    elementos.titulo.value = meta.titulo;
    elementos.descricao.value = meta.descricao;
    elementos.categoria.value = meta.categoria;
    elementos.prazo.value = meta.prazo;

    elementos.progresso.value = String(
      meta.progresso
    );

    elementos.progressoValor.textContent =
      `${meta.progresso}%`;

    elementos.modalTitulo.textContent =
      "Editar meta";
  }

  elementos.modal.classList.remove("hidden");

  window.setTimeout(() => {
    elementos.titulo?.focus();
  }, 50);

  iniciarIcones();
}

function fecharModal() {
  elementos.modal?.classList.add("hidden");
}

function atualizarResumo() {
  const total = metas.length;

  const concluidas = metas.filter(
    (meta) => meta.concluida
  ).length;

  const andamento = total - concluidas;

  const progressoMedio =
    total === 0
      ? 0
      : Math.round(
          metas.reduce(
            (soma, meta) =>
              soma + Number(meta.progresso || 0),
            0
          ) / total
        );

  if (elementos.totalMetas) {
    elementos.totalMetas.textContent =
      String(total);
  }

  if (elementos.metasConcluidas) {
    elementos.metasConcluidas.textContent =
      String(concluidas);
  }

  if (elementos.metasEmAndamento) {
    elementos.metasEmAndamento.textContent =
      String(andamento);
  }

  if (elementos.progressoGeral) {
    elementos.progressoGeral.textContent =
      `${progressoMedio}%`;
  }

  if (elementos.progressoGeralBarra) {
    elementos.progressoGeralBarra.style.width =
      `${progressoMedio}%`;
  }
}

function filtrarMetas() {
  const termo = String(
    elementos.busca?.value || ""
  )
    .trim()
    .toLowerCase();

  return metas.filter((meta) => {
    const correspondeBusca =
      !termo ||
      meta.titulo.toLowerCase().includes(termo) ||
      meta.descricao.toLowerCase().includes(termo) ||
      meta.categoria.toLowerCase().includes(termo);

    const correspondeFiltro =
      filtroAtual === "todas" ||
      (
        filtroAtual === "concluidas" &&
        meta.concluida
      ) ||
      (
        filtroAtual === "andamento" &&
        !meta.concluida
      );

    return correspondeBusca && correspondeFiltro;
  });
}

function criarMetaHTML(meta) {
  return `
    <article
      class="meta-card ${
        meta.concluida ? "concluida" : ""
      }"
      data-id="${escaparHTML(meta.id)}"
    >
      <div class="meta-card-topo">

        <span class="meta-categoria">
          <i data-lucide="tag"></i>
          ${escaparHTML(meta.categoria)}
        </span>

        <div class="meta-card-acoes">

          <button
            class="meta-icon-btn"
            type="button"
            data-action="editar"
            aria-label="Editar meta"
          >
            <i data-lucide="pencil"></i>
          </button>

          <button
            class="meta-icon-btn danger"
            type="button"
            data-action="excluir"
            aria-label="Excluir meta"
          >
            <i data-lucide="trash-2"></i>
          </button>

        </div>
      </div>

      <h3>${escaparHTML(meta.titulo)}</h3>

      <p>
        ${escaparHTML(
          meta.descricao || "Sem descrição."
        )}
      </p>

      <div class="meta-info">

        <span class="meta-prazo">
          <i data-lucide="calendar-days"></i>
          ${formatarPrazo(meta.prazo)}
        </span>

        <span class="meta-percentual">
          ${meta.progresso}%
        </span>

      </div>

      <div class="meta-progress" aria-hidden="true">
        <span
          style="width: ${meta.progresso}%"
        ></span>
      </div>

      <div class="meta-card-footer">

        <button
          class="btn-progresso"
          type="button"
          data-action="progresso"
        >
          Atualizar progresso
        </button>

        <button
          class="btn-concluir"
          type="button"
          data-action="concluir"
        >
          ${
            meta.concluida
              ? "Reabrir meta"
              : "Concluir meta"
          }
        </button>

      </div>
    </article>
  `;
}

function renderizar() {
  if (!elementos.lista || !elementos.estadoVazio) {
    console.error(
      "Os elementos da tela de metas não foram encontrados."
    );

    return;
  }

  atualizarResumo();

  const metasFiltradas = filtrarMetas();
  const semMetasCriadas = metas.length === 0;

  elementos.estadoVazio.classList.toggle(
    "show",
    semMetasCriadas
  );

  if (semMetasCriadas) {
    elementos.lista.innerHTML = "";
    iniciarIcones();
    return;
  }

  if (metasFiltradas.length === 0) {
    elementos.lista.innerHTML = `
      <div class="estado-vazio show">

        <span class="estado-icon">
          <i data-lucide="search-x"></i>
        </span>

        <h3>Nenhuma meta encontrada.</h3>

        <p>
          Tente outro termo ou altere
          o filtro selecionado.
        </p>

      </div>
    `;

    iniciarIcones();
    return;
  }

  elementos.lista.innerHTML =
    metasFiltradas
      .map(criarMetaHTML)
      .join("");

  iniciarIcones();
}

function salvarFormulario(evento) {
  evento.preventDefault();

  const titulo = String(
    elementos.titulo?.value || ""
  ).trim();

  if (!titulo) {
    elementos.titulo?.focus();
    return;
  }

  const progresso = Math.min(
    100,
    Math.max(
      0,
      Number(elementos.progresso?.value || 0)
    )
  );

  const idExistente = String(
    elementos.metaId?.value || ""
  );

  const dados = {
    titulo,

    descricao: String(
      elementos.descricao?.value || ""
    ).trim(),

    categoria: String(
      elementos.categoria?.value || "Pessoal"
    ),

    prazo: String(
      elementos.prazo?.value || ""
    ),

    progresso,
    concluida: progresso === 100,
  };

  if (idExistente) {
    metas = metas.map((meta) =>
      meta.id === idExistente
        ? normalizarMeta({
            ...meta,
            ...dados,
          })
        : meta
    );
  } else {
    metas.unshift(
      normalizarMeta({
        id: gerarId(),
        criadaEm: new Date().toISOString(),
        ...dados,
      })
    );
  }

  salvarMetas();
  fecharModal();
  renderizar();
}

function encontrarMeta(id) {
  return metas.find(
    (meta) => meta.id === String(id)
  );
}

function atualizarProgresso(meta) {
  abrirModal(meta);

  if (elementos.modalTitulo) {
    elementos.modalTitulo.textContent =
      "Atualizar progresso";
  }

  window.setTimeout(() => {
    elementos.progresso?.focus();
  }, 80);
}

elementos.lista?.addEventListener(
  "click",
  (evento) => {
    const botao = evento.target.closest(
      "button[data-action]"
    );

    if (!botao) {
      return;
    }

    const card = botao.closest(".meta-card");

    if (!card) {
      return;
    }

    const meta = encontrarMeta(card.dataset.id);

    if (!meta) {
      return;
    }

    const acao = botao.dataset.action;

    if (acao === "editar") {
      abrirModal(meta);
      return;
    }

    if (acao === "excluir") {
      metaParaExcluir = meta.id;

      elementos.confirmarExclusaoModal
        ?.classList.remove("hidden");

      iniciarIcones();
      return;
    }

    if (acao === "progresso") {
      atualizarProgresso(meta);
      return;
    }

    if (acao === "concluir") {
      meta.concluida = !meta.concluida;

      meta.progresso = meta.concluida
        ? 100
        : Math.min(
            Number(meta.progresso || 0),
            99
          );

      salvarMetas();
      renderizar();
    }
  }
);

document
  .querySelectorAll(".filtro")
  .forEach((botao) => {
    botao.addEventListener("click", () => {
      document
        .querySelectorAll(".filtro")
        .forEach((item) => {
          item.classList.remove("active");
        });

      botao.classList.add("active");

      filtroAtual =
        botao.dataset.filter || "todas";

      renderizar();
    });
  });

elementos.abrirNovaMeta?.addEventListener(
  "click",
  () => abrirModal()
);

elementos.abrirNovaMetaVazio?.addEventListener(
  "click",
  () => abrirModal()
);

elementos.fecharMetaModal?.addEventListener(
  "click",
  fecharModal
);

elementos.cancelarMeta?.addEventListener(
  "click",
  fecharModal
);

elementos.cancelarExclusao?.addEventListener(
  "click",
  () => {
    metaParaExcluir = null;

    elementos.confirmarExclusaoModal
      ?.classList.add("hidden");
  }
);

elementos.confirmarExclusao?.addEventListener(
  "click",
  () => {
    if (!metaParaExcluir) {
      elementos.confirmarExclusaoModal
        ?.classList.add("hidden");

      return;
    }

    metas = metas.filter(
      (meta) => meta.id !== metaParaExcluir
    );

    metaParaExcluir = null;

    salvarMetas();

    elementos.confirmarExclusaoModal
      ?.classList.add("hidden");

    renderizar();
  }
);

elementos.form?.addEventListener(
  "submit",
  salvarFormulario
);

elementos.busca?.addEventListener(
  "input",
  renderizar
);

elementos.progresso?.addEventListener(
  "input",
  () => {
    if (elementos.progressoValor) {
      elementos.progressoValor.textContent =
        `${elementos.progresso.value}%`;
    }
  }
);

elementos.modal?.addEventListener(
  "click",
  (evento) => {
    if (evento.target === elementos.modal) {
      fecharModal();
    }
  }
);

elementos.confirmarExclusaoModal?.addEventListener(
  "click",
  (evento) => {
    if (
      evento.target ===
      elementos.confirmarExclusaoModal
    ) {
      metaParaExcluir = null;

      elementos.confirmarExclusaoModal
        .classList.add("hidden");
    }
  }
);

document.addEventListener(
  "keydown",
  (evento) => {
    if (evento.key !== "Escape") {
      return;
    }

    fecharModal();

    metaParaExcluir = null;

    elementos.confirmarExclusaoModal
      ?.classList.add("hidden");
  }
);

window.addEventListener("storage", (evento) => {
  if (
    evento.key === "darkMode" ||
    evento.key === null
  ) {
    initDarkMode();
  }

  if (
    evento.key === STORAGE_KEY ||
    evento.key === null
  ) {
    metas = carregarMetas();
    renderizar();
  }
});

iniciarIcones();
renderizar();