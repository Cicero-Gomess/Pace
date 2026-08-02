const STORAGE_KEYS = {
  settings: "pace_focus_settings",
  active: "pace_focus_active",
  history: "pace_focus_history",
  metas: "pace_metas_local",
};

const elementos = {
  body: document.body,

  fotoSidebar: document.getElementById("fotoSidebar"),

  sequenciaFoco: document.getElementById("sequenciaFoco"),
  tituloSessao: document.getElementById("tituloSessao"),
  estadoSessao: document.getElementById("estadoSessao"),
  timerDisplay: document.getElementById("timerDisplay"),
  timerRing: document.getElementById("timerRing"),
  intencaoAtiva: document.getElementById("intencaoAtiva"),

  iniciarSessao: document.getElementById("iniciarSessao"),
  resetarSessao: document.getElementById("resetarSessao"),
  finalizarSessao: document.getElementById("finalizarSessao"),

  intencaoSessao: document.getElementById("intencaoSessao"),
  metaVinculada: document.getElementById("metaVinculada"),
  duracaoSelecionada: document.getElementById("duracaoSelecionada"),
  duracaoPersonalizada: document.getElementById("duracaoPersonalizada"),
  aplicarDuracao: document.getElementById("aplicarDuracao"),

  toggleSom: document.getElementById("toggleSom"),
  entrarTelaCheia: document.getElementById("entrarTelaCheia"),

  tempoHoje: document.getElementById("tempoHoje"),
  sessoesConcluidas: document.getElementById("sessoesConcluidas"),
  melhorDia: document.getElementById("melhorDia"),

  historicoSessoes: document.getElementById("historicoSessoes"),
  historicoVazio: document.getElementById("historicoVazio"),
  limparHistorico: document.getElementById("limparHistorico"),

  immersiveMode: document.getElementById("immersiveMode"),
  immersiveTimer: document.getElementById("immersiveTimer"),
  immersiveIntention: document.getElementById("immersiveIntention"),
  immersivePause: document.getElementById("immersivePause"),
  immersiveFinish: document.getElementById("immersiveFinish"),
  sairImersivo: document.getElementById("sairImersivo"),

  conclusaoModal: document.getElementById("conclusaoModal"),
  conclusaoResumo: document.getElementById("conclusaoResumo"),
  conclusaoTempo: document.getElementById("conclusaoTempo"),
  conclusaoSequencia: document.getElementById("conclusaoSequencia"),
  fecharConclusao: document.getElementById("fecharConclusao"),

  confirmModal: document.getElementById("confirmModal"),
  confirmTitulo: document.getElementById("confirmTitulo"),
  confirmTexto: document.getElementById("confirmTexto"),
  cancelarConfirmacao: document.getElementById("cancelarConfirmacao"),
  aceitarConfirmacao: document.getElementById("aceitarConfirmacao"),

  toast: document.getElementById("toast"),
};

const defaultSettings = {
  durationMinutes: 25,
  soundEnabled: true,
};

let settings = carregarJSON(
  STORAGE_KEYS.settings,
  defaultSettings
);

let history = carregarJSON(
  STORAGE_KEYS.history,
  []
);

let activeSession = carregarJSON(
  STORAGE_KEYS.active,
  null
);

let timerInterval = null;
let pendingConfirmAction = null;
let lastRenderedSecond = null;

function carregarJSON(chave, fallback) {
  try {
    const salvo = localStorage.getItem(chave);

    if (!salvo) {
      return fallback;
    }

    return JSON.parse(salvo);
  } catch (erro) {
    console.error(`Erro ao ler ${chave}:`, erro);

    return fallback;
  }
}

function salvarJSON(chave, valor) {
  try {
    localStorage.setItem(
      chave,
      JSON.stringify(valor)
    );
  } catch (erro) {
    console.error(`Erro ao salvar ${chave}:`, erro);
  }
}

function removerStorage(chave) {
  try {
    localStorage.removeItem(chave);
  } catch (erro) {
    console.error(`Erro ao remover ${chave}:`, erro);
  }
}

