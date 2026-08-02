const STORAGE_KEYS = {
  metas: "pace_metas_local",
  focusHistory: "pace_focus_history",
};

const elementos = {
  scoreRing: document.getElementById("scoreRing"),
  evolutionScore: document.getElementById("evolutionScore"),
  scoreLabel: document.getElementById("scoreLabel"),
  evolutionTitle: document.getElementById("evolutionTitle"),
  evolutionDescription: document.getElementById(
    "evolutionDescription"
  ),

  comparisonIcon: document.getElementById("comparisonIcon"),
  comparisonText: document.getElementById("comparisonText"),

  statusSequencia: document.getElementById("statusSequencia"),
  statusMetas: document.getElementById("statusMetas"),
  statusFoco: document.getElementById("statusFoco"),

  nextStepTitle: document.getElementById("nextStepTitle"),
  nextStepDescription: document.getElementById(
    "nextStepDescription"
  ),
  nextStepLink: document.getElementById("nextStepLink"),
  nextStepButtonText: document.getElementById(
    "nextStepButtonText"
  ),
  nextStepIcon: document.getElementById("nextStepIcon"),

  totalFocusTime: document.getElementById("totalFocusTime"),
  completedGoals: document.getElementById("completedGoals"),
  currentStreak: document.getElementById("currentStreak"),
  completedSessions: document.getElementById(
    "completedSessions"
  ),

  focusDelta: document.getElementById("focusDelta"),
  goalsDelta: document.getElementById("goalsDelta"),
  streakDelta: document.getElementById("streakDelta"),
  sessionsDelta: document.getElementById("sessionsDelta"),

  weekChart: document.getElementById("weekChart"),
  weekChartHelper: document.getElementById("weekChartHelper"),

  evolutionTimeline: document.getElementById(
    "evolutionTimeline"
  ),
  timelineEmpty: document.getElementById("timelineEmpty"),

  consistencyTrack: document.getElementById(
    "consistencyTrack"
  ),
  bestWeekValue: document.getElementById("bestWeekValue"),
  bestWeekDescription: document.getElementById(
    "bestWeekDescription"
  ),
  consistencyPeriod: document.getElementById(
    "consistencyPeriod"
  ),

  categoryProgress: document.getElementById(
    "categoryProgress"
  ),
  categoryEmpty: document.getElementById("categoryEmpty"),

  bestMomentIcon: document.getElementById("bestMomentIcon"),
  bestMomentValue: document.getElementById("bestMomentValue"),
  bestMomentTitle: document.getElementById("bestMomentTitle"),
  bestMomentDescription: document.getElementById(
    "bestMomentDescription"
  ),

  insightIcon: document.getElementById("insightIcon"),
  insightTitle: document.getElementById("insightTitle"),
  insightDescription: document.getElementById(
    "insightDescription"
  ),

  achievementGrid: document.getElementById(
    "achievementGrid"
  ),
  achievementCounter: document.getElementById(
    "achievementCounter"
  ),
};

let periodoAtual = 7;
let metas = [];
let sessoes = [];

/* =========================
   UTILIDADES
========================= */

function carregarJSON(chave, fallback = []) {
  try {
    const valor = localStorage.getItem(chave);

    return valor
      ? JSON.parse(valor)
      : fallback;
  } catch (erro) {
    console.error(
      `Erro ao carregar ${chave}:`,
      erro
    );

    return fallback;
  }
}

function aplicarTemaSalvo() {
  const tema = localStorage.getItem("darkMode");

  document.body.classList.toggle(
    "dark",
    tema === "true" ||
    tema === "dark"
  );
}

