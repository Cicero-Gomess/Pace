import { initAppShell } from "./shared/app-shell.js";

const API_BASE_URL =
  window.PACE_API_URL ||
  window.API_BASE_URL ||
  "http://127.0.0.1:8000";

const elementos = {
  lista: document.getElementById("metasLista"),
  estadoVazio: document.getElementById("estadoVazio"),
  loading: document.getElementById("metasLoading"),

  totalMetas: document.getElementById("totalMetas"),
  metasConcluidas: document.getElementById("metasConcluidas"),
  metasEmAndamento: document.getElementById("metasEmAndamento"),

  statusResumo: document.getElementById("statusResumo"),
  statusResumoTexto: document.getElementById("statusResumoTexto"),

  busca: document.getElementById("buscarMeta"),

  modal: document.getElementById("metaModal"),
  form: document.getElementById("metaForm"),

  metaId: document.getElementById("metaId"),
  titulo: document.getElementById("metaTitulo"),
  descricao: document.getElementById("metaDescricao"),
  categoria: document.getElementById("metaCategoria"),
  prazo: document.getElementById("metaPrazo"),

  modalTitulo: document.getElementById("metaModalTitulo"),

  confirmarExclusaoModal:
    document.getElementById("confirmarExclusaoModal"),

  cancelarExclusao:
    document.getElementById("cancelarExclusao"),

  confirmarExclusao:
    document.getElementById("confirmarExclusao"),

  abrirNovaMeta:
    document.getElementById("abrirNovaMeta"),

  abrirNovaMetaVazio:
    document.getElementById("abrirNovaMetaVazio"),

  fecharMetaModal:
    document.getElementById("fecharMetaModal"),

  cancelarMeta:
    document.getElementById("cancelarMeta"),

  toast:
    document.getElementById("metasToast"),
};

let metas = [];

let filtroAtual = "todas";

let metaParaExcluir = null;

let salvando = false;

let toastTimer = null;

/* =========================================================
   TOKEN
========================================================= */

function obterToken() {
  const chaves = [
    "token",
    "access_token",
    "pace_token",
    "pace_access_token",
  ];

  for (
    const storage of [
      localStorage,
      sessionStorage,
    ]
  ) {
    for (const chave of chaves) {
      const valor =
        storage.getItem(chave);

      if (
        valor &&
        valor.trim()
      ) {
        return valor.trim();
      }
    }
  }

  return null;
}

/* =========================================================
   API
========================================================= */

function montarHeaders(
  json = false
) {
  const token =
    obterToken();

  const headers = {};

  if (token) {
    headers.Authorization =
      `Bearer ${token}`;
  }

  if (json) {
    headers["Content-Type"] =
      "application/json";
  }

  return headers;
}

async function api(
  rota,
  opcoes = {}
) {
  let resposta;

  try {
    resposta =
      await fetch(
        `${API_BASE_URL}${rota}`,
        {
          credentials: "include",

          ...opcoes,

          headers: {
            ...montarHeaders(
              opcoes.body !== undefined &&
              !(opcoes.body instanceof FormData)
            ),

            ...(opcoes.headers || {}),
          },
        }
      );
  } catch (erro) {
    throw new Error(
      "Não foi possível conectar à API do Pace."
    );
  }

  let dados = null;

  try {
    dados =
      resposta.status === 204
        ? null
        : await resposta.json();
  } catch {
    dados = null;
  }

  if (
    resposta.status === 401
  ) {
    const erro =
      new Error(
        "Sua sessão expirou."
      );

    erro.status = 401;

    throw erro;
  }

  if (!resposta.ok) {
    const detalhe =
      dados?.detail ||
      dados?.message ||
      "Não foi possível concluir a operação.";

    const erro =
      new Error(
        typeof detalhe === "string"
          ? detalhe
          : "Erro na operação."
      );

    erro.status =
      resposta.status;

    throw erro;
  }

  return dados;
}

function listarMetasApi() {
  return api(
    "/metas/listar_metas"
  );
}

function criarMetaApi(
  payload
) {
  return api(
    "/metas/criar_meta",
    {
      method: "POST",

      body:
        JSON.stringify(
          payload
        ),
    }
  );
}

function atualizarMetaApi(
  id,
  payload
) {
  return api(
    `/metas/atualizar_meta/${id}`,
    {
      method: "PUT",

      body:
        JSON.stringify(
          payload
        ),
    }
  );
}

