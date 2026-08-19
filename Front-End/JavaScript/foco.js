import { initAppShell } from "./shared/app-shell.js";


/* =========================================================
   CONFIGURAÇÃO
========================================================= */

const API_BASE_URL =
  window.PACE_API_URL ||
  window.API_BASE_URL ||
  "http://127.0.0.1:8000";


const STORAGE_KEYS = {

  settings:
    "pace_focus_settings",

  active:
    "pace_focus_active",

};


const elementos = {

  sequenciaFoco:
    document.getElementById(
      "sequenciaFoco"
    ),

  tituloSessao:
    document.getElementById(
      "tituloSessao"
    ),

  estadoSessao:
    document.getElementById(
      "estadoSessao"
    ),

  timerDisplay:
    document.getElementById(
      "timerDisplay"
    ),

  timerRing:
    document.getElementById(
      "timerRing"
    ),

  intencaoAtiva:
    document.getElementById(
      "intencaoAtiva"
    ),

  iniciarSessao:
    document.getElementById(
      "iniciarSessao"
    ),

  resetarSessao:
    document.getElementById(
      "resetarSessao"
    ),

  finalizarSessao:
    document.getElementById(
      "finalizarSessao"
    ),

  intencaoSessao:
    document.getElementById(
      "intencaoSessao"
    ),

  metaVinculada:
    document.getElementById(
      "metaVinculada"
    ),


  /* NOVO DROPDOWN */

  metaPicker:
    document.getElementById(
      "metaPicker"
    ),

  metaPickerTrigger:
    document.getElementById(
      "metaPickerTrigger"
    ),

  metaPickerLabel:
    document.getElementById(
      "metaPickerLabel"
    ),

  metaPickerMenu:
    document.getElementById(
      "metaPickerMenu"
    ),

  metaPickerOptions:
    document.getElementById(
      "metaPickerOptions"
    ),

  metaPickerEmpty:
    document.getElementById(
      "metaPickerEmpty"
    ),


  duracaoSelecionada:
    document.getElementById(
      "duracaoSelecionada"
    ),

  duracaoPersonalizada:
    document.getElementById(
      "duracaoPersonalizada"
    ),

  aplicarDuracao:
    document.getElementById(
      "aplicarDuracao"
    ),

  toggleSom:
    document.getElementById(
      "toggleSom"
    ),

  entrarTelaCheia:
    document.getElementById(
      "entrarTelaCheia"
    ),

  tempoHoje:
    document.getElementById(
      "tempoHoje"
    ),

  sessoesConcluidas:
    document.getElementById(
      "sessoesConcluidas"
    ),

  melhorDia:
    document.getElementById(
      "melhorDia"
    ),

  historicoSessoes:
    document.getElementById(
      "historicoSessoes"
    ),

  historicoVazio:
    document.getElementById(
      "historicoVazio"
    ),

  limparHistorico:
    document.getElementById(
      "limparHistorico"
    ),

  immersiveMode:
    document.getElementById(
      "immersiveMode"
    ),

  immersiveTimer:
    document.getElementById(
      "immersiveTimer"
    ),

  immersiveIntention:
    document.getElementById(
      "immersiveIntention"
    ),

  immersivePause:
    document.getElementById(
      "immersivePause"
    ),

  immersiveFinish:
    document.getElementById(
      "immersiveFinish"
    ),

  sairImersivo:
    document.getElementById(
      "sairImersivo"
    ),

  conclusaoModal:
    document.getElementById(
      "conclusaoModal"
    ),

  conclusaoResumo:
    document.getElementById(
      "conclusaoResumo"
    ),

  conclusaoTempo:
    document.getElementById(
      "conclusaoTempo"
    ),

  conclusaoSequencia:
    document.getElementById(
      "conclusaoSequencia"
    ),

  fecharConclusao:
    document.getElementById(
      "fecharConclusao"
    ),

  confirmModal:
    document.getElementById(
      "confirmModal"
    ),

  confirmTitulo:
    document.getElementById(
      "confirmTitulo"
    ),

  confirmTexto:
    document.getElementById(
      "confirmTexto"
    ),

  cancelarConfirmacao:
    document.getElementById(
      "cancelarConfirmacao"
    ),

  aceitarConfirmacao:
    document.getElementById(
      "aceitarConfirmacao"
    ),

  toast:
    document.getElementById(
      "toast"
    ),

};


const defaultSettings = {

  durationMinutes: 25,

  soundEnabled: true,

};


let settings =
  carregarJSON(
    STORAGE_KEYS.settings,
    defaultSettings
  );


let activeSession =
  carregarJSON(
    STORAGE_KEYS.active,
    null
  );


let metas = [];

let history = [];

let timerInterval = null;

let pendingConfirmAction = null;

let finalizando = false;


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

    for (
      const chave of chaves
    ) {

      const token =
        storage.getItem(
          chave
        );


      if (
        token &&
        token.trim()
      ) {

        return token.trim();

      }

    }

  }


  return null;

}


/* =========================================================
   API
========================================================= */