function iniciarIcones() {
  if (
    window.lucide &&
    typeof window.lucide.createIcons === "function"
  ) {
    window.lucide.createIcons();
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

function dataLocalISO(data = new Date()) {
  const ano = data.getFullYear();

  const mes = String(
    data.getMonth() + 1
  ).padStart(2, "0");

  const dia = String(
    data.getDate()
  ).padStart(2, "0");

  return `${ano}-${mes}-${dia}`;
}

function criarDataLocal(dataISO) {
  if (!dataISO) {
    return null;
  }

  const partes = String(dataISO)
    .slice(0, 10)
    .split("-")
    .map(Number);

  if (
    partes.length !== 3 ||
    partes.some(
      (parte) =>
        !Number.isFinite(parte)
    )
  ) {
    return null;
  }

  const [
    ano,
    mes,
    dia,
  ] = partes;

  const data = new Date(
    ano,
    mes - 1,
    dia,
    12,
    0,
    0
  );

  return Number.isNaN(data.getTime())
    ? null
    : data;
}

function converterParaData(valor) {
  if (!valor) {
    return null;
  }

  if (valor instanceof Date) {
    return Number.isNaN(valor.getTime())
      ? null
      : valor;
  }

  const texto = String(valor);

  if (
    /^\d{4}-\d{2}-\d{2}$/.test(texto)
  ) {
    return criarDataLocal(texto);
  }

  const data = new Date(texto);

  return Number.isNaN(data.getTime())
    ? null
    : data;
}

function formatarDuracao(segundos) {
  const minutos = Math.max(
    0,
    Math.round(
      Number(segundos || 0) / 60
    )
  );

  if (minutos < 60) {
    return `${minutos} min`;
  }

  const horas = Math.floor(
    minutos / 60
  );

  const restante =
    minutos % 60;

  return restante > 0
    ? `${horas}h ${restante}min`
    : `${horas}h`;
}

function formatarValorGrafico(segundos) {
  const minutos = Math.round(
    Number(segundos || 0) / 60
  );

  if (minutos === 0) {
    return "0";
  }

  if (minutos < 60) {
    return `${minutos}m`;
  }

  const horas = Math.floor(
    minutos / 60
  );

  const restante =
    minutos % 60;

  return restante > 0
    ? `${horas}h${restante}`
    : `${horas}h`;
}

function formatarDataCurta(data) {
  if (
    !(data instanceof Date) ||
    Number.isNaN(data.getTime())
  ) {
    return "Data indisponível";
  }

  return new Intl.DateTimeFormat(
    "pt-BR",
    {
      day: "2-digit",
      month: "short",
    }
  ).format(data);
}

function executarSecao(
  nome,
  callback
) {
  try {
    callback();
  } catch (erro) {
    console.error(
      `Erro na seção "${nome}":`,
      erro
    );
  }
}

/* =========================
   NORMALIZAÇÃO
========================= */

function normalizarMetas(lista) {
  if (!Array.isArray(lista)) {
    return [];
  }

  return lista.map((meta) => {
    const progressoOriginal = Number(
      meta?.progresso ??
      meta?.progress ??
      0
    );

    const progresso = Math.min(
      100,
      Math.max(
        0,
        Number.isFinite(progressoOriginal)
          ? progressoOriginal
          : 0
      )
    );

    return {
      id: String(
        meta?.id || ""
      ),

      titulo: String(
        meta?.titulo ??
        meta?.title ??
        "Meta sem título"
      ),

      categoria: String(
        meta?.categoria ??
        meta?.category ??
        "Outro"
      ),

      progresso,

      concluida:
        Boolean(
          meta?.concluida ??
          meta?.completed
        ) ||
        progresso >= 100,

      criadaEm:
        meta?.criadaEm ??
        meta?.createdAt ??
        meta?.created_at ??
        meta?.dataCriacao ??
        meta?.date ??
        null,

      concluidaEm:
        meta?.concluidaEm ??
        meta?.completedAt ??
        meta?.completed_at ??
        null,
    };
  });
}

function normalizarSessoes(lista) {
  if (!Array.isArray(lista)) {
    return [];
  }

  return lista
    .map((sessao) => {
      const finishedAt =
        sessao?.finishedAt ??
        sessao?.finished_at ??
        null;

      const date =
        sessao?.date ??
        (
          finishedAt
            ? String(
                finishedAt
              ).slice(0, 10)
            : null
        );

      return {
        id: String(
          sessao?.id || ""
        ),

        durationSeconds: Math.max(
          0,
          Number(
            sessao?.durationSeconds ??
            sessao?.duration_seconds ??
            0
          )
        ),

        finishedAt,

        date,

        goalId: String(
          sessao?.goalId ??
          sessao?.goal_id ??
          ""
        ),

        goalTitle: String(
          sessao?.goalTitle ??
          sessao?.goal_title ??
          ""
        ),

        intention: String(
          sessao?.intention ??
          sessao?.intencao ??
          "Sessão de foco"
        ),
      };
    })
    .filter(
      (sessao) =>
        sessao.finishedAt ||
        sessao.date
    );
}

function carregarDados() {
  metas = normalizarMetas(
    carregarJSON(
      STORAGE_KEYS.metas,
      []
    )
  );

  sessoes = normalizarSessoes(
    carregarJSON(
      STORAGE_KEYS.focusHistory,
      []
    )
  );
}

/* =========================
   CÁLCULOS
========================= */

function obterDataSessao(sessao) {
  if (sessao.date) {
    const dataLocal =
      criarDataLocal(
        sessao.date
      );

    if (dataLocal) {
      return dataLocal;
    }
  }

  return converterParaData(
    sessao.finishedAt
  );
}

function obterIntervalo(
  dias,
  deslocamento = 0
) {
  const fim = new Date();

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

  const inicio = new Date(fim);

  inicio.setHours(
    0,
    0,
    0,
    0
  );

  inicio.setDate(
    inicio.getDate() -
    (dias - 1)
  );

  return {
    inicio,
    fim,
  };
}

function filtrarSessoesNoIntervalo(
  dias,
  deslocamento = 0
) {
  const {
    inicio,
    fim,
  } = obterIntervalo(
    dias,
    deslocamento
  );

  return sessoes.filter((sessao) => {
    const data =
      obterDataSessao(
        sessao
      );

    return (
      data &&
      data >= inicio &&
      data <= fim
    );
  });
}

function calcularSequencia() {
  const datas = [
    ...new Set(
      sessoes
        .filter(
          (sessao) =>
            sessao.durationSeconds >= 60
        )
        .map(
          (sessao) =>
            sessao.date
        )
        .filter(Boolean)
    ),
  ].sort(
    (a, b) =>
      b.localeCompare(a)
  );

  if (datas.length === 0) {
    return 0;
  }

  const hoje = new Date();

  hoje.setHours(
    12,
    0,
    0,
    0
  );

  const ontem =
    new Date(hoje);

  ontem.setDate(
    ontem.getDate() - 1
  );

  const primeira =
    criarDataLocal(
      datas[0]
    );

  if (!primeira) {
    return 0;
  }

  const primeiraISO =
    dataLocalISO(primeira);

  if (
    primeiraISO !==
      dataLocalISO(hoje) &&
    primeiraISO !==
      dataLocalISO(ontem)
  ) {
    return 0;
  }

  let sequencia = 1;
  let anterior = primeira;

  for (
    let indice = 1;
    indice < datas.length;
    indice += 1
  ) {
    const atual =
      criarDataLocal(
        datas[indice]
      );

    if (!atual) {
      continue;
    }

    const diferenca =
      Math.round(
        (
          anterior.getTime() -
          atual.getTime()
        ) /
        86400000
      );

    if (diferenca === 1) {
      sequencia += 1;
      anterior = atual;
    } else if (
      diferenca > 1
    ) {
      break;
    }
  }

  return sequencia;
}

function calcularScore(dados) {
  const {
    progressoMedio,
    metasConcluidas,
    totalMetas,
    totalSessoes,
    minutosFoco,
    sequencia,
    diasAtivos,
  } = dados;

  if (
    totalMetas === 0 &&
    totalSessoes === 0
  ) {
    return 0;
  }

  const componenteMetas =
    totalMetas > 0
      ? progressoMedio * 0.32
      : 0;

  const componenteConclusoes =
    Math.min(
      22,
      metasConcluidas * 4.4
    );

  const componenteFoco =
    Math.min(
      22,
      minutosFoco / 14
    );

  const componenteSequencia =
    Math.min(
      14,
      sequencia * 2.2
    );

  const componenteConstancia =
    Math.min(
      10,
      diasAtivos * 1.5
    );

  return Math.min(
    100,
    Math.round(
      componenteMetas +
      componenteConclusoes +
      componenteFoco +
      componenteSequencia +
      componenteConstancia
    )
  );
}

function gerarResumo(
  dias = periodoAtual,
  deslocamento = 0
) {
  const sessoesPeriodo =
    filtrarSessoesNoIntervalo(
      dias,
      deslocamento
    );

  const totalSegundos =
    sessoesPeriodo.reduce(
      (soma, sessao) =>
        soma +
        sessao.durationSeconds,
      0
    );

  const totalMinutos =
    Math.round(
      totalSegundos / 60
    );

  const metasConcluidas =
    metas.filter(
      (meta) =>
        meta.concluida
    ).length;

  const totalMetas =
    metas.length;

  const progressoMedio =
    totalMetas > 0
      ? Math.round(
          metas.reduce(
            (soma, meta) =>
              soma +
              meta.progresso,
            0
          ) /
          totalMetas
        )
      : 0;

  const diasAtivos =
    new Set(
      sessoesPeriodo
        .map(
          (sessao) =>
            sessao.date
        )
        .filter(Boolean)
    ).size;

  const sequencia =
    deslocamento === 0
      ? calcularSequencia()
      : 0;

  const score =
    calcularScore({
      progressoMedio,
      metasConcluidas,
      totalMetas,
      totalSessoes:
        sessoesPeriodo.length,
      minutosFoco:
        totalMinutos,
      sequencia,
      diasAtivos,
    });

  return {
    sessoesPeriodo,
    totalSegundos,
    totalMinutos,
    metasConcluidas,
    totalMetas,
    progressoMedio,
    diasAtivos,
    sequencia,
    score,
  };
}

/* =========================
   ÍNDICE PACE
========================= */

function definirTextoDoScore(score) {
  if (score === 0) {
    return {
      label:
        "Sua jornada começa agora",

      titulo:
        "Sua evolução começa com o primeiro passo.",

      descricao:
        "Crie uma meta ou conclua uma sessão de foco para começar a construir seu painel de evolução.",
    };
  }

  if (score < 25) {
    return {
      label:
        "Movimento inicial",

      titulo:
        "Você começou a construir movimento.",

      descricao:
        "Os primeiros registros já existem. Continue avançando para transformar ações isoladas em uma rotina consistente.",
    };
  }

  if (score < 50) {
    return {
      label:
        "Ritmo em construção",

      titulo:
        "Seu progresso já está ganhando forma.",

      descricao:
        "Você está criando um ritmo real. Agora, o maior avanço virá de repetir as ações que já funcionam.",
    };
  }

  if (score < 75) {
    return {
      label:
        "Constância sólida",

      titulo:
        "A constância está virando parte de você.",

      descricao:
        "Suas metas e sessões mostram uma evolução sólida. Mantenha o equilíbrio e proteja sua sequência.",
    };
  }

  return {
    label:
      "Alta evolução",

    titulo:
      "Você está vivendo uma fase de alta evolução.",

    descricao:
      "Seu ritmo, constância e progresso estão trabalhando juntos. Continue crescendo sem perder a qualidade da sua rotina.",
  };
}

function atualizarScore(resumo) {
  const texto =
    definirTextoDoScore(
      resumo.score
    );

  elementos.evolutionScore.textContent =
    String(resumo.score);

  elementos.scoreLabel.textContent =
    texto.label;

  elementos.scoreRing.style.setProperty(
    "--score-progress",
    `${resumo.score * 3.6}deg`
  );

  elementos.evolutionTitle.textContent =
    texto.titulo;

  elementos.evolutionDescription.textContent =
    texto.descricao;

  elementos.statusSequencia.textContent =
    `${resumo.sequencia} ${
      resumo.sequencia === 1
        ? "dia"
        : "dias"
    } de sequência`;

  elementos.statusMetas.textContent =
    `${resumo.metasConcluidas} ${
      resumo.metasConcluidas === 1
        ? "meta concluída"
        : "metas concluídas"
    }`;

  elementos.statusFoco.textContent =
    `${formatarDuracao(
      resumo.totalSegundos
    )} de foco`;
}

function atualizarComparacao(
  atual,
  anterior
) {
  if (
    atual.totalSegundos === 0 &&
    anterior.totalSegundos === 0
  ) {
    elementos.comparisonText.textContent =
      "Sem dados suficientes";

    elementos.comparisonIcon.setAttribute(
      "data-lucide",
      "minus"
    );

    return;
  }

  if (
    anterior.totalSegundos === 0
  ) {
    elementos.comparisonText.textContent =
      "Primeiro período com atividade registrada";

    elementos.comparisonIcon.setAttribute(
      "data-lucide",
      "sparkles"
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

  if (variacao > 0) {
    elementos.comparisonText.textContent =
      `${variacao}% mais tempo focado`;

    elementos.comparisonIcon.setAttribute(
      "data-lucide",
      "trending-up"
    );
  } else if (
    variacao < 0
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
      "Mesmo tempo focado do período anterior";

    elementos.comparisonIcon.setAttribute(
      "data-lucide",
      "equal"
    );
  }
}

/* =========================
   MÉTRICAS
========================= */

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
      resumo.sequencia === 1
        ? "dia"
        : "dias"
    }`;

  elementos.completedSessions.textContent =
    String(
      resumo.sessoesPeriodo.length
    );

  const deltaFoco =
    resumo.totalSegundos -
    anterior.totalSegundos;

  elementos.focusDelta.textContent =
    deltaFoco === 0
      ? "Mesmo ritmo do período anterior"
      : deltaFoco > 0
        ? `+${formatarDuracao(
            deltaFoco
          )} no período`
        : `-${formatarDuracao(
            Math.abs(deltaFoco)
          )} no período`;

  elementos.goalsDelta.textContent =
    resumo.metasConcluidas > 0
      ? `${resumo.metasConcluidas} alcançada${
          resumo.metasConcluidas === 1
            ? ""
            : "s"
        }`
      : "Nenhuma conclusão";

  elementos.streakDelta.textContent =
    resumo.sequencia > 0
      ? "Sua constância está ativa"
      : "Uma sessão hoje inicia sua sequência";

  const deltaSessoes =
    resumo.sessoesPeriodo.length -
    anterior.sessoesPeriodo.length;

  elementos.sessionsDelta.textContent =
    deltaSessoes === 0
      ? "Mesmo volume anterior"
      : deltaSessoes > 0
        ? `+${deltaSessoes} sessão${
            deltaSessoes === 1
              ? ""
              : "ões"
          }`
        : `${Math.abs(
            deltaSessoes
          )} a menos`;
}

/* =========================
   PRÓXIMO PASSO
========================= */

function configurarProximoPasso(resumo) {
  let configuracao;

  if (resumo.totalMetas === 0) {
    configuracao = {
      titulo:
        "Defina onde quer chegar",

      descricao:
        "Crie sua primeira meta para dar direção ao seu desenvolvimento.",

      link:
        "metas.html",

      botao:
        "Criar uma meta",

      icon:
        "target",
    };
  } else if (
    resumo.sessoesPeriodo.length === 0
  ) {
    configuracao = {
      titulo:
        "Transforme intenção em ação",

      descricao:
        "Inicie uma sessão de foco e registre tempo real dedicado às suas metas.",

      link:
        "foco.html",

      botao:
        "Iniciar sessão",

      icon:
        "brain",
    };
  } else if (
    resumo.sequencia === 0
  ) {
    configuracao = {
      titulo:
        "Retome sua sequência",

      descricao:
        "Uma nova sessão hoje pode recolocar sua constância em movimento.",

      link:
        "foco.html",

      botao:
        "Voltar ao foco",

      icon:
        "flame",
    };
  } else if (
    resumo.progressoMedio < 50
  ) {
    configuracao = {
      titulo:
        "Avance em uma meta",

      descricao:
        "Escolha a meta mais importante e registre o progresso alcançado.",

      link:
        "metas.html",

      botao:
        "Atualizar metas",

      icon:
        "trending-up",
    };
  } else {
    configuracao = {
      titulo:
        "Proteja seu bom momento",

      descricao:
        "Continue com uma sessão focada para manter o ritmo que você construiu.",

      link:
        "foco.html",

      botao:
        "Continuar evoluindo",

      icon:
        "zap",
    };
  }

  elementos.nextStepTitle.textContent =
    configuracao.titulo;

  elementos.nextStepDescription.textContent =
    configuracao.descricao;

  elementos.nextStepLink.href =
    configuracao.link;

  elementos.nextStepButtonText.textContent =
    configuracao.botao;

  elementos.nextStepIcon.setAttribute(
    "data-lucide",
    configuracao.icon
  );
}

/* =========================
   GRÁFICO SEMANAL
========================= */

function obterUltimosDias(quantidade) {
  const dias = [];

  for (
    let indice =
      quantidade - 1;
    indice >= 0;
    indice -= 1
  ) {
    const data = new Date();

    data.setHours(
      12,
      0,
      0,
      0
    );

    data.setDate(
      data.getDate() -
      indice
    );

    dias.push(data);
  }

  return dias;
}

function renderizarGraficoSemanal() {
  const dias =
    obterUltimosDias(7);

  const valores =
    dias.map((data) => {
      const chave =
        dataLocalISO(data);

      const segundos =
        sessoes
          .filter(
            (sessao) =>
              sessao.date ===
              chave
          )
          .reduce(
            (soma, sessao) =>
              soma +
              sessao.durationSeconds,
            0
          );

      return {
        data,
        segundos,
      };
    });

  const maiorValor =
    Math.max(
      ...valores.map(
        (item) =>
          item.segundos
      ),
      1
    );

  const formatadorDia =
    new Intl.DateTimeFormat(
      "pt-BR",
      {
        weekday:
          "short",
      }
    );

  elementos.weekChart.innerHTML =
    valores
      .map((item) => {
        const altura =
          item.segundos > 0
            ? Math.max(
                8,
                (
                  item.segundos /
                  maiorValor
                ) *
                100
              )
            : 2;

        const nomeDia =
          formatadorDia
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
            );

        const classeZero =
          item.segundos === 0
            ? "zero"
            : "";

        return `
          <div class="day-column">

            <span class="day-value">
              ${formatarValorGrafico(
                item.segundos
              )}
            </span>

            <div class="bar-shell">

              <span
                class="day-bar ${classeZero}"
                style="height: ${altura}%"
                title="${formatarDuracao(
                  item.segundos
                )}"
              ></span>

            </div>

            <span class="day-label">
              ${nomeDia}
            </span>

          </div>
        `;
      })
      .join("");

  elementos.weekChartHelper.textContent =
    "Últimos 7 dias";
}

/* =========================
   LINHA DO TEMPO
========================= */

function criarEventosDaLinhaDoTempo() {
  const eventos = [];

  metas.forEach((meta) => {
    const dataCriacao =
      converterParaData(
        meta.criadaEm
      );

    const dataConclusao =
      converterParaData(
        meta.concluidaEm
      );

    if (dataCriacao) {
      eventos.push({
        date:
          dataCriacao,

        title:
          `Meta criada: ${
            meta.titulo ||
            "Meta sem título"
          }`,

        description:
          `Categoria ${
            meta.categoria
          } · ${
            meta.progresso
          }% de progresso`,

        icon:
          "target",
      });
    }

    if (
      meta.concluida &&
      (
        dataConclusao ||
        dataCriacao
      )
    ) {
      eventos.push({
        date:
          dataConclusao ||
          dataCriacao,

        title:
          `Meta concluída: ${
            meta.titulo ||
            "Meta sem título"
          }`,

        description:
          "Um objetivo foi transformado em resultado.",

        icon:
          "trophy",
      });
    }
  });

  sessoes.forEach((sessao) => {
    const data =
      obterDataSessao(
        sessao
      );

    if (!data) {
      return;
    }

    eventos.push({
      date,

      title:
        sessao.intention ||
        "Sessão de foco",

      description:
        `${formatarDuracao(
          sessao.durationSeconds
        )} de foco${
          sessao.goalTitle
            ? ` · ${sessao.goalTitle}`
            : ""
        }`,

      icon:
        "brain",
    });
  });

  return eventos
    .filter(
      (evento) =>
        evento.date instanceof Date &&
        !Number.isNaN(
          evento.date.getTime()
        )
    )
    .sort(
      (a, b) =>
        b.date.getTime() -
        a.date.getTime()
    )
    .slice(0, 8);
}

function renderizarLinhaDoTempo() {
  const eventos =
    criarEventosDaLinhaDoTempo();

  const vazio =
    eventos.length === 0;

  elementos.timelineEmpty.classList.toggle(
    "hidden",
    !vazio
  );

  elementos.evolutionTimeline.innerHTML =
    vazio
      ? ""
      : eventos
          .map(
            (evento) => `
              <article class="timeline-item">

                <span class="timeline-marker">

                  <i
                    data-lucide="${evento.icon}"
                  ></i>

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

/* =========================
   TRILHA DE CONSTÂNCIA
========================= */

function obterUltimasSemanas(
  quantidade = 12
) {
  const semanas = [];

  const hoje = new Date();

  hoje.setHours(
    12,
    0,
    0,
    0
  );

  const diaSemana =
    hoje.getDay();

  const ajusteSegunda =
    diaSemana === 0
      ? -6
      : 1 - diaSemana;

  const inicioSemanaAtual =
    new Date(hoje);

  inicioSemanaAtual.setDate(
    hoje.getDate() +
    ajusteSegunda
  );

  for (
    let indice =
      quantidade - 1;
    indice >= 0;
    indice -= 1
  ) {
    const inicio =
      new Date(
        inicioSemanaAtual
      );

    inicio.setDate(
      inicio.getDate() -
      indice * 7
    );

    inicio.setHours(
      0,
      0,
      0,
      0
    );

    const fim =
      new Date(inicio);

    fim.setDate(
      fim.getDate() + 6
    );

    fim.setHours(
      23,
      59,
      59,
      999
    );

    semanas.push({
      inicio,
      fim,
    });
  }

  return semanas;
}

function calcularDadosDaSemana(
  inicio,
  fim
) {
  const sessoesDaSemana =
    sessoes.filter((sessao) => {
      const data =
        obterDataSessao(
          sessao
        );

      return (
        data &&
        data >= inicio &&
        data <= fim
      );
    });

  const totalSegundos =
    sessoesDaSemana.reduce(
      (soma, sessao) =>
        soma +
        sessao.durationSeconds,
      0
    );

  const diasAtivos =
    new Set(
      sessoesDaSemana
        .map(
          (sessao) =>
            sessao.date
        )
        .filter(Boolean)
    ).size;

  return {
    totalSegundos,
    diasAtivos,
    totalSessoes:
      sessoesDaSemana.length,
  };
}

function renderizarTrilhaDeConstancia() {
  const semanas =
    obterUltimasSemanas(12);

  const dados =
    semanas.map(
      (semana, indice) => {
        const resumo =
          calcularDadosDaSemana(
            semana.inicio,
            semana.fim
          );

        return {
          ...semana,
          ...resumo,
          numero:
            indice + 1,
        };
      }
    );

  const maiorTempo =
    Math.max(
      ...dados.map(
        (semana) =>
          semana.totalSegundos
      ),
      1
    );

  const melhorSemana =
    dados.reduce(
      (melhor, semana) =>
        semana.totalSegundos >
        melhor.totalSegundos
          ? semana
          : melhor,
      dados[0]
    );

  elementos.consistencyTrack.innerHTML =
    dados
      .map((semana) => {
        const porcentagem =
          semana.totalSegundos > 0
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
          semana.totalSegundos > 0;

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
                  style="width: ${porcentagem}%"
                ></span>

              </div>

              <div class="week-details">

                <span>

                  <i data-lucide="brain"></i>

                  ${semana.totalSessoes}
                  ${
                    semana.totalSessoes === 1
                      ? "sessão"
                      : "sessões"
                  }

                </span>

                <span>

                  <i data-lucide="calendar-check-2"></i>

                  ${semana.diasAtivos}
                  ${
                    semana.diasAtivos === 1
                      ? "dia ativo"
                      : "dias ativos"
                  }

                </span>

              </div>

            </div>

          </article>
        `;
      })
      .join("");

  if (
    melhorSemana &&
    melhorSemana.totalSegundos > 0
  ) {
    elementos.bestWeekValue.textContent =
      formatarDuracao(
        melhorSemana.totalSegundos
      );

    elementos.bestWeekDescription.textContent =
      `${melhorSemana.totalSessoes} ${
        melhorSemana.totalSessoes === 1
          ? "sessão"
          : "sessões"
      } em ${melhorSemana.diasAtivos} ${
        melhorSemana.diasAtivos === 1
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

/* =========================
   CATEGORIAS
========================= */

function obterIconeCategoria(
  categoria
) {
  const mapa = {
    Pessoal:
      "user-round",

    Estudos:
      "graduation-cap",

    Trabalho:
      "briefcase-business",

    Saúde:
      "heart-pulse",

    Projeto:
      "folder-kanban",

    Outro:
      "shapes",
  };

  return (
    mapa[categoria] ||
    "tag"
  );
}

function renderizarCategorias() {
  if (metas.length === 0) {
    elementos.categoryProgress.innerHTML =
      "";

    elementos.categoryEmpty.classList.remove(
      "hidden"
    );

    return;
  }

  elementos.categoryEmpty.classList.add(
    "hidden"
  );

  const categorias =
    metas.reduce(
      (mapa, meta) => {
        const categoria =
          meta.categoria ||
          "Outro";

        if (!mapa[categoria]) {
          mapa[categoria] = {
            total: 0,
            progresso: 0,
          };
        }

        mapa[categoria].total +=
          1;

        mapa[categoria].progresso +=
          meta.progresso;

        return mapa;
      },
      {}
    );

  const lista =
    Object.entries(
      categorias
    )
      .map(
        ([
          categoria,
          dados,
        ]) => ({
          categoria,

          media:
            Math.round(
              dados.progresso /
              dados.total
            ),
        })
      )
      .sort(
        (a, b) =>
          b.media -
          a.media
      );

  elementos.categoryProgress.innerHTML =
    lista
      .map(
        (item) => `
          <article class="category-item">

            <div class="category-top">

              <div class="category-name">

                <span class="category-icon">

                  <i
                    data-lucide="${obterIconeCategoria(
                      item.categoria
                    )}"
                  ></i>

                </span>

                <strong>
                  ${escaparHTML(
                    item.categoria
                  )}
                </strong>

              </div>

              <span class="category-percent">
                ${item.media}%
              </span>

            </div>

            <div class="category-progress">

              <span
                style="width: ${item.media}%"
              ></span>

            </div>

          </article>
        `
      )
      .join("");
}

/* =========================
   MELHOR MOMENTO
========================= */

function renderizarMelhorMomento() {
  if (
    sessoes.length === 0 &&
    metas.length === 0
  ) {
    elementos.bestMomentValue.textContent =
      "—";

    elementos.bestMomentTitle.textContent =
      "Ainda sem um destaque";

    elementos.bestMomentDescription.textContent =
      "Continue registrando sua evolução para revelar o melhor momento da sua jornada.";

    elementos.bestMomentIcon.setAttribute(
      "data-lucide",
      "sparkles"
    );

    return;
  }

  const maiorSessao =
    sessoes.reduce(
      (melhor, sessao) =>
        sessao.durationSeconds >
        (
          melhor?.durationSeconds ||
          0
        )
          ? sessao
          : melhor,
      null
    );

  const melhorMeta =
    metas.reduce(
      (melhor, meta) =>
        meta.progresso >
        (
          melhor?.progresso ||
          0
        )
          ? meta
          : melhor,
      null
    );

  if (
    maiorSessao &&
    maiorSessao.durationSeconds > 0
  ) {
    elementos.bestMomentValue.textContent =
      formatarDuracao(
        maiorSessao.durationSeconds
      );

    elementos.bestMomentTitle.textContent =
      "Sua sessão mais profunda";

    elementos.bestMomentDescription.textContent =
      maiorSessao.intention ||
      "Você demonstrou capacidade real de concentração.";

    elementos.bestMomentIcon.setAttribute(
      "data-lucide",
      "brain"
    );

    return;
  }

  elementos.bestMomentValue.textContent =
    `${melhorMeta?.progresso || 0}%`;

  elementos.bestMomentTitle.textContent =
    "Sua meta mais avançada";

  elementos.bestMomentDescription.textContent =
    melhorMeta?.titulo ||
    "Continue avançando para criar um novo destaque.";

  elementos.bestMomentIcon.setAttribute(
    "data-lucide",
    "target"
  );
}

/* =========================
   INSIGHT
========================= */

function definirInsight(resumo) {
  if (
    resumo.totalMetas === 0 &&
    resumo.sessoesPeriodo.length === 0
  ) {
    return {
      icon:
        "lightbulb",

      titulo:
        "Comece a gerar seu histórico.",

      descricao:
        "Suas metas e sessões de foco serão analisadas aqui para revelar padrões reais da sua evolução.",
    };
  }

  if (
    resumo.totalMetas > 0 &&
    resumo.sessoesPeriodo.length === 0
  ) {
    return {
      icon:
        "brain",

      titulo:
        "Você já tem direção. Agora falta tempo protegido.",

      descricao:
        "Suas metas estão definidas, mas ainda não há sessões de foco neste período.",
    };
  }

  if (
    resumo.sessoesPeriodo.length > 0 &&
    resumo.totalMetas === 0
  ) {
    return {
      icon:
        "target",

      titulo:
        "Você está agindo, mas pode ganhar mais direção.",

      descricao:
        "Seu histórico mostra tempo dedicado. Criar metas ajudará a conectar esse esforço a objetivos claros.",
    };
  }

  if (
    resumo.sequencia >= 7
  ) {
    return {
      icon:
        "flame",

      titulo:
        "Sua constância já passou de uma semana.",

      descricao:
        "Você está formando um padrão consistente. Mantenha o ritmo sem aumentar a carga de forma exagerada.",
    };
  }

  if (
    resumo.progressoMedio >= 70
  ) {
    return {
      icon:
        "trending-up",

      titulo:
        "Suas metas estão em uma fase avançada.",

      descricao:
        "Priorize concluir o que já começou antes de adicionar muitos novos objetivos.",
    };
  }

  if (
    resumo.diasAtivos >= 4
  ) {
    return {
      icon:
        "calendar-check-2",

      titulo:
        "Seu esforço está bem distribuído.",

      descricao:
        "Você registrou atividade em vários dias do período, um sinal saudável de constância.",
    };
  }

  return {
    icon:
      "footprints",

    titulo:
      "Seu ritmo está começando a aparecer.",

    descricao:
      "Continue registrando pequenas sessões e atualizando suas metas para enxergar padrões mais claros.",
  };
}

function renderizarInsight(resumo) {
  const insight =
    definirInsight(
      resumo
    );

  elementos.insightIcon.setAttribute(
    "data-lucide",
    insight.icon
  );

  elementos.insightTitle.textContent =
    insight.titulo;

  elementos.insightDescription.textContent =
    insight.descricao;
}

/* =========================
   CONQUISTAS
========================= */

function obterConquistas(resumo) {
  const totalFocoGeral =
    sessoes.reduce(
      (soma, sessao) =>
        soma +
        sessao.durationSeconds,
      0
    );

  const metasConcluidas =
    metas.filter(
      (meta) =>
        meta.concluida
    ).length;

  return [
    {
      nome:
        "Primeiro passo",

      descricao:
        "Conclua sua primeira sessão de foco.",

      icon:
        "footprints",

      desbloqueada:
        sessoes.length >= 1,
    },

    {
      nome:
        "Objetivo alcançado",

      descricao:
        "Conclua sua primeira meta.",

      icon:
        "trophy",

      desbloqueada:
        metasConcluidas >= 1,
    },

    {
      nome:
        "Uma hora de presença",

      descricao:
        "Acumule 60 minutos de foco.",

      icon:
        "clock-3",

      desbloqueada:
        totalFocoGeral >=
        3600,
    },

    {
      nome:
        "Constância de 3 dias",

      descricao:
        "Mantenha uma sequência de três dias.",

      icon:
        "flame",

      desbloqueada:
        resumo.sequencia >= 3,
    },

    {
      nome:
        "Cinco metas",

      descricao:
        "Conclua cinco metas.",

      icon:
        "list-checks",

      desbloqueada:
        metasConcluidas >= 5,
    },

    {
      nome:
        "Foco profundo",

      descricao:
        "Complete uma sessão de pelo menos 60 minutos.",

      icon:
        "brain",

      desbloqueada:
        sessoes.some(
          (sessao) =>
            sessao.durationSeconds >=
            3600
        ),
    },
  ];
}

function renderizarConquistas(resumo) {
  const conquistas =
    obterConquistas(
      resumo
    );

  const desbloqueadas =
    conquistas.filter(
      (item) =>
        item.desbloqueada
    ).length;

  elementos.achievementCounter.textContent =
    `${desbloqueadas} de ${conquistas.length}`;

  elementos.achievementGrid.innerHTML =
    conquistas
      .map(
        (conquista) => `
          <article
            class="achievement-card ${
              conquista.desbloqueada
                ? "unlocked"
                : "locked"
            }"
          >

            ${
              conquista.desbloqueada
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

              <i
                data-lucide="${conquista.icon}"
              ></i>

            </span>

            <h3>
              ${escaparHTML(
                conquista.nome
              )}
            </h3>

            <p>
              ${escaparHTML(
                conquista.descricao
              )}
            </p>

          </article>
        `
      )
      .join("");
}

/* =========================
   RENDERIZAÇÃO
========================= */

function atualizarPeriodo(
  novoPeriodo
) {
  periodoAtual =
    novoPeriodo;

  document
    .querySelectorAll(
      ".period-button"
    )
    .forEach((botao) => {
      botao.classList.toggle(
        "active",
        Number(
          botao.dataset.period
        ) ===
        novoPeriodo
      );
    });

  renderizarPagina();
}

function renderizarPagina() {
  carregarDados();

  const resumo =
    gerarResumo(
      periodoAtual,
      0
    );

  const anterior =
    gerarResumo(
      periodoAtual,
      periodoAtual
    );

  executarSecao(
    "Índice Pace",
    () =>
      atualizarScore(
        resumo
      )
  );

  executarSecao(
    "Comparação",
    () =>
      atualizarComparacao(
        resumo,
        anterior
      )
  );

  executarSecao(
    "Métricas",
    () =>
      atualizarMetricas(
        resumo,
        anterior
      )
  );

  executarSecao(
    "Próximo passo",
    () =>
      configurarProximoPasso(
        resumo
      )
  );

  executarSecao(
    "Gráfico semanal",
    renderizarGraficoSemanal
  );

  executarSecao(
    "Linha do tempo",
    renderizarLinhaDoTempo
  );

  executarSecao(
    "Trilha de constância",
    renderizarTrilhaDeConstancia
  );

  executarSecao(
    "Categorias",
    renderizarCategorias
  );

  executarSecao(
    "Melhor momento",
    renderizarMelhorMomento
  );

  executarSecao(
    "Insight",
    () =>
      renderizarInsight(
        resumo
      )
  );

  executarSecao(
    "Conquistas",
    () =>
      renderizarConquistas(
        resumo
      )
  );

  iniciarIcones();
}

/* =========================
   EVENTOS
========================= */

document
  .querySelectorAll(
    ".period-button"
  )
  .forEach((botao) => {
    botao.addEventListener(
      "click",
      () => {
        atualizarPeriodo(
          Number(
            botao.dataset.period
          )
        );
      }
    );
  });

window.addEventListener(
  "storage",
  (evento) => {
    if (
      evento.key ===
        STORAGE_KEYS.metas ||
      evento.key ===
        STORAGE_KEYS.focusHistory ||
      evento.key === null
    ) {
      renderizarPagina();
    }

    if (
      evento.key ===
        "darkMode" ||
      evento.key === null
    ) {
      aplicarTemaSalvo();
    }
  }
);

document.addEventListener(
  "visibilitychange",
  () => {
    if (!document.hidden) {
      renderizarPagina();
    }
  }
);

/* =========================
   INICIALIZAÇÃO
========================= */

aplicarTemaSalvo();
renderizarPagina();