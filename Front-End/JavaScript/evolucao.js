import { initAppShell } from "./shared/app-shell.js";


/* =========================================================
   CONFIGURAÇÃO
========================================================= */

const API_BASE_URL =
  window.PACE_API_URL ||
  window.API_BASE_URL ||
  "http://127.0.0.1:8000";


const elementos = {

  scoreRing:
    document.getElementById(
      "scoreRing"
    ),

  evolutionScore:
    document.getElementById(
      "evolutionScore"
    ),

  scoreLabel:
    document.getElementById(
      "scoreLabel"
    ),

  evolutionTitle:
    document.getElementById(
      "evolutionTitle"
    ),

  evolutionDescription:
    document.getElementById(
      "evolutionDescription"
    ),

  comparisonIcon:
    document.getElementById(
      "comparisonIcon"
    ),

  comparisonText:
    document.getElementById(
      "comparisonText"
    ),

  statusSequencia:
    document.getElementById(
      "statusSequencia"
    ),

  statusMetas:
    document.getElementById(
      "statusMetas"
    ),

  statusFoco:
    document.getElementById(
      "statusFoco"
    ),

  nextStepTitle:
    document.getElementById(
      "nextStepTitle"
    ),

  nextStepDescription:
    document.getElementById(
      "nextStepDescription"
    ),

  nextStepLink:
    document.getElementById(
      "nextStepLink"
    ),

  nextStepButtonText:
    document.getElementById(
      "nextStepButtonText"
    ),

  nextStepIcon:
    document.getElementById(
      "nextStepIcon"
    ),

  totalFocusTime:
    document.getElementById(
      "totalFocusTime"
    ),

  completedGoals:
    document.getElementById(
      "completedGoals"
    ),

  currentStreak:
    document.getElementById(
      "currentStreak"
    ),

  completedSessions:
    document.getElementById(
      "completedSessions"
    ),

  focusDelta:
    document.getElementById(
      "focusDelta"
    ),

  goalsDelta:
    document.getElementById(
      "goalsDelta"
    ),

  streakDelta:
    document.getElementById(
      "streakDelta"
    ),

  sessionsDelta:
    document.getElementById(
      "sessionsDelta"
    ),

  weekChart:
    document.getElementById(
      "weekChart"
    ),

  weekChartHelper:
    document.getElementById(
      "weekChartHelper"
    ),

  evolutionTimeline:
    document.getElementById(
      "evolutionTimeline"
    ),

  timelineEmpty:
    document.getElementById(
      "timelineEmpty"
    ),

  consistencyTrack:
    document.getElementById(
      "consistencyTrack"
    ),

  bestWeekValue:
    document.getElementById(
      "bestWeekValue"
    ),

  bestWeekDescription:
    document.getElementById(
      "bestWeekDescription"
    ),

  consistencyPeriod:
    document.getElementById(
      "consistencyPeriod"
    ),

  categoryProgress:
    document.getElementById(
      "categoryProgress"
    ),

  categoryEmpty:
    document.getElementById(
      "categoryEmpty"
    ),

  bestMomentIcon:
    document.getElementById(
      "bestMomentIcon"
    ),

  bestMomentValue:
    document.getElementById(
      "bestMomentValue"
    ),

  bestMomentTitle:
    document.getElementById(
      "bestMomentTitle"
    ),

  bestMomentDescription:
    document.getElementById(
      "bestMomentDescription"
    ),

  insightIcon:
    document.getElementById(
      "insightIcon"
    ),

  insightTitle:
    document.getElementById(
      "insightTitle"
    ),

  insightDescription:
    document.getElementById(
      "insightDescription"
    ),

  achievementGrid:
    document.getElementById(
      "achievementGrid"
    ),

  achievementCounter:
    document.getElementById(
      "achievementCounter"
    ),

};


let periodoAtual =
  7;


let metas = [];

let sessoes = [];


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

      const valor =
        storage.getItem(
          chave
        );


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