function deletarMetaApi(id) {
  return api(
    `/metas/deletar_meta/${id}`,
    {
      method:
        "DELETE",
    }
  );
}

/* =========================================================
   UTILIDADES
========================================================= */

function iniciarIcones() {
  if (
    window.lucide &&
    typeof window.lucide.createIcons ===
      "function"
  ) {
    window.lucide.createIcons();
  }
}

function escaparHTML(
  valor = ""
) {
  return String(valor)
    .replaceAll(
      "&",
      "&amp;"
    )
    .replaceAll(
      "<",
      "&lt;"
    )
    .replaceAll(
      ">",
      "&gt;"
    )
    .replaceAll(
      '"',
      "&quot;"
    )
    .replaceAll(
      "'",
      "&#039;"
    );
}

function normalizarStatus(
  valor
) {
  const status =
    String(
      valor || ""
    )
      .trim()
      .toLowerCase();

  return (
    status ===
    "concluida"
      ? "concluida"
      : "em andamento"
  );
}

function normalizarMeta(
  meta
) {
  return {
    id:
      Number(meta?.id),

    titulo:
      String(
        meta?.titulo ||
        ""
      ),

    descricao:
      String(
        meta?.descricao ||
        ""
      ),

    categoria:
      String(
        meta?.categoria ||
        "Outro"
      ),

    prazo:
      meta?.prazo
        ? String(
            meta.prazo
          ).slice(
            0,
            10
          )
        : "",

    status:
      normalizarStatus(
        meta?.status
      ),
  };
}

function formatarPrazo(
  data
) {
  if (!data) {
    return "Sem prazo";
  }

  const partes =
    String(data)
      .slice(
        0,
        10
      )
      .split("-");

  if (
    partes.length !== 3
  ) {
    return "Sem prazo";
  }

  const [
    ano,
    mes,
    dia,
  ] = partes;

  return `${dia}/${mes}/${ano}`;
}

function mostrarToast(
  mensagem,
  tipo = "success"
) {
  if (!elementos.toast) {
    console.log(
      mensagem
    );

    return;
  }

  clearTimeout(
    toastTimer
  );

  elementos.toast.textContent =
    mensagem;

  elementos.toast.className =
    `metas-toast ${tipo}`;

  elementos.toast.classList.remove(
    "hidden"
  );

  requestAnimationFrame(
    () => {
      elementos.toast.classList.add(
        "show"
      );
    }
  );

  toastTimer =
    setTimeout(
      () => {
        elementos.toast.classList.remove(
          "show"
        );

        setTimeout(
          () => {
            elementos.toast.classList.add(
              "hidden"
            );
          },
          200
        );
      },
      2600
    );
}

function tratarErro(
  erro
) {
  console.error(
    erro
  );

  if (
    erro?.status === 401
  ) {
    mostrarToast(
      "Sua sessão expirou. Entre novamente.",
      "error"
    );

    setTimeout(
      () => {
        window.location.href =
          "entrar.html";
      },
      800
    );

    return;
  }

  mostrarToast(
    erro?.message ||
      "Algo deu errado.",
    "error"
  );
}

/* =========================================================
   MODAL
========================================================= */

function abrirModal(
  meta = null
) {
  if (
    !elementos.modal ||
    !elementos.form
  ) {
    return;
  }

  elementos.form.reset();

  elementos.metaId.value =
    "";

  elementos.modalTitulo.textContent =
    "Nova meta";

  if (meta) {
    elementos.metaId.value =
      String(meta.id);

    elementos.titulo.value =
      meta.titulo;

    elementos.descricao.value =
      meta.descricao;

    elementos.categoria.value =
      meta.categoria;

    elementos.prazo.value =
      meta.prazo;

    elementos.modalTitulo.textContent =
      "Editar meta";
  }

  elementos.modal.classList.remove(
    "hidden"
  );

  document.body.style.overflow =
    "hidden";

  setTimeout(
    () =>
      elementos.titulo?.focus(),
    50
  );

  iniciarIcones();
}

function fecharModal() {
  elementos.modal?.classList.add(
    "hidden"
  );

  document.body.style.overflow =
    "";
}