function headers(
  json = false
) {

  const resultado = {};

  const token =
    obterToken();


  if (token) {

    resultado.Authorization =
      `Bearer ${token}`;

  }


  if (json) {

    resultado[
      "Content-Type"
    ] =
      "application/json";

  }


  return resultado;

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

          credentials:
            "include",

          ...opcoes,

          headers: {

            ...headers(
              opcoes.body !==
                undefined
            ),

            ...(opcoes.headers ||
              {}),

          },

        }
      );

  } catch {

    throw new Error(
      "Não foi possível conectar à API."
    );

  }


  let dados = null;


  try {

    dados =
      resposta.status ===
      204
        ? null
        : await resposta.json();

  } catch {

    dados = null;

  }


  if (
    resposta.status ===
    401
  ) {

    const erro =
      new Error(
        "Sua sessão expirou."
      );

    erro.status =
      401;

    throw erro;

  }


  if (!resposta.ok) {

    const erro =
      new Error(
        dados?.detail ||
        dados?.message ||
        "Erro na operação."
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


function listarSessoesApi(
  idMeta
) {

  return api(
    `/sessoes/meta/${idMeta}`
  );

}


function criarSessaoApi(
  payload
) {

  return api(
    "/sessoes/criar_sessao",
    {

      method:
        "POST",

      body:
        JSON.stringify(
          payload
        ),

    }
  );

}


function deletarSessaoApi(
  id
) {

  return api(
    `/sessoes/deletar_sessao/${id}`,
    {

      method:
        "DELETE",

    }
  );

}


/* =========================================================
   STORAGE
========================================================= */

function carregarJSON(
  chave,
  fallback
) {

  try {

    const valor =
      localStorage.getItem(
        chave
      );


    return valor
      ? JSON.parse(
          valor
        )
      : fallback;

  } catch {

    return fallback;

  }

}


function salvarJSON(
  chave,
  valor
) {

  localStorage.setItem(
    chave,
    JSON.stringify(
      valor
    )
  );

}


function removerStorage(
  chave
) {

  localStorage.removeItem(
    chave
  );

}


/* =========================================================
   UTILIDADES
========================================================= */

function iniciarIcones() {

  if (
    window.lucide &&
    typeof window.lucide
      .createIcons ===
      "function"
  ) {

    window.lucide.createIcons();

  }

}


function aplicarTemaSalvo() {

  const tema =
    localStorage.getItem(
      "darkMode"
    );


  document.body.classList.toggle(
    "dark",
    tema === "true" ||
      tema === "dark"
  );

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


  elementos.toast.textContent =
    mensagem;


  elementos.toast.className =
    `toast ${tipo}`;


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
    erro?.status ===
    401
  ) {

    mostrarToast(
      "Sua sessão expirou.",
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


function formatarTempo(
  segundos
) {

  const total =
    Math.max(
      0,
      Math.floor(
        segundos
      )
    );


  const min =
    Math.floor(
      total / 60
    );


  const seg =
    total % 60;


  return `${String(
    min
  ).padStart(
    2,
    "0"
  )}:${String(
    seg
  ).padStart(
    2,
    "0"
  )}`;

}


function formatarDuracao(
  segundos
) {

  const minutos =
    Math.max(
      0,
      Math.round(
        Number(
          segundos ||
          0
        ) /
        60
      )
    );


  if (
    minutos < 60
  ) {

    return `${minutos} min`;

  }


  const horas =
    Math.floor(
      minutos / 60
    );


  const restante =
    minutos % 60;


  return restante
    ? `${horas}h ${restante}min`
    : `${horas}h`;

}


function dataISO(
  data = new Date()
) {

  const ano =
    data.getFullYear();


  const mes =
    String(
      data.getMonth() +
      1
    ).padStart(
      2,
      "0"
    );


  const dia =
    String(
      data.getDate()
    ).padStart(
      2,
      "0"
    );


  return `${ano}-${mes}-${dia}`;

}


function formatarData(
  valor
) {

  const data =
    new Date(
      valor
    );


  if (
    Number.isNaN(
      data.getTime()
    )
  ) {

    return "Data indisponível";

  }


  return new Intl.DateTimeFormat(
    "pt-BR",
    {

      day:
        "2-digit",

      month:
        "short",

      hour:
        "2-digit",

      minute:
        "2-digit",

    }
  ).format(
    data
  );

}


/* =========================================================
   NORMALIZAÇÃO
========================================================= */

function normalizarMeta(
  meta
) {

  return {

    id:
      Number(
        meta.id
      ),

    titulo:
      String(
        meta.titulo ||
        "Meta sem título"
      ),

    status:
      String(
        meta.status ||
        ""
      )
        .trim()
        .toLowerCase() ===
      "concluida"
        ? "concluida"
        : "em andamento",

  };

}


/*
  IMPORTANTE:

  O BACKEND TRABALHA COM MINUTOS.

  Internamente o front transforma a duração
  das sessões em segundos para facilitar
  timer, gráficos e cálculos.
*/

function normalizarSessao(
  sessao,
  meta
) {

  const duracaoMinutos =
    Number(
      sessao?.duracao ||
      0
    );


  const durationSeconds =
    Math.max(
      0,
      duracaoMinutos *
        60
    );


  const inicio =
    sessao?.inicio ||
    null;


  let finishedAt =
    inicio;


  if (inicio) {

    const data =
      new Date(
        inicio
      );


    if (
      !Number.isNaN(
        data.getTime()
      )
    ) {

      finishedAt =
        new Date(
          data.getTime() +
            durationSeconds *
              1000
        ).toISOString();

    }

  }


  return {

    id:
      Number(
        sessao.id
      ),

    goalId:
      String(
        sessao.id_meta ||
        meta?.id ||
        ""
      ),

    goalTitle:
      String(
        meta?.titulo ||
        ""
      ),

    intention:
      meta?.titulo
        ? `Foco em ${meta.titulo}`
        : "Sessão de foco",

    durationSeconds,

    startedAt:
      inicio,

    finishedAt,

    date:
      inicio
        ? String(
            inicio
          ).slice(
            0,
            10
          )
        : null,

  };

}


/* =========================================================
   META PICKER
========================================================= */

function abrirMetaPicker() {

  if (
    !elementos.metaPicker ||
    !elementos.metaPickerMenu ||
    elementos.metaPickerTrigger
      ?.disabled
  ) {

    return;

  }


  const aberto =
    elementos.metaPicker
      .classList
      .contains(
        "open"
      );


  if (aberto) {

    fecharMetaPicker();

    return;

  }


  elementos.metaPicker
    .classList.add(
      "open"
    );


  elementos.metaPickerMenu
    .classList.remove(
      "hidden"
    );


  elementos.metaPickerTrigger
    ?.setAttribute(
      "aria-expanded",
      "true"
    );


  iniciarIcones();

}


function fecharMetaPicker() {

  elementos.metaPicker
    ?.classList.remove(
      "open"
    );


  elementos.metaPickerMenu
    ?.classList.add(
      "hidden"
    );


  elementos.metaPickerTrigger
    ?.setAttribute(
      "aria-expanded",
      "false"
    );

}


function atualizarMetaPickerSelecionada() {

  if (
    !elementos.metaVinculada ||
    !elementos.metaPickerLabel
  ) {

    return;

  }


  const metaId =
    String(
      elementos.metaVinculada
        .value ||
      ""
    );


  const meta =
    metas.find(
      (
        item
      ) =>
        String(
          item.id
        ) ===
        metaId
    );


  elementos.metaPickerLabel.textContent =
    meta
      ? meta.titulo
      : "Selecione uma meta em andamento";


  elementos.metaPickerOptions
    ?.querySelectorAll(
      ".meta-picker-option"
    )
    .forEach(
      (
        option
      ) => {

        const ativa =
          option.dataset.metaId ===
          metaId;


        option.classList.toggle(
          "active",
          ativa
        );


        option.setAttribute(
          "aria-selected",
          ativa
            ? "true"
            : "false"
        );

      }
    );


  iniciarIcones();

}


function selecionarMetaPicker(
  metaId
) {

  if (
    !elementos.metaVinculada
  ) {

    return;

  }


  elementos.metaVinculada.value =
    String(
      metaId
    );


  elementos.metaVinculada.dispatchEvent(
    new Event(
      "change",
      {

        bubbles: true,

      }
    )
  );


  atualizarMetaPickerSelecionada();

  fecharMetaPicker();

}


function renderizarMetaPicker() {

  if (
    !elementos.metaPickerOptions ||
    !elementos.metaPickerEmpty
  ) {

    return;

  }


  const metasEmAndamento =
    metas.filter(
      (
        meta
      ) =>
        meta.status ===
        "em andamento"
    );


  const vazio =
    metasEmAndamento.length ===
    0;


  elementos.metaPickerEmpty
    .classList.toggle(
      "hidden",
      !vazio
    );


  elementos.metaPickerOptions
    .classList.toggle(
      "hidden",
      vazio
    );


  if (vazio) {

    elementos.metaPickerOptions.innerHTML =
      "";


    atualizarMetaPickerSelecionada();

    iniciarIcones();

    return;

  }


  const selecionada =
    String(
      elementos.metaVinculada
        ?.value ||
      ""
    );


  elementos.metaPickerOptions.innerHTML =
    metasEmAndamento
      .map(
        (
          meta
        ) => {

          const ativa =
            String(
              meta.id
            ) ===
            selecionada;


          return `

            <button
              class="meta-picker-option ${
                ativa
                  ? "active"
                  : ""
              }"
              type="button"
              role="option"
              aria-selected="${
                ativa
                  ? "true"
                  : "false"
              }"
              data-meta-id="${meta.id}"
            >

              <span class="meta-picker-option-icon">

                <i data-lucide="target"></i>

              </span>


              <span class="meta-picker-option-copy">

                <strong>
                  ${escaparHTML(
                    meta.titulo
                  )}
                </strong>

                <small>
                  Meta em andamento
                </small>

              </span>


              <span class="meta-picker-option-check">

                <i data-lucide="check"></i>

              </span>

            </button>

          `;

        }
      )
      .join("");


  iniciarIcones();

}


function definirMetaPickerDesabilitado(
  desabilitado
) {

  if (
    elementos.metaVinculada
  ) {

    elementos.metaVinculada.disabled =
      desabilitado;

  }


  if (
    elementos.metaPickerTrigger
  ) {

    elementos.metaPickerTrigger.disabled =
      desabilitado;

  }


  if (desabilitado) {

    fecharMetaPicker();

  }

}


/* =========================================================
   CARREGAR METAS
========================================================= */

async function carregarMetas() {

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


  if (
    !elementos.metaVinculada
  ) {

    return;

  }


  const valorAnterior =
    elementos.metaVinculada
      .value;


  elementos.metaVinculada.innerHTML =
    `

      <option value="">
        Selecione uma meta
      </option>

    `;


  metas
    .filter(
      (
        meta
      ) =>
        meta.status ===
        "em andamento"
    )
    .forEach(
      (
        meta
      ) => {

        const option =
          document.createElement(
            "option"
          );


        option.value =
          String(
            meta.id
          );


        option.textContent =
          meta.titulo;


        elementos.metaVinculada
          .appendChild(
            option
          );

      }
    );


  if (
    valorAnterior &&
    metas.some(
      (
        meta
      ) =>
        String(
          meta.id
        ) ===
          String(
            valorAnterior
          ) &&
        meta.status ===
          "em andamento"
    )
  ) {

    elementos.metaVinculada.value =
      valorAnterior;

  }


  renderizarMetaPicker();

  atualizarMetaPickerSelecionada();

}


/* =========================================================
   HISTÓRICO API
========================================================= */

async function carregarHistorico() {

  if (
    metas.length ===
    0
  ) {

    history = [];

    return;

  }


  const resultados =
    await Promise.all(
      metas.map(
        async (
          meta
        ) => {

          try {

            const lista =
              await listarSessoesApi(
                meta.id
              );


            return Array.isArray(
              lista
            )
              ? lista.map(
                  (
                    sessao
                  ) =>
                    normalizarSessao(
                      sessao,
                      meta
                    )
                )
              : [];

          } catch (
            erro
          ) {

            if (
              erro.status ===
              401
            ) {

              throw erro;

            }


            console.warn(
              "Não foi possível carregar sessões da meta:",
              meta.id
            );


            return [];

          }

        }
      )
    );


  history =
    resultados
      .flat()
      .sort(
        (
          a,
          b
        ) =>

          new Date(
            b.startedAt ||
            0
          ) -

          new Date(
            a.startedAt ||
            0
          )

      );

}


async function carregarDados() {

  try {

    await carregarMetas();

    await carregarHistorico();

    atualizarResumo();

    renderizarHistorico();

  } catch (
    erro
  ) {

    tratarErro(
      erro
    );

  }

}


/* =========================================================
   DURAÇÃO
========================================================= */

function selecionarDuracao(
  minutos
) {

  const duracao =
    Math.min(
      240,
      Math.max(
        1,
        Number(
          minutos
        ) ||
        25
      )
    );


  settings.durationMinutes =
    duracao;


  salvarJSON(
    STORAGE_KEYS.settings,
    settings
  );


  document
    .querySelectorAll(
      ".duration-option"
    )
    .forEach(
      (
        botao
      ) => {

        botao.classList.toggle(
          "active",
          Number(
            botao.dataset
              .minutes
          ) ===
            duracao
        );

      }
    );


  if (
    elementos.duracaoSelecionada
  ) {

    elementos.duracaoSelecionada.textContent =
      `${duracao} min`;

  }


  if (
    !activeSession
  ) {

    renderizarTempo(
      duracao *
        60
    );

  }

}


/* =========================================================
   CRIAR SESSÃO LOCAL
========================================================= */

function criarSessaoLocal() {

  const metaId =
    String(
      elementos.metaVinculada
        ?.value ||
      ""
    );


  if (!metaId) {

    mostrarToast(
      "Escolha uma meta antes de iniciar.",
      "error"
    );


    abrirMetaPicker();

    return null;

  }


  const meta =
    metas.find(
      (
        item
      ) =>
        String(
          item.id
        ) ===
        metaId
    );


  if (!meta) {

    mostrarToast(
      "Meta não encontrada.",
      "error"
    );

    return null;

  }


  const intencao =
    String(
      elementos.intencaoSessao
        ?.value ||
      ""
    ).trim();


  return {

    goalId:
      metaId,

    goalTitle:
      meta.titulo,

    intention:
      intencao ||
      `Foco em ${meta.titulo}`,

    durationSeconds:
      settings.durationMinutes *
      60,

    elapsedBeforeStart:
      0,

    startedAt:
      Date.now(),

    createdAt:
      new Date()
        .toISOString(),

    status:
      "running",

  };

}


/* =========================================================
   TEMPO
========================================================= */

function tempoDecorrido(
  sessao = activeSession
) {

  if (
    !sessao
  ) {

    return 0;

  }


  const acumulado =
    Number(
      sessao
        .elapsedBeforeStart ||
      0
    );


  if (
    sessao.status !==
      "running" ||
    !sessao.startedAt
  ) {

    return acumulado;

  }


  const atual =
    Math.floor(
      (
        Date.now() -
        Number(
          sessao.startedAt
        )
      ) /
      1000
    );


  return Math.max(
    0,
    acumulado +
      atual
  );

}


function tempoRestante() {

  if (
    !activeSession
  ) {

    return (
      settings.durationMinutes *
      60
    );

  }


  return Math.max(
    0,

    Number(
      activeSession
        .durationSeconds
    ) -
      tempoDecorrido()

  );

}


function salvarAtiva() {

  if (
    activeSession
  ) {

    salvarJSON(
      STORAGE_KEYS.active,
      activeSession
    );

  } else {

    removerStorage(
      STORAGE_KEYS.active
    );

  }

}


/* =========================================================
   TIMER
========================================================= */

function iniciarTimer() {

  pararTimer();


  timerInterval =
    setInterval(
      atualizarTimer,
      250
    );


  atualizarTimer();

}


function pararTimer() {

  if (
    timerInterval
  ) {

    clearInterval(
      timerInterval
    );


    timerInterval =
      null;

  }

}


function atualizarTimer() {

  if (
    !activeSession
  ) {

    return;

  }


  const restante =
    tempoRestante();


  renderizarTempo(
    restante
  );


  if (
    restante <=
    0
  ) {

    finalizarSessao(
      true
    );

  }

}


function renderizarTempo(
  restante
) {

  const total =
    activeSession
      ? Number(
          activeSession
            .durationSeconds
        )
      : settings.durationMinutes *
        60;


  const decorrido =
    Math.max(
      0,
      total -
        restante
    );


  const progresso =
    total > 0
      ? decorrido /
        total
      : 0;


  const graus =
    Math.min(
      360,
      progresso *
        360
    );


  const texto =
    formatarTempo(
      restante
    );


  if (
    elementos.timerDisplay
  ) {

    elementos.timerDisplay.textContent =
      texto;

  }


  if (
    elementos.immersiveTimer
  ) {

    elementos.immersiveTimer.textContent =
      texto;

  }


  elementos.timerRing
    ?.style.setProperty(
      "--progress",
      `${graus}deg`
    );


  document.title =
    activeSession
      ? `${texto} | Sala de Foco`
      : "Sala de Foco | Pace";

}


/* =========================================================
   INICIAR / PAUSAR
========================================================= */

function iniciarOuPausar() {

  if (
    !activeSession
  ) {

    const nova =
      criarSessaoLocal();


    if (!nova) {

      return;

    }


    activeSession =
      nova;


    salvarAtiva();

    abrirImersivo();

    renderizarSessao();

    iniciarTimer();


    return;

  }


  if (
    activeSession.status ===
    "running"
  ) {

    activeSession.elapsedBeforeStart =
      tempoDecorrido();


    activeSession.startedAt =
      null;


    activeSession.status =
      "paused";


    salvarAtiva();

    pararTimer();

    renderizarSessao();


    return;

  }


  activeSession.startedAt =
    Date.now();


  activeSession.status =
    "running";


  salvarAtiva();

  abrirImersivo();

  renderizarSessao();

  iniciarTimer();

}


/* =========================================================
   FINALIZAR
========================================================= */

async function finalizarSessao(
  automatico = false
) {

  if (
    !activeSession ||
    finalizando
  ) {

    return;

  }


  finalizando =
    true;


  const snapshot = {

    ...activeSession,

  };


  const segundos =
    Math.min(
      snapshot.durationSeconds,
      tempoDecorrido(
        snapshot
      )
    );


  if (
    segundos <
    10
  ) {

    activeSession =
      null;


    salvarAtiva();

    pararTimer();

    fecharImersivo();

    renderizarSessao();


    mostrarToast(
      "Sessão curta demais para ser salva.",
      "error"
    );


    finalizando =
      false;


    return;

  }


  /*
    BACKEND = MINUTOS

    Exemplo:

    1500 segundos
          ↓
       25 min
          ↓
    API recebe 25
  */

  const minutos =
    Math.max(
      1,
      Math.round(
        segundos /
        60
      )
    );


  try {

    const resposta =
      await criarSessaoApi(
        {

          id_meta:
            Number(
              snapshot.goalId
            ),

          inicio:
            snapshot.createdAt,

          duracao:
            minutos,

        }
      );


    const meta =
      metas.find(
        (
          item
        ) =>
          String(
            item.id
          ) ===
          String(
            snapshot.goalId
          )
      );


    const salva =
      normalizarSessao(
        resposta,
        meta
      );


    history.unshift(
      salva
    );


    history.sort(
      (
        a,
        b
      ) =>

        new Date(
          b.startedAt ||
          0
        ) -

        new Date(
          a.startedAt ||
          0
        )

    );


    activeSession =
      null;


    salvarAtiva();

    pararTimer();

    fecharImersivo();

    atualizarResumo();

    renderizarHistorico();


    abrirConclusao(
      {

        ...salva,

        intention:
          snapshot.intention,

      }
    );


    if (
      automatico
    ) {

      tocarSomConclusao();

    }


    renderizarSessao();

  } catch (
    erro
  ) {

    activeSession =
      snapshot;


    salvarAtiva();


    tratarErro(
      erro
    );


    renderizarSessao();

  } finally {

    finalizando =
      false;

  }

}


/* =========================================================
   RESET
========================================================= */

function resetarSessao() {

  activeSession =
    null;


  salvarAtiva();

  pararTimer();

  fecharImersivo();

  renderizarSessao();


  mostrarToast(
    "Sessão reiniciada."
  );

}


/* =========================================================
   RENDER SESSÃO
========================================================= */

function renderizarSessao() {

  if (
    !activeSession
  ) {

    elementos.tituloSessao.textContent =
      "Pronto para começar?";


    elementos.estadoSessao.textContent =
      "Preparação";


    elementos.intencaoAtiva.textContent =
      "Defina uma intenção para sua sessão";


    elementos.iniciarSessao.innerHTML =
      `

        <i data-lucide="play"></i>

        <span>
          Iniciar foco
        </span>

      `;


    elementos.finalizarSessao.disabled =
      true;


    elementos.resetarSessao.disabled =
      true;


    elementos.intencaoSessao.disabled =
      false;


    definirMetaPickerDesabilitado(
      false
    );


    elementos.duracaoPersonalizada.disabled =
      false;


    elementos.aplicarDuracao.disabled =
      false;


    document
      .querySelectorAll(
        ".duration-option"
      )
      .forEach(
        (
          botao
        ) => {

          botao.disabled =
            false;

        }
      );


    renderizarTempo(
      settings.durationMinutes *
        60
    );


    iniciarIcones();


    return;

  }


  const rodando =
    activeSession.status ===
    "running";


  elementos.tituloSessao.textContent =
    rodando
      ? "Você está em foco."
      : "Sessão pausada.";


  elementos.estadoSessao.textContent =
    rodando
      ? "Foco ativo"
      : "Pausado";


  elementos.intencaoAtiva.textContent =
    activeSession.intention;


  elementos.immersiveIntention.textContent =
    activeSession.intention;


  elementos.iniciarSessao.innerHTML =
    rodando
      ? `

          <i data-lucide="pause"></i>

          <span>
            Pausar
          </span>

        `
      : `

          <i data-lucide="play"></i>

          <span>
            Continuar
          </span>

        `;


  elementos.immersivePause.innerHTML =
    rodando
      ? `

          <i data-lucide="pause"></i>

          Pausar

        `
      : `

          <i data-lucide="play"></i>

          Continuar

        `;


  elementos.finalizarSessao.disabled =
    false;


  elementos.resetarSessao.disabled =
    false;


  elementos.intencaoSessao.disabled =
    true;


  definirMetaPickerDesabilitado(
    true
  );


  elementos.duracaoPersonalizada.disabled =
    true;


  elementos.aplicarDuracao.disabled =
    true;


  document
    .querySelectorAll(
      ".duration-option"
    )
    .forEach(
      (
        botao
      ) => {

        botao.disabled =
          true;

      }
    );


  renderizarTempo(
    tempoRestante()
  );


  if (
    rodando
  ) {

    iniciarTimer();

  } else {

    pararTimer();

  }


  iniciarIcones();

}


/* =========================================================
   MODO IMERSIVO
========================================================= */

function abrirImersivo() {

  if (
    !activeSession
  ) {

    return;

  }


  elementos.immersiveMode
    ?.classList.remove(
      "hidden"
    );


  elementos.immersiveMode
    ?.setAttribute(
      "aria-hidden",
      "false"
    );


  elementos.immersiveIntention.textContent =
    activeSession.intention;


  document.body.style.overflow =
    "hidden";


  iniciarIcones();

}


function fecharImersivo() {

  elementos.immersiveMode
    ?.classList.add(
      "hidden"
    );


  elementos.immersiveMode
    ?.setAttribute(
      "aria-hidden",
      "true"
    );


  document.body.style.overflow =
    "";

}


/* =========================================================
   CONCLUSÃO
========================================================= */

function abrirConclusao(
  sessao
) {

  if (
    !elementos.conclusaoModal
  ) {

    return;

  }


  elementos.conclusaoResumo.textContent =
    `Você avançou em “${sessao.intention}”.`;


  elementos.conclusaoTempo.textContent =
    formatarDuracao(
      sessao.durationSeconds
    );


  const sequencia =
    calcularSequencia();


  elementos.conclusaoSequencia.textContent =
    `${sequencia} ${
      sequencia ===
      1
        ? "dia"
        : "dias"
    }`;


  elementos.conclusaoModal.classList.remove(
    "hidden"
  );


  iniciarIcones();

}


/* =========================================================
   SEQUÊNCIA
========================================================= */

function calcularSequencia() {

  const datas = [

    ...new Set(

      history

        .filter(
          (
            sessao
          ) =>
            sessao.durationSeconds >=
            60
        )

        .map(
          (
            sessao
          ) =>
            sessao.date
        )

        .filter(
          Boolean
        )

    ),

  ].sort(
    (
      a,
      b
    ) =>
      b.localeCompare(
        a
      )
  );


  if (
    datas.length ===
    0
  ) {

    return 0;

  }


  const hoje =
    new Date();


  hoje.setHours(
    12,
    0,
    0,
    0
  );


  const ontem =
    new Date(
      hoje
    );


  ontem.setDate(
    ontem.getDate() -
      1
  );


  const primeira =
    new Date(
      `${datas[0]}T12:00:00`
    );


  if (
    dataISO(
      primeira
    ) !==
      dataISO(
        hoje
      ) &&
    dataISO(
      primeira
    ) !==
      dataISO(
        ontem
      )
  ) {

    return 0;

  }


  let sequencia =
    1;


  let anterior =
    primeira;


  for (
    let i = 1;
    i < datas.length;
    i++
  ) {

    const atual =
      new Date(
        `${datas[i]}T12:00:00`
      );


    const diferenca =
      Math.round(
        (
          anterior -
          atual
        ) /
        86400000
      );


    if (
      diferenca ===
      1
    ) {

      sequencia++;

      anterior =
        atual;

    } else if (
      diferenca >
      1
    ) {

      break;

    }

  }


  return sequencia;

}


/* =========================================================
   RESUMO
========================================================= */

function atualizarResumo() {

  const hoje =
    dataISO();


  const segundosHoje =
    history

      .filter(
        (
          sessao
        ) =>
          sessao.date ===
          hoje
      )

      .reduce(
        (
          soma,
          sessao
        ) =>
          soma +
          sessao.durationSeconds,
        0
      );


  const dias = {};


  history.forEach(
    (
      sessao
    ) => {

      if (
        !sessao.date
      ) {

        return;

      }


      dias[
        sessao.date
      ] =
        (
          dias[
            sessao.date
          ] ||
          0
        ) +
        sessao.durationSeconds;

    }
  );


  const melhor =
    Object.values(
      dias
    ).sort(
      (
        a,
        b
      ) =>
        b -
        a
    )[0];


  elementos.tempoHoje.textContent =
    segundosHoje
      ? formatarDuracao(
          segundosHoje
        )
      : "0 min";


  elementos.sessoesConcluidas.textContent =
    String(
      history.length
    );


  elementos.melhorDia.textContent =
    melhor
      ? formatarDuracao(
          melhor
        )
      : "—";


  const sequencia =
    calcularSequencia();


  elementos.sequenciaFoco.textContent =
    `${sequencia} ${
      sequencia ===
      1
        ? "dia"
        : "dias"
    }`;

}


/* =========================================================
   HISTÓRICO
========================================================= */

function renderizarHistorico() {

  if (
    !elementos.historicoSessoes
  ) {

    return;

  }


  const vazio =
    history.length ===
    0;


  elementos.historicoVazio
    ?.classList.toggle(
      "hidden",
      !vazio
    );


  elementos.limparHistorico.disabled =
    vazio;


  if (vazio) {

    elementos.historicoSessoes.innerHTML =
      "";

    return;

  }


  elementos.historicoSessoes.innerHTML =
    history
      .slice(
        0,
        8
      )
      .map(
        (
          sessao
        ) => `

          <article class="history-item">

            <span class="history-item-icon">

              <i data-lucide="brain"></i>

            </span>


            <div class="history-item-copy">

              <strong>
                ${escaparHTML(
                  sessao.intention
                )}
              </strong>

              <span>

                ${formatarData(
                  sessao.startedAt
                )}

                ${
                  sessao.goalTitle
                    ? ` · ${escaparHTML(
                        sessao.goalTitle
                      )}`
                    : ""
                }

              </span>

            </div>


            <span class="history-duration">

              ${formatarDuracao(
                sessao.durationSeconds
              )}

            </span>

          </article>

        `
      )
      .join("");


  iniciarIcones();

}


/* =========================================================
   LIMPAR HISTÓRICO
========================================================= */

async function limparHistorico() {

  if (
    history.length ===
    0
  ) {

    return;

  }


  try {

    const resultados =
      await Promise.allSettled(

        history.map(
          (
            sessao
          ) =>
            deletarSessaoApi(
              sessao.id
            )
        )

      );


    const falhas =
      resultados.filter(
        (
          resultado
        ) =>
          resultado.status ===
          "rejected"
      );


    await carregarHistorico();

    atualizarResumo();

    renderizarHistorico();


    if (
      falhas.length >
      0
    ) {

      mostrarToast(
        `${falhas.length} sessão(ões) não puderam ser removidas.`,
        "error"
      );

    } else {

      mostrarToast(
        "Histórico limpo."
      );

    }

  } catch (
    erro
  ) {

    tratarErro(
      erro
    );

  }

}


/* =========================================================
   SOM
========================================================= */

function tocarSomConclusao() {

  if (
    !settings.soundEnabled
  ) {

    return;

  }


  try {

    const Context =
      window.AudioContext ||
      window.webkitAudioContext;


    const ctx =
      new Context();


    const notas = [

      523.25,

      659.25,

      783.99,

    ];


    notas.forEach(
      (
        frequencia,
        indice
      ) => {

        const osc =
          ctx.createOscillator();


        const gain =
          ctx.createGain();


        osc.frequency.value =
          frequencia;


        osc.type =
          "sine";


        const inicio =
          ctx.currentTime +
          indice *
          0.12;


        gain.gain.setValueAtTime(
          0.0001,
          inicio
        );


        gain.gain.exponentialRampToValueAtTime(
          0.13,
          inicio +
          0.02
        );


        gain.gain.exponentialRampToValueAtTime(
          0.0001,
          inicio +
          0.32
        );


        osc.connect(
          gain
        );


        gain.connect(
          ctx.destination
        );


        osc.start(
          inicio
        );


        osc.stop(
          inicio +
          0.35
        );

      }
    );

  } catch {

    // Som é apenas complementar.

  }

}


function alternarSom() {

  settings.soundEnabled =
    !settings.soundEnabled;


  salvarJSON(
    STORAGE_KEYS.settings,
    settings
  );


  atualizarBotaoSom();


  mostrarToast(
    settings.soundEnabled
      ? "Som ativado."
      : "Som desativado."
  );

}


function atualizarBotaoSom() {

  if (
    !elementos.toggleSom
  ) {

    return;

  }


  elementos.toggleSom.innerHTML =
    settings.soundEnabled
      ? '<i data-lucide="volume-2"></i>'
      : '<i data-lucide="volume-x"></i>';


  iniciarIcones();

}


/* =========================================================
   TELA CHEIA
========================================================= */

async function telaCheia() {

  try {

    if (
      !document.fullscreenElement
    ) {

      await document
        .documentElement
        .requestFullscreen();

    } else {

      await document
        .exitFullscreen();

    }

  } catch {

    mostrarToast(
      "Seu navegador bloqueou a tela cheia.",
      "error"
    );

  }

}


/* =========================================================
   CONFIRMAÇÃO
========================================================= */

function pedirConfirmacao(
  acao
) {

  pendingConfirmAction =
    acao;


  if (
    acao ===
    "finish"
  ) {

    elementos.confirmTitulo.textContent =
      "Finalizar sessão?";


    elementos.confirmTexto.textContent =
      "O tempo focado até agora será salvo.";


    elementos.aceitarConfirmacao.textContent =
      "Finalizar sessão";

  }


  if (
    acao ===
    "reset"
  ) {

    elementos.confirmTitulo.textContent =
      "Reiniciar sessão?";


    elementos.confirmTexto.textContent =
      "O tempo atual será descartado e o cronômetro voltará ao início.";


    elementos.aceitarConfirmacao.textContent =
      "Reiniciar";

  }


  if (
    acao ===
    "clear"
  ) {

    elementos.confirmTitulo.textContent =
      "Limpar histórico?";


    elementos.confirmTexto.textContent =
      "Todas as sessões registradas serão removidas da sua conta.";


    elementos.aceitarConfirmacao.textContent =
      "Limpar histórico";

  }


  elementos.confirmModal
    ?.classList.remove(
      "hidden"
    );


  iniciarIcones();

}


async function confirmarAcao() {

  elementos.confirmModal
    ?.classList.add(
      "hidden"
    );


  const acao =
    pendingConfirmAction;


  pendingConfirmAction =
    null;


  if (
    acao ===
    "finish"
  ) {

    await finalizarSessao();

    return;

  }


  if (
    acao ===
    "reset"
  ) {

    resetarSessao();

    return;

  }


  if (
    acao ===
    "clear"
  ) {

    await limparHistorico();

  }

}


/* =========================================================
   RESTAURAR SESSÃO
========================================================= */

function restaurarSessao() {

  if (
    !activeSession ||
    typeof activeSession !==
      "object"
  ) {

    activeSession =
      null;


    removerStorage(
      STORAGE_KEYS.active
    );


    return;

  }


  const duracao =
    Number(
      activeSession
        .durationSeconds
    );


  if (
    !Number.isFinite(
      duracao
    ) ||
    duracao <=
      0
  ) {

    activeSession =
      null;


    removerStorage(
      STORAGE_KEYS.active
    );


    return;

  }


  elementos.intencaoSessao.value =
    activeSession.intention ||
    "";


  if (
    elementos.metaVinculada
  ) {

    const optionExiste =
      [
        ...elementos.metaVinculada
          .options,
      ].some(
        (
          option
        ) =>
          option.value ===
          String(
            activeSession.goalId
          )
      );


    if (
      optionExiste
    ) {

      elementos.metaVinculada.value =
        String(
          activeSession.goalId
        );

    }

  }


  atualizarMetaPickerSelecionada();


  if (
    tempoRestante() <=
    0
  ) {

    finalizarSessao(
      true
    );


    return;

  }


  if (
    activeSession.status ===
    "running"
  ) {

    iniciarTimer();

  }

}


/* =========================================================
   EVENTOS
========================================================= */


/* DURAÇÕES */

document
  .querySelectorAll(
    ".duration-option"
  )
  .forEach(
    (
      botao
    ) => {

      botao.addEventListener(
        "click",
        () => {

          selecionarDuracao(
            Number(
              botao.dataset
                .minutes
            )
          );

        }
      );

    }
  );


elementos.aplicarDuracao
  ?.addEventListener(
    "click",
    () => {

      const valor =
        Number(
          elementos
            .duracaoPersonalizada
            .value
        );


      if (
        !Number.isFinite(
          valor
        ) ||
        valor <
          1 ||
        valor >
          240
      ) {

        mostrarToast(
          "Use um valor entre 1 e 240 minutos.",
          "error"
        );


        return;

      }


      selecionarDuracao(
        Math.round(
          valor
        )
      );


      elementos.duracaoPersonalizada.value =
        "";

    }
  );


/* META PICKER */

elementos.metaPickerTrigger
  ?.addEventListener(
    "click",
    (
      evento
    ) => {

      evento.stopPropagation();

      abrirMetaPicker();

    }
  );


elementos.metaPickerOptions
  ?.addEventListener(
    "click",
    (
      evento
    ) => {

      const botao =
        evento.target.closest(
          ".meta-picker-option"
        );


      if (!botao) {

        return;

      }


      selecionarMetaPicker(
        botao.dataset.metaId
      );

    }
  );


elementos.metaVinculada
  ?.addEventListener(
    "change",
    atualizarMetaPickerSelecionada
  );


document.addEventListener(
  "click",
  (
    evento
  ) => {

    if (
      !elementos.metaPicker
        ?.contains(
          evento.target
        )
    ) {

      fecharMetaPicker();

    }

  }
);


/* TIMER */

elementos.iniciarSessao
  ?.addEventListener(
    "click",
    iniciarOuPausar
  );


elementos.immersivePause
  ?.addEventListener(
    "click",
    iniciarOuPausar
  );


elementos.finalizarSessao
  ?.addEventListener(
    "click",
    () => {

      if (
        activeSession
      ) {

        pedirConfirmacao(
          "finish"
        );

      }

    }
  );


elementos.immersiveFinish
  ?.addEventListener(
    "click",
    () => {

      if (
        activeSession
      ) {

        fecharImersivo();


        pedirConfirmacao(
          "finish"
        );

      }

    }
  );


elementos.resetarSessao
  ?.addEventListener(
    "click",
    () => {

      if (
        activeSession
      ) {

        pedirConfirmacao(
          "reset"
        );

      }

    }
  );


/* HISTÓRICO */

elementos.limparHistorico
  ?.addEventListener(
    "click",
    () => {

      if (
        history.length >
        0
      ) {

        pedirConfirmacao(
          "clear"
        );

      }

    }
  );


/* MODAIS */

elementos.cancelarConfirmacao
  ?.addEventListener(
    "click",
    () => {

      pendingConfirmAction =
        null;


      elementos.confirmModal
        ?.classList.add(
          "hidden"
        );

    }
  );


elementos.aceitarConfirmacao
  ?.addEventListener(
    "click",
    confirmarAcao
  );


elementos.fecharConclusao
  ?.addEventListener(
    "click",
    () => {

      elementos.conclusaoModal
        ?.classList.add(
          "hidden"
        );

    }
  );


elementos.confirmModal
  ?.addEventListener(
    "click",
    (
      evento
    ) => {

      if (
        evento.target ===
        elementos.confirmModal
      ) {

        pendingConfirmAction =
          null;


        elementos.confirmModal.classList.add(
          "hidden"
        );

      }

    }
  );


elementos.conclusaoModal
  ?.addEventListener(
    "click",
    (
      evento
    ) => {

      if (
        evento.target ===
        elementos.conclusaoModal
      ) {

        elementos.conclusaoModal.classList.add(
          "hidden"
        );

      }

    }
  );


/* MODO IMERSIVO */

elementos.sairImersivo
  ?.addEventListener(
    "click",
    fecharImersivo
  );


/* SOM */

elementos.toggleSom
  ?.addEventListener(
    "click",
    alternarSom
  );


/* FULLSCREEN */

elementos.entrarTelaCheia
  ?.addEventListener(
    "click",
    telaCheia
  );


/* INTENÇÃO */

elementos.intencaoSessao
  ?.addEventListener(
    "input",
    () => {

      if (
        !activeSession
      ) {

        elementos.intencaoAtiva.textContent =
          elementos
            .intencaoSessao
            .value
            .trim() ||
          "Defina uma intenção para sua sessão";

      }

    }
  );


/* ESC */

document.addEventListener(
  "keydown",
  (
    evento
  ) => {

    if (
      evento.key ===
      "Escape"
    ) {

      fecharMetaPicker();


      if (
        !elementos.confirmModal
          ?.classList.contains(
            "hidden"
          )
      ) {

        pendingConfirmAction =
          null;


        elementos.confirmModal.classList.add(
          "hidden"
        );


        return;

      }


      if (
        !elementos.conclusaoModal
          ?.classList.contains(
            "hidden"
          )
      ) {

        elementos.conclusaoModal.classList.add(
          "hidden"
        );


        return;

      }


      fecharImersivo();

    }


    if (
      evento.code ===
        "Space" &&
      ![
        "INPUT",
        "SELECT",
        "TEXTAREA",
        "BUTTON",
      ].includes(
        document.activeElement
          ?.tagName
      )
    ) {

      evento.preventDefault();


      if (
        activeSession
      ) {

        iniciarOuPausar();

      }

    }

  }
);


/* TEMA */

window.addEventListener(
  "storage",
  (
    evento
  ) => {

    if (
      evento.key ===
        "darkMode" ||
      evento.key ===
        null
    ) {

      aplicarTemaSalvo();

    }

  }
);


/* RECARREGAR DADOS QUANDO VOLTAR */

document.addEventListener(
  "visibilitychange",
  async () => {

    if (
      !document.hidden
    ) {

      if (
        activeSession
      ) {

        atualizarTimer();

      }


      await carregarDados();

      atualizarMetaPickerSelecionada();

    }

  }
);


/* =========================================================
   INICIALIZAÇÃO
========================================================= */

const shellOk =
  await initAppShell();


if (
  shellOk !==
  false
) {

  aplicarTemaSalvo();


  selecionarDuracao(
    settings.durationMinutes
  );


  atualizarBotaoSom();


  await carregarDados();


  restaurarSessao();


  renderizarSessao();


  atualizarResumo();


  renderizarHistorico();


  atualizarMetaPickerSelecionada();


  iniciarIcones();

}