async function api(
  rota
) {

  const token =
    obterToken();


  let resposta;


  try {

    resposta =
      await fetch(
        `${API_BASE_URL}${rota}`,
        {

          credentials:
            "include",

          headers:
            token
              ? {

                  Authorization:
                    `Bearer ${token}`,

                }
              : {},

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
      await resposta.json();

  } catch {

    dados = null;

  }


  if (
    resposta.status ===
    401
  ) {

    window.location.href =
      "entrar.html";


    throw new Error(
      "Sessão expirada."
    );

  }


  if (
    !resposta.ok
  ) {

    throw new Error(
      dados?.detail ||
      "Erro ao carregar dados."
    );

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
    tema ===
      "true" ||
      tema ===
      "dark"
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


function criarDataLocal(
  valor
) {

  if (
    !valor
  ) {

    return null;

  }


  const data =
    new Date(
      `${String(
        valor
      ).slice(
        0,
        10
      )}T12:00:00`
    );


  return Number.isNaN(
    data.getTime()
  )
    ? null
    : data;

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
    minutos <
    60
  ) {

    return `${minutos} min`;

  }


  const horas =
    Math.floor(
      minutos /
      60
    );


  const restante =
    minutos %
    60;


  return restante
    ? `${horas}h ${restante}min`
    : `${horas}h`;

}


function formatarDataCurta(
  data
) {

  if (
    !data ||
    Number.isNaN(
      data.getTime()
    )
  ) {

    return "—";

  }


  return new Intl.DateTimeFormat(
    "pt-BR",
    {

      day:
        "2-digit",

      month:
        "short",

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

  const status =
    String(
      meta?.status ||
      ""
    )
      .trim()
      .toLowerCase();


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

    categoria:
      String(
        meta.categoria ||
        "Outro"
      ),

    status:
      status ===
      "concluida"
        ? "concluida"
        : "em andamento",

    concluida:
      status ===
      "concluida",

  };

}


/*
  API = MINUTOS

  FRONT = SEGUNDOS
*/

function normalizarSessao(
  sessao,
  meta
) {

  const minutos =
    Math.max(
      0,
      Number(
        sessao?.duracao ||
        0
      )
    );


  const segundos =
    minutos *
    60;


  const inicio =
    sessao?.inicio ||
    null;


  return {

    id:
      Number(
        sessao.id
      ),

    goalId:
      String(
        sessao.id_meta ||
        meta.id
      ),

    goalTitle:
      meta.titulo,

    durationSeconds:
      segundos,

    startedAt:
      inicio,

    date:
      inicio
        ? String(
            inicio
          ).slice(
            0,
            10
          )
        : null,

    intention:
      `Foco em ${meta.titulo}`,

  };

}


/* =========================================================
   CARREGAR DADOS
========================================================= */

async function carregarDados() {

  try {

    const dadosMetas =
      await listarMetasApi();


    metas =
      Array.isArray(
        dadosMetas
      )
        ? dadosMetas.map(
            normalizarMeta
          )
        : [];


    const blocos =
      await Promise.all(
        metas.map(
          async (
            meta
          ) => {

            try {

              const dados =
                await listarSessoesApi(
                  meta.id
                );


              return Array.isArray(
                dados
              )
                ? dados.map(
                    (
                      sessao
                    ) =>
                      normalizarSessao(
                        sessao,
                        meta
                      )
                  )
                : [];

            } catch {

              return [];

            }

          }
        )
      );


    sessoes =
      blocos
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


    renderizarPagina();

  } catch (
    erro
  ) {

    console.error(
      erro
    );

  }

}


/* =========================================================
   PERÍODO
========================================================= */

function intervalo(
  dias,
  deslocamento = 0
) {

  const fim =
    new Date();


  fim.setHours(
    23,
    59,
    59,
    999
  );


  fim.setDate(
    fim.getDate() -
      deslocamento
  );


  const inicio =
    new Date(
      fim
    );


  inicio.setHours(
    0,
    0,
    0,
    0
  );


  inicio.setDate(
    inicio.getDate() -
      (
        dias -
        1
      )
  );


  return {

    inicio,

    fim,

  };

}


function sessoesPeriodo(
  dias,
  deslocamento = 0
) {

  const {
    inicio,
    fim,
  } =
    intervalo(
      dias,
      deslocamento
    );


  return sessoes.filter(
    (
      sessao
    ) => {

      const data =
        sessao.date
          ? criarDataLocal(
              sessao.date
            )
          : new Date(
              sessao.startedAt
            );


      return (
        data &&
        data >=
          inicio &&
        data <=
          fim
      );

    }
  );

}


/* =========================================================
   SEQUÊNCIA
========================================================= */

function calcularSequencia() {

  const datas = [

    ...new Set(

      sessoes

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
    criarDataLocal(
      datas[0]
    );


  if (
    !primeira
  ) {

    return 0;

  }


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
      criarDataLocal(
        datas[i]
      );


    if (
      !atual
    ) {

      continue;

    }


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

function gerarResumo(
  dias,
  deslocamento = 0
) {

  const lista =
    sessoesPeriodo(
      dias,
      deslocamento
    );


  const totalSegundos =
    lista.reduce(
      (
        total,
        sessao
      ) =>
        total +
        sessao.durationSeconds,
      0
    );


  const concluidas =
    metas.filter(
      (
        meta
      ) =>
        meta.concluida
    ).length;


  const andamento =
    metas.length -
    concluidas;


  const diasAtivos =
    new Set(
      lista
        .map(
          (
            sessao
          ) =>
            sessao.date
        )
        .filter(
          Boolean
        )
    ).size;


  const sequencia =
    deslocamento ===
    0
      ? calcularSequencia()
      : 0;


  return {

    sessoes:
      lista,

    totalSegundos,

    totalMinutos:
      Math.round(
        totalSegundos /
        60
      ),

    metasConcluidas:
      concluidas,

    metasEmAndamento:
      andamento,

    totalMetas:
      metas.length,

    diasAtivos,

    sequencia,

  };

}


/* =========================================================
   ÍNDICE PACE
========================================================= */

function calcularScore(
  resumo
) {

  if (
    resumo.totalMetas ===
      0 &&
    resumo.sessoes.length ===
      0
  ) {

    return 0;

  }


  /*
    Não existe mais porcentagem manual de meta.

    A única razão percentual aqui é:

    metas concluídas
        ÷
    total de metas

    Isso representa resultado global,
    não progresso digitado pelo usuário.
  */

  const taxaMetas =
    resumo.totalMetas >
    0
      ? (
          resumo.metasConcluidas /
          resumo.totalMetas
        ) *
        100
      : 0;


  const metasScore =
    taxaMetas *
    0.3;


  const focoScore =
    Math.min(
      25,
      resumo.totalMinutos /
        12
    );


  const sequenciaScore =
    Math.min(
      20,
      resumo.sequencia *
        3
    );


  const constanciaScore =
    Math.min(
      15,
      resumo.diasAtivos *
        2
    );


  const conclusoesScore =
    Math.min(
      10,
      resumo.metasConcluidas *
        2
    );


  return Math.min(
    100,
    Math.round(

      metasScore +

      focoScore +

      sequenciaScore +

      constanciaScore +

      conclusoesScore

    )
  );

}


/* =========================================================
   ATUALIZAR ÍNDICE
========================================================= */

function atualizarIndice(
  resumo
) {

  const score =
    calcularScore(
      resumo
    );


  let label =
    "Sua jornada começa agora";


  let titulo =
    "Sua evolução começa com o primeiro passo.";


  let descricao =
    "Crie uma meta ou faça uma sessão de foco para começar.";


  if (
    score >=
    25
  ) {

    label =
      "Ritmo em construção";


    titulo =
      "Seu progresso está ganhando forma.";


    descricao =
      "Continue repetindo as ações que estão funcionando.";

  }


  if (
    score >=
    50
  ) {

    label =
      "Constância sólida";


    titulo =
      "Sua consistência já está aparecendo.";


    descricao =
      "Metas e foco estão trabalhando juntos.";

  }


  if (
    score >=
    75
  ) {

    label =
      "Alta evolução";


    titulo =
      "Você está vivendo um ótimo momento.";


    descricao =
      "Continue protegendo sua rotina e concluindo seus objetivos.";

  }


  elementos.evolutionScore.textContent =
    String(
      score
    );


  elementos.scoreLabel.textContent =
    label;


  elementos.evolutionTitle.textContent =
    titulo;


  elementos.evolutionDescription.textContent =
    descricao;


  elementos.scoreRing
    ?.style.setProperty(
      "--score-progress",
      `${score * 3.6}deg`
    );


  elementos.statusSequencia.textContent =
    `${resumo.sequencia} ${
      resumo.sequencia ===
      1
        ? "dia"
        : "dias"
    } de sequência`;


  elementos.statusMetas.textContent =
    `${resumo.metasConcluidas} ${
      resumo.metasConcluidas ===
      1
        ? "meta concluída"
        : "metas concluídas"
    }`;


  elementos.statusFoco.textContent =
    `${formatarDuracao(
      resumo.totalSegundos
    )} de foco`;

}


/* =========================================================
   COMPARAÇÃO
========================================================= */

function atualizarComparacao(
  atual,
  anterior
) {

  if (
    anterior.totalSegundos ===
    0
  ) {

    elementos.comparisonText.textContent =
      atual.totalSegundos >
      0
        ? "Primeiro período com atividade registrada"
        : "Sem dados suficientes";


    elementos.comparisonIcon.setAttribute(
      "data-lucide",
      atual.totalSegundos >
      0
        ? "sparkles"
        : "minus"
    );


    return;

  }


  const variacao =
    Math.round(
      (
        (
          atual.totalSegundos -
          anterior.totalSegundos
        ) /
        anterior.totalSegundos
      ) *
      100
    );


  if (
    variacao >
    0
  ) {

    elementos.comparisonText.textContent =
      `${variacao}% mais tempo focado`;


    elementos.comparisonIcon.setAttribute(
      "data-lucide",
      "trending-up"
    );

  } else if (
    variacao <
    0
  ) {

    elementos.comparisonText.textContent =
      `${Math.abs(
        variacao
      )}% menos tempo focado`;


    elementos.comparisonIcon.setAttribute(
      "data-lucide",
      "trending-down"
    );

  } else {

    elementos.comparisonText.textContent =
      "Mesmo ritmo do período anterior";


    elementos.comparisonIcon.setAttribute(
      "data-lucide",
      "equal"
    );

  }

}


/* =========================================================
   MÉTRICAS
========================================================= */

function atualizarMetricas(
  resumo,
  anterior
) {

  elementos.totalFocusTime.textContent =
    formatarDuracao(
      resumo.totalSegundos
    );


  elementos.completedGoals.textContent =
    String(
      resumo.metasConcluidas
    );


  elementos.currentStreak.textContent =
    `${resumo.sequencia} ${
      resumo.sequencia ===
      1
        ? "dia"
        : "dias"
    }`;


  elementos.completedSessions.textContent =
    String(
      resumo.sessoes.length
    );


  const delta =
    resumo.totalSegundos -
    anterior.totalSegundos;


  elementos.focusDelta.textContent =
    delta >
    0
      ? `+${formatarDuracao(
          delta
        )}`
      : delta <
        0
        ? `-${formatarDuracao(
            Math.abs(
              delta
            )
          )}`
        : "Mesmo ritmo anterior";


  elementos.goalsDelta.textContent =
    resumo.metasConcluidas
      ? `${resumo.metasConcluidas} alcançada${
          resumo.metasConcluidas ===
          1
            ? ""
            : "s"
        }`
      : "Nenhuma conclusão";


  elementos.streakDelta.textContent =
    resumo.sequencia
      ? "Sua constância está ativa"
      : "Comece uma sequência hoje";


  const deltaSessoes =
    resumo.sessoes.length -
    anterior.sessoes.length;


  elementos.sessionsDelta.textContent =
    deltaSessoes >
    0
      ? `+${deltaSessoes} ${
          deltaSessoes ===
          1
            ? "sessão"
            : "sessões"
        }`
      : deltaSessoes <
        0
        ? `${Math.abs(
            deltaSessoes
          )} a menos`
        : "Mesmo volume anterior";

}


/* =========================================================
   PRÓXIMO PASSO
========================================================= */

function atualizarProximoPasso(
  resumo
) {

  let dados;


  if (
    resumo.totalMetas ===
    0
  ) {

    dados = {

      titulo:
        "Defina onde quer chegar",

      descricao:
        "Crie sua primeira meta para dar direção à sua evolução.",

      link:
        "metas.html",

      texto:
        "Criar uma meta",

      icon:
        "target",

    };

  } else if (
    resumo.sessoes.length ===
    0
  ) {

    dados = {

      titulo:
        "Transforme intenção em ação",

      descricao:
        "Inicie uma sessão de foco vinculada a uma meta.",

      link:
        "foco.html",

      texto:
        "Iniciar sessão",

      icon:
        "brain",

    };

  } else if (
    resumo.metasEmAndamento >
    0
  ) {

    dados = {

      titulo:
        "Continue avançando",

      descricao:
        `Você possui ${resumo.metasEmAndamento} ${
          resumo.metasEmAndamento ===
          1
            ? "meta em andamento"
            : "metas em andamento"
        }.`,

      link:
        "metas.html",

      texto:
        "Ver metas",

      icon:
        "target",

    };

  } else {

    dados = {

      titulo:
        "Escolha o próximo desafio",

      descricao:
        "Suas metas atuais estão concluídas.",

      link:
        "metas.html",

      texto:
        "Nova meta",

      icon:
        "sparkles",

    };

  }


  elementos.nextStepTitle.textContent =
    dados.titulo;


  elementos.nextStepDescription.textContent =
    dados.descricao;


  elementos.nextStepLink.href =
    dados.link;


  elementos.nextStepButtonText.textContent =
    dados.texto;


  elementos.nextStepIcon.setAttribute(
    "data-lucide",
    dados.icon
  );

}


/* =========================================================
   GRÁFICO 7 DIAS
========================================================= */

function renderizarGrafico() {

  const dias = [];


  for (
    let i = 6;
    i >= 0;
    i--
  ) {

    const data =
      new Date();


    data.setDate(
      data.getDate() -
      i
    );


    data.setHours(
      12,
      0,
      0,
      0
    );


    const chave =
      dataISO(
        data
      );


    const segundos =
      sessoes

        .filter(
          (
            sessao
          ) =>
            sessao.date ===
            chave
        )

        .reduce(
          (
            total,
            sessao
          ) =>
            total +
            sessao.durationSeconds,
          0
        );


    dias.push(
      {

        data,

        segundos,

      }
    );

  }


  const maior =
    Math.max(
      ...dias.map(
        (
          item
        ) =>
          item.segundos
      ),
      1
    );


  const formatador =
    new Intl.DateTimeFormat(
      "pt-BR",
      {

        weekday:
          "short",

      }
    );


  elementos.weekChart.innerHTML =
    dias
      .map(
        (
          item
        ) => {

          const altura =
            item.segundos
              ? Math.max(
                  8,
                  (
                    item.segundos /
                    maior
                  ) *
                    100
                )
              : 2;


          return `

            <div class="day-column">

              <span class="day-value">

                ${
                  item.segundos
                    ? `${Math.round(
                        item.segundos /
                        60
                      )}m`
                    : "0"
                }

              </span>


              <div class="bar-shell">

                <span
                  class="day-bar ${
                    !item.segundos
                      ? "zero"
                      : ""
                  }"
                  style="height:${altura}%"
                ></span>

              </div>


              <span class="day-label">

                ${formatador
                  .format(
                    item.data
                  )
                  .replace(
                    ".",
                    ""
                  )
                  .slice(
                    0,
                    3
                  )}

              </span>

            </div>

          `;

        }
      )
      .join("");


  elementos.weekChartHelper.textContent =
    "Últimos 7 dias";

}


/* =========================================================
   TIMELINE
========================================================= */

function renderizarTimeline() {

  const eventos =
    sessoes
      .map(
        (
          sessao
        ) => {

          return {

            date:
              new Date(
                sessao.startedAt
              ),

            title:
              sessao.intention,

            description:
              `${formatarDuracao(
                sessao.durationSeconds
              )} de foco`,

            icon:
              "brain",

          };

        }
      )
      .filter(
        (
          evento
        ) =>
          !Number.isNaN(
            evento.date.getTime()
          )
      )
      .sort(
        (
          a,
          b
        ) =>
          b.date -
          a.date
      )
      .slice(
        0,
        8
      );


  const vazio =
    eventos.length ===
    0;


  elementos.timelineEmpty
    ?.classList.toggle(
      "hidden",
      !vazio
    );


  elementos.evolutionTimeline.innerHTML =
    vazio
      ? ""
      : eventos
          .map(
            (
              evento
            ) => `

              <article class="timeline-item">

                <span class="timeline-marker">

                  <i data-lucide="${evento.icon}"></i>

                </span>


                <div class="timeline-content">

                  <span class="timeline-date">

                    ${formatarDataCurta(
                      evento.date
                    )}

                  </span>


                  <h3>

                    ${escaparHTML(
                      evento.title
                    )}

                  </h3>


                  <p>

                    ${escaparHTML(
                      evento.description
                    )}

                  </p>

                </div>

              </article>

            `
          )
          .join("");

}


/* =========================================================
   TRILHA DE CONSTÂNCIA
========================================================= */

function obterUltimasSemanas(
  quantidade =
    12
) {

  const semanas = [];


  const hoje =
    new Date();


  hoje.setHours(
    12,
    0,
    0,
    0
  );


  const diaSemana =
    hoje.getDay();


  const ajusteSegunda =
    diaSemana ===
    0
      ? -6
      : 1 -
        diaSemana;


  const inicioSemanaAtual =
    new Date(
      hoje
    );


  inicioSemanaAtual.setDate(
    hoje.getDate() +
      ajusteSegunda
  );


  for (
    let indice =
      quantidade -
      1;
    indice >=
    0;
    indice--
  ) {

    const inicio =
      new Date(
        inicioSemanaAtual
      );


    inicio.setDate(
      inicio.getDate() -
      indice *
        7
    );


    inicio.setHours(
      0,
      0,
      0,
      0
    );


    const fim =
      new Date(
        inicio
      );


    fim.setDate(
      fim.getDate() +
      6
    );


    fim.setHours(
      23,
      59,
      59,
      999
    );


    semanas.push(
      {

        inicio,

        fim,

      }
    );

  }


  return semanas;

}


function calcularDadosDaSemana(
  inicio,
  fim
) {

  const sessoesDaSemana =
    sessoes.filter(
      (
        sessao
      ) => {

        const data =
          sessao.date
            ? criarDataLocal(
                sessao.date
              )
            : new Date(
                sessao.startedAt
              );


        return (
          data &&
          data >=
            inicio &&
          data <=
            fim
        );

      }
    );


  const totalSegundos =
    sessoesDaSemana.reduce(
      (
        soma,
        sessao
      ) =>
        soma +
        sessao.durationSeconds,
      0
    );


  const diasAtivos =
    new Set(
      sessoesDaSemana
        .map(
          (
            sessao
          ) =>
            sessao.date
        )
        .filter(
          Boolean
        )
    ).size;


  return {

    totalSegundos,

    diasAtivos,

    totalSessoes:
      sessoesDaSemana.length,

  };

}


function renderizarTrilhaDeConstancia() {

  if (
    !elementos.consistencyTrack
  ) {

    return;

  }


  const semanas =
    obterUltimasSemanas(
      12
    );


  const dados =
    semanas.map(
      (
        semana,
        indice
      ) => {

        const resumo =
          calcularDadosDaSemana(
            semana.inicio,
            semana.fim
          );


        return {

          ...semana,

          ...resumo,

          numero:
            indice +
            1,

        };

      }
    );


  const maiorTempo =
    Math.max(
      ...dados.map(
        (
          semana
        ) =>
          semana.totalSegundos
      ),
      1
    );


  const melhorSemana =
    dados.reduce(
      (
        melhor,
        semana
      ) =>
        semana.totalSegundos >
        melhor.totalSegundos
          ? semana
          : melhor,
      dados[0]
    );


  elementos.consistencyTrack.innerHTML =
    dados
      .map(
        (
          semana
        ) => {

          const porcentagem =
            semana.totalSegundos >
            0
              ? Math.max(
                  10,
                  Math.round(
                    (
                      semana.totalSegundos /
                      maiorTempo
                    ) *
                    100
                  )
                )
              : 0;


          const ativa =
            semana.totalSegundos >
            0;


          const atual =
            semana.numero ===
            dados.length;


          return `

            <article
              class="consistency-week ${
                ativa
                  ? "active"
                  : ""
              } ${
                atual
                  ? "current"
                  : ""
              }"
            >

              <div class="week-indicator">

                <span class="week-dot"></span>

                <span class="week-line"></span>

              </div>


              <div class="week-content">

                <div class="week-heading">

                  <div>

                    <small>
                      Semana ${semana.numero}
                    </small>

                    <strong>

                      ${formatarDataCurta(
                        semana.inicio
                      )}

                      —

                      ${formatarDataCurta(
                        semana.fim
                      )}

                    </strong>

                  </div>


                  <span>

                    ${formatarDuracao(
                      semana.totalSegundos
                    )}

                  </span>

                </div>


                <div class="week-progress">

                  <span
                    style="width:${porcentagem}%"
                  ></span>

                </div>


                <div class="week-details">

                  <span>

                    <i data-lucide="brain"></i>

                    ${semana.totalSessoes}

                    ${
                      semana.totalSessoes ===
                      1
                        ? "sessão"
                        : "sessões"
                    }

                  </span>


                  <span>

                    <i data-lucide="calendar-check-2"></i>

                    ${semana.diasAtivos}

                    ${
                      semana.diasAtivos ===
                      1
                        ? "dia ativo"
                        : "dias ativos"
                    }

                  </span>

                </div>

              </div>

            </article>

          `;

        }
      )
      .join("");


  if (
    melhorSemana &&
    melhorSemana.totalSegundos >
    0
  ) {

    elementos.bestWeekValue.textContent =
      formatarDuracao(
        melhorSemana.totalSegundos
      );


    elementos.bestWeekDescription.textContent =
      `${melhorSemana.totalSessoes} ${
        melhorSemana.totalSessoes ===
        1
          ? "sessão"
          : "sessões"
      } em ${melhorSemana.diasAtivos} ${
        melhorSemana.diasAtivos ===
        1
          ? "dia ativo"
          : "dias ativos"
      }.`;

  } else {

    elementos.bestWeekValue.textContent =
      "—";


    elementos.bestWeekDescription.textContent =
      "Continue registrando sessões para revelar seu melhor período.";

  }


  elementos.consistencyPeriod.textContent =
    "Últimas 12 semanas";

}


/* =========================================================
   CATEGORIAS
========================================================= */

function renderizarCategorias() {

  if (
    metas.length ===
    0
  ) {

    elementos.categoryProgress.innerHTML =
      "";


    elementos.categoryEmpty
      ?.classList.remove(
        "hidden"
      );


    return;

  }


  elementos.categoryEmpty
    ?.classList.add(
      "hidden"
    );


  const categorias = {};


  metas.forEach(
    (
      meta
    ) => {

      const nome =
        meta.categoria ||
        "Outro";


      if (
        !categorias[
          nome
        ]
      ) {

        categorias[
          nome
        ] = {

          total:
            0,

          concluidas:
            0,

        };

      }


      categorias[
        nome
      ].total++;


      if (
        meta.concluida
      ) {

        categorias[
          nome
        ].concluidas++;

      }

    }
  );


  elementos.categoryProgress.innerHTML =
    Object.entries(
      categorias
    )
      .map(
        ([
          nome,
          dados,
        ]) => {

          /*
            Esta barra NÃO é progresso manual.

            Ela representa:

            metas concluídas
                  /
            metas da categoria
          */

          const porcentagem =
            dados.total >
            0
              ? Math.round(
                  (
                    dados.concluidas /
                    dados.total
                  ) *
                  100
                )
              : 0;


          return `

            <article class="category-item">

              <div class="category-top">

                <div class="category-name">

                  <span class="category-icon">

                    <i data-lucide="tag"></i>

                  </span>


                  <strong>

                    ${escaparHTML(
                      nome
                    )}

                  </strong>

                </div>


                <span class="category-percent">

                  ${dados.concluidas}/${dados.total}

                </span>

              </div>


              <div class="category-progress">

                <span
                  style="width:${porcentagem}%"
                ></span>

              </div>

            </article>

          `;

        }
      )
      .join("");

}


/* =========================================================
   MELHOR MOMENTO
========================================================= */

function renderizarMelhorMomento() {

  if (
    sessoes.length ===
    0
  ) {

    elementos.bestMomentValue.textContent =
      "—";


    elementos.bestMomentTitle.textContent =
      "Ainda sem um destaque";


    elementos.bestMomentDescription.textContent =
      "Faça sessões de foco para construir seu histórico.";


    elementos.bestMomentIcon.setAttribute(
      "data-lucide",
      "sparkles"
    );


    return;

  }


  const melhor =
    sessoes.reduce(
      (
        atual,
        sessao
      ) =>
        sessao.durationSeconds >
        atual.durationSeconds
          ? sessao
          : atual
    );


  elementos.bestMomentValue.textContent =
    formatarDuracao(
      melhor.durationSeconds
    );


  elementos.bestMomentTitle.textContent =
    "Sua sessão mais profunda";


  elementos.bestMomentDescription.textContent =
    melhor.goalTitle
      ? `Foco dedicado à meta “${melhor.goalTitle}”.`
      : "Seu melhor momento de concentração.";


  elementos.bestMomentIcon.setAttribute(
    "data-lucide",
    "brain"
  );

}


/* =========================================================
   INSIGHT
========================================================= */

function renderizarInsight(
  resumo
) {

  let icon =
    "lightbulb";


  let titulo =
    "Comece a gerar seu histórico.";


  let descricao =
    "Suas metas e sessões serão analisadas aqui.";


  if (
    resumo.totalMetas >
      0 &&
    resumo.sessoes.length ===
      0
  ) {

    icon =
      "brain";


    titulo =
      "Você já tem direção.";


    descricao =
      "Agora transforme suas metas em tempo de foco.";

  } else if (
    resumo.sequencia >=
    7
  ) {

    icon =
      "flame";


    titulo =
      "Sua constância já passou de uma semana.";


    descricao =
      "Você está construindo um padrão forte.";

  } else if (
    resumo.metasEmAndamento ===
      0 &&
    resumo.metasConcluidas >
      0
  ) {

    icon =
      "trophy";


    titulo =
      "Você concluiu todas as metas atuais.";


    descricao =
      "Esse é um ótimo momento para definir o próximo desafio.";

  } else if (
    resumo.diasAtivos >=
    4
  ) {

    icon =
      "calendar-check-2";


    titulo =
      "Seu esforço está bem distribuído.";


    descricao =
      "Você esteve ativo em vários dias do período.";

  } else if (
    resumo.sessoes.length >
    0
  ) {

    icon =
      "footprints";


    titulo =
      "Seu ritmo está começando a aparecer.";


    descricao =
      "Continue focando e concluindo metas.";

  }


  elementos.insightIcon.setAttribute(
    "data-lucide",
    icon
  );


  elementos.insightTitle.textContent =
    titulo;


  elementos.insightDescription.textContent =
    descricao;

}


/* =========================================================
   CONQUISTAS
========================================================= */

function renderizarConquistas(
  resumo
) {

  const totalFoco =
    sessoes.reduce(
      (
        total,
        sessao
      ) =>
        total +
        sessao.durationSeconds,
      0
    );


  const conquistas = [

    {

      nome:
        "Primeiro passo",

      descricao:
        "Faça sua primeira sessão.",

      icon:
        "footprints",

      ok:
        sessoes.length >=
        1,

    },

    {

      nome:
        "Objetivo alcançado",

      descricao:
        "Conclua sua primeira meta.",

      icon:
        "trophy",

      ok:
        resumo.metasConcluidas >=
        1,

    },

    {

      nome:
        "Uma hora de presença",

      descricao:
        "Acumule uma hora de foco.",

      icon:
        "clock-3",

      ok:
        totalFoco >=
        3600,

    },

    {

      nome:
        "Constância",

      descricao:
        "Mantenha três dias seguidos.",

      icon:
        "flame",

      ok:
        resumo.sequencia >=
        3,

    },

    {

      nome:
        "Cinco metas",

      descricao:
        "Conclua cinco metas.",

      icon:
        "list-checks",

      ok:
        resumo.metasConcluidas >=
        5,

    },

    {

      nome:
        "Foco profundo",

      descricao:
        "Faça uma sessão de 60 minutos.",

      icon:
        "brain",

      ok:
        sessoes.some(
          (
            sessao
          ) =>
            sessao.durationSeconds >=
            3600
        ),

    },

  ];


  const desbloqueadas =
    conquistas.filter(
      (
        item
      ) =>
        item.ok
    ).length;


  elementos.achievementCounter.textContent =
    `${desbloqueadas} de ${conquistas.length}`;


  elementos.achievementGrid.innerHTML =
    conquistas
      .map(
        (
          item
        ) => `

          <article
            class="achievement-card ${
              item.ok
                ? "unlocked"
                : "locked"
            }"
          >

            ${
              item.ok
                ? `

                  <span class="achievement-state">
                    Desbloqueada
                  </span>

                `
                : `

                  <i
                    data-lucide="lock-keyhole"
                    class="achievement-lock"
                  ></i>

                `
            }


            <span class="achievement-icon">

              <i data-lucide="${item.icon}"></i>

            </span>


            <h3>

              ${escaparHTML(
                item.nome
              )}

            </h3>


            <p>

              ${escaparHTML(
                item.descricao
              )}

            </p>

          </article>

        `
      )
      .join("");

}


/* =========================================================
   RENDER GERAL
========================================================= */

function renderizarPagina() {

  const atual =
    gerarResumo(
      periodoAtual,
      0
    );


  const anterior =
    gerarResumo(
      periodoAtual,
      periodoAtual
    );


  atualizarIndice(
    atual
  );


  atualizarComparacao(
    atual,
    anterior
  );


  atualizarMetricas(
    atual,
    anterior
  );


  atualizarProximoPasso(
    atual
  );


  renderizarGrafico();


  renderizarTimeline();


  renderizarTrilhaDeConstancia();


  renderizarCategorias();


  renderizarMelhorMomento();


  renderizarInsight(
    atual
  );


  renderizarConquistas(
    atual
  );


  iniciarIcones();

}


/* =========================================================
   FILTRO PERÍODO
========================================================= */

document
  .querySelectorAll(
    ".period-button"
  )
  .forEach(
    (
      botao
    ) => {

      botao.addEventListener(
        "click",
        () => {

          periodoAtual =
            Number(
              botao.dataset
                .period
            );


          document
            .querySelectorAll(
              ".period-button"
            )
            .forEach(
              (
                item
              ) => {

                item.classList.toggle(
                  "active",
                  item ===
                    botao
                );

              }
            );


          renderizarPagina();

        }
      );

    }
  );


/* =========================================================
   TEMA
========================================================= */

window.addEventListener(
  "storage",
  (
    evento
  ) => {

    if (
      evento.key ===
      "darkMode"
    ) {

      aplicarTemaSalvo();

    }

  }
);


/* =========================================================
   ATUALIZA QUANDO VOLTA PARA PÁGINA
========================================================= */

document.addEventListener(
  "visibilitychange",
  async () => {

    if (
      !document.hidden
    ) {

      await carregarDados();

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

  iniciarIcones();

  await carregarDados();

}