function abrirModalExclusao(
  meta
) {
  metaParaExcluir =
    meta;

  elementos
    .confirmarExclusaoModal
    ?.classList.remove(
      "hidden"
    );

  document.body.style.overflow =
    "hidden";
}

function fecharModalExclusao() {
  metaParaExcluir =
    null;

  elementos
    .confirmarExclusaoModal
    ?.classList.add(
      "hidden"
    );

  document.body.style.overflow =
    "";
}

/* =========================================================
   RESUMO
========================================================= */

function atualizarResumo() {
  const total =
    metas.length;

  const concluidas =
    metas.filter(
      (meta) =>
        meta.status ===
        "concluida"
    ).length;

  const andamento =
    metas.filter(
      (meta) =>
        meta.status ===
        "em andamento"
    ).length;

  if (
    elementos.totalMetas
  ) {
    elementos.totalMetas.textContent =
      String(total);
  }

  if (
    elementos.metasConcluidas
  ) {
    elementos.metasConcluidas.textContent =
      String(
        concluidas
      );
  }

  if (
    elementos.metasEmAndamento
  ) {
    elementos.metasEmAndamento.textContent =
      String(
        andamento
      );
  }

  if (
    !elementos.statusResumo ||
    !elementos.statusResumoTexto
  ) {
    return;
  }

  if (
    total === 0
  ) {
    elementos.statusResumo.textContent =
      "Nenhuma meta ativa";

    elementos.statusResumoTexto.textContent =
      "Crie uma meta e comece seu próximo passo.";

    return;
  }

  if (
    andamento > 0
  ) {
    elementos.statusResumo.textContent =
      `${andamento} ${
        andamento === 1
          ? "meta em andamento"
          : "metas em andamento"
      }`;

    elementos.statusResumoTexto.textContent =
      "Continue avançando. Quando finalizar, marque a meta como concluída.";

    return;
  }

  elementos.statusResumo.textContent =
    "Tudo concluído por aqui";

  elementos.statusResumoTexto.textContent =
    "Suas metas atuais foram concluídas. Que tal criar o próximo objetivo?";
}

/* =========================================================
   FILTROS
========================================================= */

function filtrarMetas() {
  const termo =
    String(
      elementos.busca
        ?.value ||
      ""
    )
      .trim()
      .toLowerCase();

  return metas.filter(
    (meta) => {
      const bateBusca =
        !termo ||
        meta.titulo
          .toLowerCase()
          .includes(
            termo
          ) ||
        meta.descricao
          .toLowerCase()
          .includes(
            termo
          ) ||
        meta.categoria
          .toLowerCase()
          .includes(
            termo
          );

      const bateFiltro =
        filtroAtual ===
          "todas" ||

        (
          filtroAtual ===
            "concluidas" &&
          meta.status ===
            "concluida"
        ) ||

        (
          filtroAtual ===
            "andamento" &&
          meta.status ===
            "em andamento"
        );

      return (
        bateBusca &&
        bateFiltro
      );
    }
  );
}

/* =========================================================
   CARD
========================================================= */

function criarMetaHTML(
  meta
) {
  const concluida =
    meta.status ===
    "concluida";

  return `
    <article
      class="meta-card ${
        concluida
          ? "concluida"
          : ""
      }"
      data-id="${meta.id}"
    >

      <div class="meta-card-topo">

        <span class="meta-categoria">
          <i data-lucide="tag"></i>
          ${escaparHTML(
            meta.categoria
          )}
        </span>

        <div class="meta-card-acoes">

          <button
            class="meta-icon-btn"
            type="button"
            data-action="editar"
            title="Editar meta"
          >
            <i data-lucide="pencil"></i>
          </button>

          <button
            class="meta-icon-btn danger"
            type="button"
            data-action="excluir"
            title="Excluir meta"
          >
            <i data-lucide="trash-2"></i>
          </button>

        </div>

      </div>

      <h3>
        ${escaparHTML(
          meta.titulo
        )}
      </h3>

      <p>
        ${escaparHTML(
          meta.descricao ||
          "Sem descrição."
        )}
      </p>

      <div class="meta-info">

        <span class="meta-prazo">
          <i data-lucide="calendar-days"></i>

          ${formatarPrazo(
            meta.prazo
          )}
        </span>

      </div>

      <div class="meta-card-status-row">

        <span
          class="meta-status ${
            concluida
              ? "concluida"
              : "andamento"
          }"
        >
          ${
            concluida
              ? "Concluída"
              : "Em andamento"
          }
        </span>

        <button
          class="${
            concluida
              ? "btn-reabrir"
              : "btn-concluir"
          }"
          type="button"
          data-action="alternar-status"
        >

          <i
            data-lucide="${
              concluida
                ? "rotate-ccw"
                : "circle-check-big"
            }"
          ></i>

          ${
            concluida
              ? "Reabrir meta"
              : "Marcar como concluída"
          }

        </button>

      </div>

    </article>
  `;
}