function aplicarTemaSalvo() {
  const valor = localStorage.getItem("darkMode");

  const usarEscuro =
    valor === "true" ||
    valor === "dark";

  document.body.classList.toggle(
    "dark",
    usarEscuro
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

function gerarId() {
  if (
    window.crypto &&
    typeof window.crypto.randomUUID === "function"
  ) {
    return window.crypto.randomUUID();
  }

  return `focus-${Date.now()}-${Math.random()
    .toString(16)
    .slice(2)}`;
}

function formatarTempo(totalSegundos) {
  const segundos = Math.max(
    0,
    Math.floor(totalSegundos)
  );

  const minutos = Math.floor(segundos / 60);
  const restante = segundos % 60;

  return `${String(minutos).padStart(2, "0")}:${String(
    restante
  ).padStart(2, "0")}`;
}

function formatarDuracao(segundos) {
  const totalMinutos = Math.max(
    1,
    Math.round(segundos / 60)
  );

  if (totalMinutos < 60) {
    return `${totalMinutos} min`;
  }

  const horas = Math.floor(totalMinutos / 60);
  const minutos = totalMinutos % 60;

  if (minutos > 0) {
    return `${horas}h ${minutos}min`;
  }

  return `${horas}h`;
}

function hojeISO() {
  const agora = new Date();

  const ano = agora.getFullYear();
  const mes = String(
    agora.getMonth() + 1
  ).padStart(2, "0");

  const dia = String(
    agora.getDate()
  ).padStart(2, "0");

  return `${ano}-${mes}-${dia}`;
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

function formatarData(dataISO) {
  const data = new Date(dataISO);

  return new Intl.DateTimeFormat(
    "pt-BR",
    {
      day: "2-digit",
      month: "short",
      hour: "2-digit",
      minute: "2-digit",
    }
  ).format(data);
}

function mostrarToast(
  mensagem,
  tipo = "success"
) {
  if (!elementos.toast) {
    return;
  }

  elementos.toast.textContent = mensagem;

  elementos.toast.className =
    `toast ${tipo}`;

  elementos.toast.classList.remove(
    "hidden"
  );

  requestAnimationFrame(() => {
    elementos.toast.classList.add(
      "show"
    );
  });

  window.setTimeout(() => {
    elementos.toast.classList.remove(
      "show"
    );

    window.setTimeout(() => {
      elementos.toast.classList.add(
        "hidden"
      );
    }, 250);
  }, 2600);
}

function tocarSomConclusao() {
  if (!settings.soundEnabled) {
    return;
  }

  try {
    const AudioContext =
      window.AudioContext ||
      window.webkitAudioContext;

    const contexto =
      new AudioContext();

    const notas = [
      523.25,
      659.25,
      783.99,
    ];

    notas.forEach(
      (frequencia, indice) => {
        const oscilador =
          contexto.createOscillator();

        const ganho =
          contexto.createGain();

        oscilador.frequency.value =
          frequencia;

        oscilador.type = "sine";

        ganho.gain.setValueAtTime(
          0.0001,
          contexto.currentTime +
            indice * 0.14
        );

        ganho.gain.exponentialRampToValueAtTime(
          0.16,
          contexto.currentTime +
            indice * 0.14 +
            0.02
        );

        ganho.gain.exponentialRampToValueAtTime(
          0.0001,
          contexto.currentTime +
            indice * 0.14 +
            0.35
        );

        oscilador.connect(ganho);
        ganho.connect(contexto.destination);

        oscilador.start(
          contexto.currentTime +
            indice * 0.14
        );

        oscilador.stop(
          contexto.currentTime +
            indice * 0.14 +
            0.4
        );
      }
    );
  } catch (erro) {
    console.warn(
      "Não foi possível tocar o som:",
      erro
    );
  }
}

function carregarMetas() {
  const metas = carregarJSON(
    STORAGE_KEYS.metas,
    []
  );

  if (
    !Array.isArray(metas) ||
    !elementos.metaVinculada
  ) {
    return;
  }

  elementos.metaVinculada.innerHTML = `
    <option value="">
      Nenhuma meta vinculada
    </option>
  `;

  metas
    .filter((meta) => !meta.concluida)
    .forEach((meta) => {
      const option =
        document.createElement("option");

      option.value =
        String(meta.id || "");

      option.textContent =
        String(
          meta.titulo ||
          "Meta sem título"
        );

      elementos.metaVinculada.appendChild(
        option
      );
    });
}

function selecionarDuracao(minutos) {
  const duracao = Math.min(
    240,
    Math.max(
      1,
      Number(minutos) || 25
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
    .forEach((botao) => {
      botao.classList.toggle(
        "active",
        Number(
          botao.dataset.minutes
        ) === duracao
      );
    });

  elementos.duracaoSelecionada.textContent =
    `${duracao} min`;

  if (!activeSession) {
    elementos.timerDisplay.textContent =
      formatarTempo(duracao * 60);

    elementos.immersiveTimer.textContent =
      formatarTempo(duracao * 60);
  }
}

function criarSessao() {
  const intencao = String(
    elementos.intencaoSessao.value || ""
  ).trim();

  const metaId = String(
    elementos.metaVinculada.value || ""
  );

  const metaOption =
    elementos.metaVinculada
      .selectedOptions?.[0];

  const metaTitulo =
    metaId && metaOption
      ? String(
          metaOption.textContent || ""
        ).trim()
      : "";

  const agora = Date.now();

  return {
    id: gerarId(),

    intention:
      intencao ||
      "Sessão de foco",

    goalId: metaId,

    goalTitle:
      metaTitulo,

    durationSeconds:
      settings.durationMinutes * 60,

    elapsedBeforeStart: 0,

    startedAt: agora,

    status: "running",

    createdAt:
      new Date(
        agora
      ).toISOString(),
  };
}

function obterSegundosDecorridos(
  sessao = activeSession
) {
  if (!sessao) {
    return 0;
  }

  const acumulado = Number(
    sessao.elapsedBeforeStart || 0
  );

  if (
    sessao.status !== "running" ||
    !sessao.startedAt
  ) {
    return acumulado;
  }

  const desdeInicio = Math.floor(
    (
      Date.now() -
      Number(sessao.startedAt)
    ) / 1000
  );

  return Math.max(
    0,
    acumulado + desdeInicio
  );
}

function obterSegundosRestantes() {
  if (!activeSession) {
    return (
      settings.durationMinutes *
      60
    );
  }

  return Math.max(
    0,
    Number(
      activeSession.durationSeconds
    ) -
      obterSegundosDecorridos(
        activeSession
      )
  );
}

function salvarSessaoAtiva() {
  if (activeSession) {
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

function pausarSessao() {
  if (
    !activeSession ||
    activeSession.status !==
      "running"
  ) {
    return;
  }

  activeSession.elapsedBeforeStart =
    obterSegundosDecorridos(
      activeSession
    );

  activeSession.startedAt = null;
  activeSession.status = "paused";

  salvarSessaoAtiva();
  renderizarSessao();
}

function retomarSessao() {
  if (
    !activeSession ||
    activeSession.status !==
      "paused"
  ) {
    return;
  }

  activeSession.startedAt =
    Date.now();

  activeSession.status =
    "running";

  salvarSessaoAtiva();
  renderizarSessao();
}

function iniciarOuPausar() {
  if (!activeSession) {
    activeSession =
      criarSessao();

    salvarSessaoAtiva();
    abrirImersivo();
    iniciarLoopTimer();
    renderizarSessao();

    return;
  }

  if (
    activeSession.status ===
    "running"
  ) {
    pausarSessao();
    return;
  }

  retomarSessao();
  abrirImersivo();
  iniciarLoopTimer();
}

function solicitarConfirmacao(tipo) {
  pendingConfirmAction = tipo;

  if (tipo === "reset") {
    elementos.confirmTitulo.textContent =
      "Reiniciar a sessão?";

    elementos.confirmTexto.textContent =
      "O tempo atual será descartado e o cronômetro voltará ao início.";

    elementos.aceitarConfirmacao.textContent =
      "Reiniciar";
  } else if (
    tipo === "clear-history"
  ) {
    elementos.confirmTitulo.textContent =
      "Limpar histórico?";

    elementos.confirmTexto.textContent =
      "Todas as sessões concluídas armazenadas neste navegador serão removidas.";

    elementos.aceitarConfirmacao.textContent =
      "Limpar histórico";
  } else {
    elementos.confirmTitulo.textContent =
      "Finalizar sessão?";

    elementos.confirmTexto.textContent =
      "O tempo focado até agora será registrado no seu histórico.";

    elementos.aceitarConfirmacao.textContent =
      "Finalizar sessão";
  }

  elementos.confirmModal.classList.remove(
    "hidden"
  );

  iniciarIcones();
}

function executarConfirmacao() {
  const acao =
    pendingConfirmAction;

  pendingConfirmAction = null;

  elementos.confirmModal.classList.add(
    "hidden"
  );

  if (acao === "reset") {
    resetarSessao();
  } else if (
    acao === "clear-history"
  ) {
    history = [];

    salvarJSON(
      STORAGE_KEYS.history,
      history
    );

    renderizarHistorico();
    atualizarResumo();

    mostrarToast(
      "Histórico removido."
    );
  } else {
    finalizarSessao(false);
  }
}

function resetarSessao() {
  fecharImersivo();

  activeSession = null;

  removerStorage(
    STORAGE_KEYS.active
  );

  pararLoopTimer();

  lastRenderedSecond = null;

  renderizarSessao();

  mostrarToast(
    "Sessão reiniciada."
  );
}

function finalizarSessao(
  automatico = false
) {
  if (!activeSession) {
    return;
  }

  const decorrido = Math.min(
    Number(
      activeSession.durationSeconds
    ),
    obterSegundosDecorridos(
      activeSession
    )
  );

  const minimoParaSalvar = 10;

  const sessaoFinalizada = {
    id: activeSession.id,

    intention:
      activeSession.intention,

    goalId:
      activeSession.goalId,

    goalTitle:
      activeSession.goalTitle,

    durationSeconds:
      Math.max(0, decorrido),

    plannedSeconds:
      Number(
        activeSession.durationSeconds
      ),

    completed:
      automatico ||
      decorrido >=
        Number(
          activeSession.durationSeconds
        ),

    finishedAt:
      new Date().toISOString(),

    date: hojeISO(),
  };

  activeSession = null;

  removerStorage(
    STORAGE_KEYS.active
  );

  pararLoopTimer();
  fecharImersivo();

  if (
    decorrido >=
    minimoParaSalvar
  ) {
    history.unshift(
      sessaoFinalizada
    );

    history = history.slice(
      0,
      100
    );

    salvarJSON(
      STORAGE_KEYS.history,
      history
    );

    if (automatico) {
      tocarSomConclusao();
    }

    abrirConclusao(
      sessaoFinalizada
    );
  } else {
    mostrarToast(
      "A sessão foi encerrada antes de completar tempo suficiente para ser salva.",
      "error"
    );
  }

  renderizarSessao();
  renderizarHistorico();
  atualizarResumo();
}

function abrirConclusao(sessao) {
  const sequencia =
    calcularSequencia();

  elementos.conclusaoResumo.textContent =
    sessao.intention ===
    "Sessão de foco"
      ? "Seu tempo de foco foi registrado no seu histórico."
      : `Você avançou em “${sessao.intention}”.`;

  elementos.conclusaoTempo.textContent =
    formatarDuracao(
      sessao.durationSeconds
    );

  elementos.conclusaoSequencia.textContent =
    `${sequencia} ${
      sequencia === 1
        ? "dia"
        : "dias"
    }`;

  elementos.conclusaoModal.classList.remove(
    "hidden"
  );

  iniciarIcones();
}

function abrirImersivo() {
  if (!activeSession) {
    return;
  }

  elementos.immersiveMode.classList.remove(
    "hidden"
  );

  elementos.immersiveMode.setAttribute(
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
  elementos.immersiveMode.classList.add(
    "hidden"
  );

  elementos.immersiveMode.setAttribute(
    "aria-hidden",
    "true"
  );

  document.body.style.overflow =
    "";
}

async function alternarTelaCheia() {
  try {
    if (!document.fullscreenElement) {
      await document.documentElement.requestFullscreen();
    } else {
      await document.exitFullscreen();
    }
  } catch (erro) {
    mostrarToast(
      "Seu navegador bloqueou a tela cheia.",
      "error"
    );
  }
}

function atualizarBotaoSom() {
  elementos.toggleSom.classList.toggle(
    "muted",
    !settings.soundEnabled
  );

  elementos.toggleSom.innerHTML =
    settings.soundEnabled
      ? '<i data-lucide="volume-2"></i>'
      : '<i data-lucide="volume-x"></i>';

  iniciarIcones();
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

function iniciarLoopTimer() {
  pararLoopTimer();

  timerInterval =
    window.setInterval(() => {
      atualizarTimer();
    }, 250);

  atualizarTimer();
}

function pararLoopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval);

    timerInterval = null;
  }
}

function atualizarTimer() {
  if (!activeSession) {
    return;
  }

  const restante =
    obterSegundosRestantes();

  if (
    restante !==
    lastRenderedSecond
  ) {
    lastRenderedSecond =
      restante;

    renderizarTempo(
      restante
    );
  }

  if (restante <= 0) {
    finalizarSessao(true);
  }
}

function renderizarTempo(restante) {
  const total = activeSession
    ? Number(
        activeSession.durationSeconds
      )
    : settings.durationMinutes *
      60;

  const decorrido = Math.max(
    0,
    total - restante
  );

  const progresso =
    total > 0
      ? decorrido / total
      : 0;

  const graus = Math.min(
    360,
    Math.max(
      0,
      progresso * 360
    )
  );

  const texto =
    formatarTempo(restante);

  elementos.timerDisplay.textContent =
    texto;

  elementos.immersiveTimer.textContent =
    texto;

  elementos.timerRing.style.setProperty(
    "--progress",
    `${graus}deg`
  );

  document.title =
    activeSession
      ? `${texto} | Sala de Foco`
      : "Sala de Foco | Pace";
}

function renderizarSessao() {
  if (!activeSession) {
    const total =
      settings.durationMinutes *
      60;

    elementos.tituloSessao.textContent =
      "Pronto para começar?";

    elementos.estadoSessao.textContent =
      "Preparação";

    elementos.intencaoAtiva.textContent =
      "Defina uma intenção para sua sessão";

    elementos.iniciarSessao.innerHTML = `
      <i data-lucide="play"></i>
      <span>Iniciar foco</span>
    `;

    elementos.finalizarSessao.disabled =
      true;

    elementos.resetarSessao.disabled =
      true;

    elementos.intencaoSessao.disabled =
      false;

    elementos.metaVinculada.disabled =
      false;

    elementos.duracaoPersonalizada.disabled =
      false;

    elementos.aplicarDuracao.disabled =
      false;

    document
      .querySelectorAll(
        ".duration-option"
      )
      .forEach((botao) => {
        botao.disabled =
          false;
      });

    renderizarTempo(total);
    iniciarIcones();

    return;
  }

  const rodando =
    activeSession.status ===
    "running";

  const restante =
    obterSegundosRestantes();

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
        <span>Pausar</span>
      `
      : `
        <i data-lucide="play"></i>
        <span>Continuar</span>
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

  elementos.metaVinculada.disabled =
    true;

  elementos.duracaoPersonalizada.disabled =
    true;

  elementos.aplicarDuracao.disabled =
    true;

  document
    .querySelectorAll(
      ".duration-option"
    )
    .forEach((botao) => {
      botao.disabled = true;
    });

  renderizarTempo(restante);

  if (rodando) {
    iniciarLoopTimer();
  } else {
    pararLoopTimer();
  }

  iniciarIcones();
}

function calcularSequencia() {
  const datas = [
    ...new Set(
      history
        .filter(
          (sessao) =>
            Number(
              sessao.durationSeconds ||
              0
            ) >= 60
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

  const hoje = new Date(
    `${hojeISO()}T12:00:00`
  );

  const ontem =
    new Date(hoje);

  ontem.setDate(
    ontem.getDate() - 1
  );

  const primeiraData =
    new Date(
      `${datas[0]}T12:00:00`
    );

  const primeiraISO =
    dataLocalISO(
      primeiraData
    );

  if (
    primeiraISO !==
      dataLocalISO(hoje) &&
    primeiraISO !==
      dataLocalISO(ontem)
  ) {
    return 0;
  }

  let sequencia = 1;
  let anterior =
    primeiraData;

  for (
    let i = 1;
    i < datas.length;
    i += 1
  ) {
    const atual = new Date(
      `${datas[i]}T12:00:00`
    );

    const diferencaDias =
      Math.round(
        (
          anterior -
          atual
        ) / 86400000
      );

    if (diferencaDias === 1) {
      sequencia += 1;
      anterior = atual;
    } else if (
      diferencaDias > 1
    ) {
      break;
    }
  }

  return sequencia;
}

function atualizarResumo() {
  const hoje =
    hojeISO();

  const sessoesHoje =
    history.filter(
      (sessao) =>
        sessao.date === hoje
    );

  const segundosHoje =
    sessoesHoje.reduce(
      (soma, sessao) =>
        soma +
        Number(
          sessao.durationSeconds ||
          0
        ),
      0
    );

  const agrupadoPorDia =
    history.reduce(
      (mapa, sessao) => {
        if (!sessao.date) {
          return mapa;
        }

        mapa[sessao.date] =
          (
            mapa[sessao.date] ||
            0
          ) +
          Number(
            sessao.durationSeconds ||
            0
          );

        return mapa;
      },
      {}
    );

  const melhorEntrada =
    Object.entries(
      agrupadoPorDia
    ).sort(
      (a, b) =>
        b[1] - a[1]
    )[0];

  elementos.tempoHoje.textContent =
    segundosHoje > 0
      ? formatarDuracao(
          segundosHoje
        )
      : "0 min";

  elementos.sessoesConcluidas.textContent =
    String(history.length);

  elementos.melhorDia.textContent =
    melhorEntrada
      ? formatarDuracao(
          melhorEntrada[1]
        )
      : "—";

  const sequencia =
    calcularSequencia();

  elementos.sequenciaFoco.textContent =
    `${sequencia} ${
      sequencia === 1
        ? "dia"
        : "dias"
    }`;
}

function criarHistoricoHTML(
  sessao
) {
  const detalheMeta =
    sessao.goalTitle
      ? ` · ${escaparHTML(
          sessao.goalTitle
        )}`
      : "";

  return `
    <article class="history-item">

      <span class="history-item-icon">
        <i data-lucide="brain"></i>
      </span>

      <div class="history-item-copy">

        <strong>
          ${escaparHTML(
            sessao.intention ||
            "Sessão de foco"
          )}
        </strong>

        <span>
          ${formatarData(
            sessao.finishedAt
          )}${detalheMeta}
        </span>

      </div>

      <span class="history-duration">
        ${formatarDuracao(
          Number(
            sessao.durationSeconds ||
            0
          )
        )}
      </span>

    </article>
  `;
}

function renderizarHistorico() {
  const vazio =
    history.length === 0;

  elementos.historicoVazio.classList.toggle(
    "hidden",
    !vazio
  );

  elementos.limparHistorico.disabled =
    vazio;

  elementos.historicoSessoes.innerHTML =
    vazio
      ? ""
      : history
          .slice(0, 8)
          .map(
            criarHistoricoHTML
          )
          .join("");

  iniciarIcones();
}

function restaurarSessao() {
  if (
    !activeSession ||
    typeof activeSession !==
      "object"
  ) {
    activeSession = null;

    removerStorage(
      STORAGE_KEYS.active
    );

    return;
  }

  const duracao = Number(
    activeSession.durationSeconds
  );

  if (
    !Number.isFinite(
      duracao
    ) ||
    duracao <= 0
  ) {
    activeSession = null;

    removerStorage(
      STORAGE_KEYS.active
    );

    return;
  }

  if (
    obterSegundosRestantes() <=
    0
  ) {
    finalizarSessao(true);
    return;
  }

  elementos.intencaoSessao.value =
    activeSession.intention || "";

  elementos.metaVinculada.value =
    activeSession.goalId || "";

  if (
    activeSession.status ===
    "running"
  ) {
    iniciarLoopTimer();
  }
}

document
  .querySelectorAll(
    ".duration-option"
  )
  .forEach((botao) => {
    botao.addEventListener(
      "click",
      () => {
        selecionarDuracao(
          Number(
            botao.dataset.minutes
          )
        );
      }
    );
  });

elementos.aplicarDuracao.addEventListener(
  "click",
  () => {
    const valor = Number(
      elementos
        .duracaoPersonalizada
        .value
    );

    if (
      !Number.isFinite(valor) ||
      valor < 1 ||
      valor > 240
    ) {
      mostrarToast(
        "Escolha uma duração entre 1 e 240 minutos.",
        "error"
      );

      return;
    }

    selecionarDuracao(
      Math.round(valor)
    );

    elementos.duracaoPersonalizada.value =
      "";
  }
);

elementos.iniciarSessao.addEventListener(
  "click",
  iniciarOuPausar
);

elementos.immersivePause.addEventListener(
  "click",
  iniciarOuPausar
);

elementos.resetarSessao.addEventListener(
  "click",
  () => {
    if (activeSession) {
      solicitarConfirmacao(
        "reset"
      );
    }
  }
);

elementos.finalizarSessao.addEventListener(
  "click",
  () => {
    if (activeSession) {
      solicitarConfirmacao(
        "finish"
      );
    }
  }
);

elementos.immersiveFinish.addEventListener(
  "click",
  () => {
    if (activeSession) {
      fecharImersivo();

      solicitarConfirmacao(
        "finish"
      );
    }
  }
);

elementos.sairImersivo.addEventListener(
  "click",
  fecharImersivo
);

elementos.entrarTelaCheia.addEventListener(
  "click",
  alternarTelaCheia
);

elementos.toggleSom.addEventListener(
  "click",
  alternarSom
);

elementos.limparHistorico.addEventListener(
  "click",
  () => {
    if (history.length > 0) {
      solicitarConfirmacao(
        "clear-history"
      );
    }
  }
);

elementos.cancelarConfirmacao.addEventListener(
  "click",
  () => {
    pendingConfirmAction =
      null;

    elementos.confirmModal.classList.add(
      "hidden"
    );
  }
);

elementos.aceitarConfirmacao.addEventListener(
  "click",
  executarConfirmacao
);

elementos.fecharConclusao.addEventListener(
  "click",
  () => {
    elementos.conclusaoModal.classList.add(
      "hidden"
    );
  }
);

elementos.confirmModal.addEventListener(
  "click",
  (evento) => {
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

elementos.conclusaoModal.addEventListener(
  "click",
  (evento) => {
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

elementos.intencaoSessao.addEventListener(
  "input",
  () => {
    if (!activeSession) {
      const valor =
        elementos
          .intencaoSessao
          .value
          .trim();

      elementos.intencaoAtiva.textContent =
        valor ||
        "Defina uma intenção para sua sessão";
    }
  }
);

document.addEventListener(
  "keydown",
  (evento) => {
    if (
      evento.key ===
      "Escape"
    ) {
      if (
        !elementos.confirmModal.classList.contains(
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
        !elementos.conclusaoModal.classList.contains(
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
      ].includes(
        document.activeElement
          ?.tagName
      )
    ) {
      evento.preventDefault();

      if (activeSession) {
        iniciarOuPausar();
      }
    }
  }
);

window.addEventListener(
  "storage",
  (evento) => {
    if (
      evento.key ===
        "darkMode" ||
      evento.key === null
    ) {
      aplicarTemaSalvo();
    }

    if (
      evento.key ===
        STORAGE_KEYS.metas ||
      evento.key === null
    ) {
      carregarMetas();
    }

    if (
      evento.key ===
        STORAGE_KEYS.history ||
      evento.key === null
    ) {
      history = carregarJSON(
        STORAGE_KEYS.history,
        []
      );

      renderizarHistorico();
      atualizarResumo();
    }
  }
);

document.addEventListener(
  "visibilitychange",
  () => {
    if (
      !document.hidden &&
      activeSession
    ) {
      atualizarTimer();
    }
  }
);

aplicarTemaSalvo();
carregarMetas();
selecionarDuracao(
  settings.durationMinutes
);
atualizarBotaoSom();
restaurarSessao();
renderizarSessao();
renderizarHistorico();
atualizarResumo();
iniciarIcones();