/* =========================================================
   RENDER
========================================================= */

function renderizarMetas() {
  atualizarResumo();

  if (
    !elementos.lista ||
    !elementos.estadoVazio
  ) {
    return;
  }

  const lista =
    filtrarMetas();

  if (
    lista.length === 0
  ) {
    elementos.lista.innerHTML =
      "";

    elementos.estadoVazio.classList.remove(
      "hidden"
    );

    const titulo =
      elementos.estadoVazio
        .querySelector(
          "h3"
        );

    const texto =
      elementos.estadoVazio
        .querySelector(
          "p"
        );

    if (
      metas.length === 0
    ) {
      if (titulo) {
        titulo.textContent =
          "Sua primeira meta começa aqui.";
      }

      if (texto) {
        texto.textContent =
          "Crie uma meta para começar a organizar seus objetivos.";
      }
    } else {
      if (titulo) {
        titulo.textContent =
          "Nenhuma meta encontrada.";
      }

      if (texto) {
        texto.textContent =
          "Tente outro termo ou filtro.";
      }
    }

    iniciarIcones();

    return;
  }

  elementos.estadoVazio.classList.add(
    "hidden"
  );

  elementos.lista.innerHTML =
    lista
      .map(
        criarMetaHTML
      )
      .join("");

  iniciarIcones();
}

/* =========================================================
   CARREGAR
========================================================= */

async function carregarMetas() {
  elementos.loading?.classList.remove(
    "hidden"
  );

  try {
    const dados =
      await listarMetasApi();

    metas =
      Array.isArray(
        dados
      )
        ? dados.map(
            normalizarMeta
          )
        : [];

    renderizarMetas();
  } catch (erro) {
    metas = [];

    renderizarMetas();

    tratarErro(
      erro
    );
  } finally {
    elementos.loading?.classList.add(
      "hidden"
    );
  }
}

/* =========================================================
   SALVAR
========================================================= */

async function salvarMeta(
  evento
) {
  evento.preventDefault();

  if (salvando) {
    return;
  }

  const titulo =
    elementos.titulo
      .value
      .trim();

  if (!titulo) {
    mostrarToast(
      "Digite o título da meta.",
      "error"
    );

    elementos.titulo.focus();

    return;
  }

  const id =
    Number(
      elementos.metaId
        .value ||
      0
    );

  const payload = {
    titulo,

    descricao:
      elementos.descricao
        .value
        .trim(),

    categoria:
      elementos.categoria
        .value,

    prazo:
      elementos.prazo
        .value ||
      null,
  };

  salvando = true;

  const botao =
    elementos.form
      .querySelector(
        '[type="submit"]'
      );

  if (botao) {
    botao.disabled =
      true;
  }

  try {
    const resposta =
      id
        ? await atualizarMetaApi(
            id,
            payload
          )
        : await criarMetaApi(
            payload
          );

    const meta =
      normalizarMeta(
        resposta
      );

    if (id) {
      metas =
        metas.map(
          (item) =>
            item.id === id
              ? meta
              : item
        );

      mostrarToast(
        "Meta atualizada!"
      );
    } else {
      metas.unshift(
        meta
      );

      mostrarToast(
        "Meta criada!"
      );
    }

    fecharModal();

    renderizarMetas();
  } catch (erro) {
    tratarErro(
      erro
    );
  } finally {
    salvando = false;

    if (botao) {
      botao.disabled =
        false;
    }
  }
}

/* =========================================================
   STATUS
========================================================= */

async function alternarStatus(
  meta,
  botao
) {
  const novoStatus =
    meta.status ===
    "concluida"
      ? "em andamento"
      : "concluida";

  botao.disabled =
    true;

  try {
    const resposta =
      await atualizarMetaApi(
        meta.id,
        {
          status:
            novoStatus,
        }
      );

    const atualizada =
      normalizarMeta(
        resposta
      );

    metas =
      metas.map(
        (item) =>
          item.id ===
            meta.id
            ? atualizada
            : item
      );

    renderizarMetas();

    mostrarToast(
      novoStatus ===
        "concluida"
        ? "Meta concluída! 🔥"
        : "Meta reaberta."
    );
  } catch (erro) {
    botao.disabled =
      false;

    tratarErro(
      erro
    );
  }
}

/* =========================================================
   EXCLUIR
========================================================= */

async function excluirMeta() {
  if (
    !metaParaExcluir
  ) {
    return;
  }

  const meta =
    metaParaExcluir;

  elementos.confirmarExclusao.disabled =
    true;

  try {
    await deletarMetaApi(
      meta.id
    );

    metas =
      metas.filter(
        (item) =>
          item.id !==
          meta.id
      );

    fecharModalExclusao();

    renderizarMetas();

    mostrarToast(
      "Meta excluída."
    );
  } catch (erro) {
    tratarErro(
      erro
    );
  } finally {
    elementos.confirmarExclusao.disabled =
      false;
  }
}

/* =========================================================
   EVENTOS
========================================================= */

elementos.abrirNovaMeta
  ?.addEventListener(
    "click",
    () =>
      abrirModal()
  );

elementos.abrirNovaMetaVazio
  ?.addEventListener(
    "click",
    () =>
      abrirModal()
  );

elementos.fecharMetaModal
  ?.addEventListener(
    "click",
    fecharModal
  );

elementos.cancelarMeta
  ?.addEventListener(
    "click",
    fecharModal
  );

elementos.form
  ?.addEventListener(
    "submit",
    salvarMeta
  );

elementos.busca
  ?.addEventListener(
    "input",
    renderizarMetas
  );

document
  .querySelectorAll(
    "[data-filter]"
  )
  .forEach(
    (botao) => {
      botao.addEventListener(
        "click",
        () => {
          filtroAtual =
            botao.dataset
              .filter ||
            "todas";

          document
            .querySelectorAll(
              "[data-filter]"
            )
            .forEach(
              (item) => {
                item.classList.toggle(
                  "active",
                  item ===
                    botao
                );
              }
            );

          renderizarMetas();
        }
      );
    }
  );

elementos.lista
  ?.addEventListener(
    "click",
    async (
      evento
    ) => {
      const botao =
        evento.target.closest(
          "button"
        );

      if (!botao) {
        return;
      }

      const card =
        botao.closest(
          ".meta-card"
        );

      const id =
        Number(
          card?.dataset
            .id ||
          0
        );

      const meta =
        metas.find(
          (item) =>
            item.id === id
        );

      if (!meta) {
        return;
      }

      const acao =
        botao.dataset
          .action;

      if (
        acao ===
        "editar"
      ) {
        abrirModal(
          meta
        );

        return;
      }

      if (
        acao ===
        "excluir"
      ) {
        abrirModalExclusao(
          meta
        );

        return;
      }

      if (
        acao ===
        "alternar-status"
      ) {
        await alternarStatus(
          meta,
          botao
        );
      }
    }
  );

elementos.cancelarExclusao
  ?.addEventListener(
    "click",
    fecharModalExclusao
  );

elementos.confirmarExclusao
  ?.addEventListener(
    "click",
    excluirMeta
  );

elementos.modal
  ?.addEventListener(
    "click",
    (
      evento
    ) => {
      if (
        evento.target ===
        elementos.modal
      ) {
        fecharModal();
      }
    }
  );

elementos.confirmarExclusaoModal
  ?.addEventListener(
    "click",
    (
      evento
    ) => {
      if (
        evento.target ===
        elementos
          .confirmarExclusaoModal
      ) {
        fecharModalExclusao();
      }
    }
  );

document.addEventListener(
  "keydown",
  (
    evento
  ) => {
    if (
      evento.key !==
      "Escape"
    ) {
      return;
    }

    fecharModal();

    fecharModalExclusao();
  }
);

/* =========================================================
   INICIALIZAÇÃO
========================================================= */

const shellOk =
  await initAppShell();

if (
  shellOk !== false
) {
  iniciarIcones();

  await carregarMetas();
}