import { initAppShell } from "./shared/app-shell.js";

import {
  getCurrentUser,
  saveCurrentUser,
  handleAuthError,
} from "./shared/auth.js";

import {
  showToast,
  updateSidebarPhoto,
  initLucide,
} from "./shared/ui.js";

import { escaparHTML } from "./shared/utils.js";

import {
  fetchCurrentProfile,
  fetchFollowing,
  followUser,
  unfollowUser,
} from "./shared/services/profile-service.js";

import {
  fetchFeed,
  fetchPostById,
  likePost,
  unlikePost,
  updatePost,
  deletePost,
  formatarDataRelativa,
} from "./shared/services/post-service.js";

import {
  fetchComments,
  createComment,
  updateComment,
  deleteComment,
} from "./shared/services/comment-service.js";

import { AVATAR_PLACEHOLDER } from "./shared/config.js";

import { apiFetch } from "./shared/api.js";


const shellOk =
  await initAppShell();


if (shellOk) {

  /* =========================================================
     ESTADO
  ========================================================= */

  let usuario =
    getCurrentUser() || {};

  let postsCarregados = [];

  let seguindoIds =
    new Set();

  let postEmEdicao =
    null;

  let postParaExcluir =
    null;

  let comentarioParaExcluir =
    null;

  let comentarioEmEdicao =
    null;


  /* =========================================================
     COMUNIDADES / PAGINAÇÃO
  ========================================================= */

  const COMMUNITY_STORAGE_KEY =
    "paceCommunities";

  const COMMUNITY_MEMBERS_STORAGE_KEY =
    "paceCommunityMembers";

  const COMMUNITY_POSTS_STORAGE_KEY =
    "paceCommunityPosts";

  const POSTS_PER_PAGE =
    10;

  let filtroFeedAtivo =
    "general";

  let comunidadeFiltroAtiva =
    "all";

  let limitePostsVisiveis =
    POSTS_PER_PAGE;

  let feedObserver =
    null;


  /* =========================================================
     ELEMENTOS
  ========================================================= */

  const feedEl =
    document.getElementById(
      "feed"
    );

  const feedLoadMore =
    document.getElementById(
      "feedLoadMore"
    );

  const communityFilters =
    document.getElementById(
      "communityFilters"
    );


  /* =========================================================
     PAINEL DE PROGRESSO
  ========================================================= */

  const progressStreak =
    document.getElementById(
      "progressStreak"
    );

  const progressStreakLabel =
    document.getElementById(
      "progressStreakLabel"
    );

  const progressFocusToday =
    document.getElementById(
      "progressFocusToday"
    );

  const progressGoalTitle =
    document.getElementById(
      "progressGoalTitle"
    );

  const progressGoalStatus =
    document.getElementById(
      "progressGoalStatus"
    );

  const progressGoalDescription =
    document.getElementById(
      "progressGoalDescription"
    );


  /* =========================================================
     MODAIS
  ========================================================= */

  const confirmDeleteModal =
    document.getElementById(
      "confirmDeleteModal"
    );

  const cancelDeleteBtn =
    document.getElementById(
      "cancelDeleteBtn"
    );

  const confirmDeleteBtn =
    document.getElementById(
      "confirmDeleteBtn"
    );

  const confirmDeleteCommentModal =
    document.getElementById(
      "confirmDeleteCommentModal"
    );

  const cancelDeleteCommentBtn =
    document.getElementById(
      "cancelDeleteCommentBtn"
    );

  const confirmDeleteCommentBtn =
    document.getElementById(
      "confirmDeleteCommentBtn"
    );

  const modalEditarPost =
    document.getElementById(
      "editPostModal"
    );

  const editPostTexto =
    document.getElementById(
      "editPostText"
    );

  const cancelarEditarPost =
    document.getElementById(
      "cancelEditBtn"
    );

  const salvarEditarPost =
    document.getElementById(
      "saveEditBtn"
    );

  const editCommentModal =
    document.getElementById(
      "editCommentModal"
    );

  const editCommentInput =
    document.getElementById(
      "editCommentText"
    );

  const cancelEditCommentBtn =
    document.getElementById(
      "cancelEditCommentBtn"
    );

  const confirmEditCommentBtn =
    document.getElementById(
      "saveEditCommentBtn"
    );


  /* =========================================================
     UTILITÁRIOS
  ========================================================= */

  function encontrarPost(
    postId
  ) {

    return postsCarregados.find(
      (post) =>
        post.id === postId
    );

  }


  function abrirModal(
    elemento
  ) {

    elemento?.classList.remove(
      "hidden"
    );

  }


  function fecharModal(
    elemento
  ) {

    elemento?.classList.add(
      "hidden"
    );

  }


  function atualizarPostNaLista(
    postAtualizado
  ) {

    postsCarregados =
      postsCarregados.map(
        (post) =>

          post.id ===
          postAtualizado.id

            ? {
                ...post,
                ...postAtualizado,
              }

            : post
      );

  }


  function obterCard(
    postId
  ) {

    return (
      feedEl?.querySelector(
        `.card[data-post-id="${postId}"]`
      ) || null
    );

  }


  /* =========================================================
     LOCAL STORAGE
  ========================================================= */

  function obterArrayLocalStorage(
    chave
  ) {

    try {

      const valor =
        JSON.parse(
          localStorage.getItem(
            chave
          )
        );

      return Array.isArray(
        valor
      )
        ? valor
        : [];

    } catch {

      return [];

    }

  }


  function obterIdUsuarioAtual() {

    if (
      usuario?.id !== undefined &&
      usuario?.id !== null
    ) {

      return String(
        usuario.id
      );

    }


    const possibleKeys = [
      "user",
      "usuario",
      "paceUser",
      "currentUser",
    ];


    for (
      const key of
      possibleKeys
    ) {

      try {

        const raw =
          localStorage.getItem(
            key
          );


        if (!raw) {
          continue;
        }


        const parsed =
          JSON.parse(
            raw
          );


        const id =
          parsed?.id ??
          parsed?.usuario_id ??
          parsed?.user_id;


        if (
          id !== undefined &&
          id !== null
        ) {

          return String(
            id
          );

        }

      } catch {

        // Continua procurando.

      }

    }


    return "";

  }


  /* =========================================================
     COMUNIDADES
  ========================================================= */

  function obterComunidadeIdDoPost(
    post
  ) {

    const id =
      post?.comunidadeId ??
      post?.communityId ??
      post?.comunidade_id ??
      post?.community_id ??
      null;


    return (
      id === null ||
      id === undefined ||
      id === ""
    )
      ? null
      : String(
          id
        );

  }


  function obterMinhasComunidades() {

    const userId =
      obterIdUsuarioAtual();


    if (!userId) {

      return [];

    }


    const comunidades =
      obterArrayLocalStorage(
        COMMUNITY_STORAGE_KEY
      );


    const membros =
      obterArrayLocalStorage(
        COMMUNITY_MEMBERS_STORAGE_KEY
      );


    const idsParticipando =
      new Set(

        membros

          .filter(
            (membro) =>

              String(
                membro.usuarioId
              ) ===
              userId
          )

          .map(
            (membro) =>

              String(
                membro.comunidadeId
              )
          )

      );


    return comunidades.filter(
      (comunidade) =>

        idsParticipando.has(
          String(
            comunidade.id
          )
        )
    );

  }


  function obterComunidadePorId(
    comunidadeId
  ) {

    if (
      !comunidadeId
    ) {

      return null;

    }


    return (

      obterArrayLocalStorage(
        COMMUNITY_STORAGE_KEY
      )

        .find(
          (comunidade) =>

            String(
              comunidade.id
            ) ===

            String(
              comunidadeId
            )
        )

      ||

      null

    );

  }


  function aplicarVinculosComunidades(
    posts
  ) {

    const vinculos =
      obterArrayLocalStorage(
        COMMUNITY_POSTS_STORAGE_KEY
      );


    const vinculosPorPost =
      new Map(

        vinculos.map(
          (vinculo) => [

            String(
              vinculo.postId
            ),

            vinculo,

          ]
        )

      );


    return posts.map(
      (post) => {

        const vinculo =
          vinculosPorPost.get(
            String(
              post.id
            )
          );


        const comunidadeId =

          obterComunidadeIdDoPost(
            post
          )

          ??

          (
            vinculo?.comunidadeId !== undefined &&
            vinculo?.comunidadeId !== null &&
            vinculo?.comunidadeId !== ""

              ? String(
                  vinculo.comunidadeId
                )

              : null
          );


        if (
          !comunidadeId
        ) {

          return {

            ...post,

            comunidadeId:
              null,

            comunidadeNome:
              null,

          };

        }


        const comunidade =
          obterComunidadePorId(
            comunidadeId
          );


        return {

          ...post,

          comunidadeId,

          comunidadeNome:
            comunidade?.nome ||
            "Comunidade",

        };

      }
    );

  }


  function removerVinculoComunidadeDoPost(
    postId
  ) {

    const vinculos =
      obterArrayLocalStorage(
        COMMUNITY_POSTS_STORAGE_KEY
      );


    const atualizados =
      vinculos.filter(
        (vinculo) =>

          String(
            vinculo.postId
          ) !==

          String(
            postId
          )
      );


    localStorage.setItem(

      COMMUNITY_POSTS_STORAGE_KEY,

      JSON.stringify(
        atualizados
      )

    );

  }


  /* =========================================================
     FILTRO DOS POSTS
  ========================================================= */

  function obterPostsFiltrados() {

    if (
      filtroFeedAtivo ===
      "following"
    ) {

      return postsCarregados.filter(
        (post) =>

          seguindoIds.has(
            String(
              post.userId
            )
          )
      );

    }


    if (
      filtroFeedAtivo ===
      "communities"
    ) {

      const idsPermitidos =
        new Set(

          obterMinhasComunidades()

            .map(
              (comunidade) =>

                String(
                  comunidade.id
                )
            )

        );


      return postsCarregados.filter(
        (post) => {

          const comunidadeId =
            obterComunidadeIdDoPost(
              post
            );


          if (
            !comunidadeId ||
            !idsPermitidos.has(
              comunidadeId
            )
          ) {

            return false;

          }


          return (

            comunidadeFiltroAtiva ===
              "all"

            ||

            comunidadeId ===
              String(
                comunidadeFiltroAtiva
              )

          );

        }
      );

    }


    return postsCarregados;

  }


  /* =========================================================
     FILTROS VISUAIS DAS COMUNIDADES
  ========================================================= */

  function renderizarFiltrosComunidades() {

    if (
      !communityFilters
    ) {

      return;

    }


    const comunidades =
      obterMinhasComunidades();


    if (
      !comunidades.length
    ) {

      communityFilters.innerHTML = `

        <span class="community-filter-empty">

          Você ainda não participa de nenhuma comunidade.

          <a href="explorar.html">
            Explorar comunidades
          </a>

        </span>

      `;


      return;

    }


    const filtroAindaExiste =

      comunidadeFiltroAtiva ===
        "all"

      ||

      comunidades.some(
        (comunidade) =>

          String(
            comunidade.id
          ) ===

          String(
            comunidadeFiltroAtiva
          )
      );


    if (
      !filtroAindaExiste
    ) {

      comunidadeFiltroAtiva =
        "all";

    }


    communityFilters.innerHTML = `

      <button
        type="button"
        class="community-filter ${
          comunidadeFiltroAtiva ===
          "all"
            ? "active"
            : ""
        }"
        data-community-filter="all"
      >

        Todas

      </button>


      ${

        comunidades

          .map(
            (comunidade) => `

              <button
                type="button"
                class="community-filter ${
                  String(
                    comunidadeFiltroAtiva
                  ) ===
                  String(
                    comunidade.id
                  )

                    ? "active"

                    : ""
                }"
                data-community-filter="${escaparHTML(
                  String(
                    comunidade.id
                  )
                )}"
              >

                ${escaparHTML(
                  comunidade.nome
                )}

              </button>

            `
          )

          .join("")

      }

    `;

  }


  /* =========================================================
     PAGINAÇÃO VISUAL
  ========================================================= */

  function resetarPaginacaoFeed() {

    limitePostsVisiveis =
      POSTS_PER_PAGE;

  }


  function atualizarSentinelaFeed(
    total
  ) {

    if (
      !feedLoadMore
    ) {

      return;

    }


    const temMais =
      limitePostsVisiveis <
      total;


    feedLoadMore.classList.toggle(
      "active",
      temMais
    );


    feedLoadMore.setAttribute(
      "aria-hidden",
      String(
        !temMais
      )
    );


    feedLoadMore.innerHTML =

      temMais

        ? `
            <span class="feed-load-more-dot"></span>
            <span>Carregando mais posts...</span>
          `

        : "";

  }


  function configurarInfiniteScroll() {

    if (
      !feedLoadMore ||
      !(
        "IntersectionObserver"
        in window
      )
    ) {

      return;

    }


    feedObserver?.disconnect();


    feedObserver =
      new IntersectionObserver(

        (entries) => {

          const entrou =
            entries.some(
              (entry) =>
                entry.isIntersecting
            );


          if (
            !entrou
          ) {

            return;

          }


          const total =
            obterPostsFiltrados()
              .length;


          if (
            limitePostsVisiveis >=
            total
          ) {

            return;

          }


          limitePostsVisiveis +=
            POSTS_PER_PAGE;


          renderFeed();

        },

        {
          rootMargin:
            "320px 0px",
        }

      );


    feedObserver.observe(
      feedLoadMore
    );

  }


  /* =========================================================
     FEED VAZIO
  ========================================================= */

  function renderEmptyFeed() {

    if (
      !feedEl
    ) {

      return;

    }


    feedEl.innerHTML = `

      <div class="empty-feed">

        <div class="empty-icon">

          <i data-lucide="sparkles"></i>

        </div>


        <h3>
          Nenhum post por enquanto
        </h3>


        <p>
          Quando a comunidade começar
          a publicar, tudo vai aparecer aqui.
        </p>


        <a
          href="postar.html"
          class="empty-btn"
        >

          <i data-lucide="square-pen"></i>

          <span>
            Criar post
          </span>

        </a>

      </div>

    `;


    initLucide();

  }


  /* =========================================================
     COMENTÁRIO HTML
  ========================================================= */

  function criarComentarioHTML(
    post,
    comentario
  ) {

    const ehDono =

      String(
        comentario.userId
      ) ===

      String(
        usuario.id
      );


    return `

      <div
        class="comentario"
        data-comment-id="${comentario.id}"
      >

        <img
          class="comentario-avatar"
          src="${escaparHTML(
            comentario.foto ||
            AVATAR_PLACEHOLDER
          )}"
          alt=""
        >


        <div class="comentario-bloco">

          <div class="comentario-conteudo">


            <div class="comentario-topo">

              <strong class="comentario-nome">

                ${escaparHTML(
                  comentario.username
                )}

              </strong>


              ${

                ehDono

                  ? `

                    <div class="comentario-acoes">

                      <button
                        class="btn-icon"
                        type="button"
                        data-action="abrir-editar-comentario"
                        data-post-id="${post.id}"
                        data-comment-id="${comentario.id}"
                        aria-label="Editar comentário"
                      >

                        <i data-lucide="pencil"></i>

                      </button>


                      <button
                        class="btn-icon"
                        type="button"
                        data-action="abrir-excluir-comentario"
                        data-post-id="${post.id}"
                        data-comment-id="${comentario.id}"
                        aria-label="Excluir comentário"
                      >

                        <i data-lucide="trash-2"></i>

                      </button>

                    </div>

                  `

                  : ""

              }

            </div>


            <span class="comentario-texto">

              ${escaparHTML(
                comentario.texto
              )}

            </span>

          </div>

        </div>

      </div>

    `;

  }


  /* =========================================================
     BOTÃO SEGUIR
  ========================================================= */

  function criarBotaoSeguir(
    post
  ) {

    const seguindo =

      seguindoIds.has(
        String(
          post.userId
        )
      )

      ||

      post.seguindo;


    return `

      <button
        class="
          btn-seguir-post
          ${seguindo ? "seguindo" : ""}
        "
        type="button"
        data-action="toggle-follow"
        data-user-id="${post.userId}"
      >

        ${
          seguindo
            ? "Seguindo"
            : "Seguir"
        }

      </button>

    `;

  }


  function obterContagemInicial(
    post
  ) {

    const valor =

      post.commentsCount ??

      post.comentariosCount ??

      post.commentCount ??

      post.totalComentarios ??

      post.total_comentarios;


    const numero =
      Number(
        valor
      );


    return Number.isFinite(
      numero
    )
      ? numero
      : 0;

  }


  /* =========================================================
     POST HTML
  ========================================================= */

  function criarPostHTML(
    post
  ) {

    const ehMeuPost =

      String(
        post.userId
      ) ===

      String(
        usuario.id
      );


    const totalComentarios =
      obterContagemInicial(
        post
      );


    const comunidadeId =
      obterComunidadeIdDoPost(
        post
      );


    const comunidadeNome =

      post.comunidadeNome ||

      obterComunidadePorId(
        comunidadeId
      )?.nome ||

      null;


    const estaNaComunidadeEspecifica =

      filtroFeedAtivo ===
        "communities"

      &&

      comunidadeFiltroAtiva !==
        "all"

      &&

      comunidadeId

      &&

      String(
        comunidadeFiltroAtiva
      ) ===

      String(
        comunidadeId
      );


    const deveMostrarComunidade =

      comunidadeId &&

      comunidadeNome &&

      !estaNaComunidadeEspecifica;


    return `

      <article
        class="card"
        data-post-id="${post.id}"
      >

        <div class="post-topo">


          <img
            class="avatar"
            src="${escaparHTML(
              post.foto ||
              AVATAR_PLACEHOLDER
            )}"
            alt=""
          >


          <div class="info">

            <strong>

              ${escaparHTML(
                post.nome
              )}

            </strong>


            <span>

              ${escaparHTML(
                post.usuario
              )}

              ${

                post.data

                  ? ` • ${escaparHTML(
                      formatarDataRelativa(
                        post.data
                      )
                    )}`

                  : ""

              }

            </span>

          </div>


          ${

            ehMeuPost

              ? `

                <div class="post-topo-acoes">

                  <button
                    class="btn-icon"
                    type="button"
                    data-action="abrir-editar-post"
                    data-post-id="${post.id}"
                    aria-label="Editar post"
                  >

                    <i data-lucide="pencil"></i>

                  </button>


                  <button
                    class="btn-icon"
                    type="button"
                    data-action="abrir-excluir-post"
                    data-post-id="${post.id}"
                    aria-label="Excluir post"
                  >

                    <i data-lucide="trash-2"></i>

                  </button>

                </div>

              `

              : criarBotaoSeguir(
                  post
                )

          }

        </div>


        ${

          deveMostrarComunidade

            ? `

              <button
                class="post-community-badge"
                type="button"
                data-action="filtrar-comunidade"
                data-community-id="${escaparHTML(
                  String(
                    comunidadeId
                  )
                )}"
                aria-label="Ver posts da comunidade ${escaparHTML(
                  comunidadeNome
                )}"
              >

                <i data-lucide="users-round"></i>

                <span>

                  Publicado em

                  <strong>

                    ${escaparHTML(
                      comunidadeNome
                    )}

                  </strong>

                </span>

              </button>

            `

            : ""

        }


        ${

          post.texto

            ? `

              <p class="post-texto">

                ${escaparHTML(
                  post.texto
                )}

              </p>

            `

            : ""

        }


        ${

          post.imagem

            ? `

              <div class="post-img-wrap">

                <img
                  class="post-img"
                  src="${escaparHTML(
                    post.imagem
                  )}"
                  alt=""
                >

              </div>

            `

            : ""

        }


        <div class="post-acoes">


          <button
            class="
              like
              ${post.liked ? "liked" : ""}
            "
            type="button"
            data-action="toggle-like"
            data-post-id="${post.id}"
          >

            <i data-lucide="heart"></i>

            <span>
              ${post.likes}
            </span>

          </button>


          <button
            class="comment-badge"
            type="button"
            data-action="toggle-comments"
            data-post-id="${post.id}"
            aria-expanded="false"
            aria-controls="comments-panel-${post.id}"
          >

            <i data-lucide="message-circle"></i>

            <span data-role="comment-count">
              ${totalComentarios}
            </span>

          </button>


        </div>


        <div
          id="comments-panel-${post.id}"
          class="comments-panel"
          data-role="comments-panel"
          data-post-id="${post.id}"
          hidden
        >


          <div
            class="comentarios"
            data-role="comments-list"
          ></div>


          <div class="add-comentario">

            <input
              class="input-comentario"
              type="text"
              placeholder="Compartilhe algo..."
              data-role="comment-input"
              data-post-id="${post.id}"
            >


            <button
              class="btn-comentar"
              type="button"
              data-action="criar-comentario"
              data-post-id="${post.id}"
              aria-label="Enviar comentário"
            >

              <i data-lucide="send"></i>

            </button>

          </div>


        </div>

      </article>

    `;

  }


  /* =========================================================
     RENDER FEED
  ========================================================= */

  function renderFeed() {

    if (
      !feedEl
    ) {

      return;

    }


    const postsFiltrados =
      obterPostsFiltrados();


    if (
      !postsFiltrados.length
    ) {


      if (
        filtroFeedAtivo ===
        "following"
      ) {

        feedEl.innerHTML = `

          <div class="empty-feed">

            <div class="empty-icon">
              <i data-lucide="users"></i>
            </div>


            <h3>
              Nenhum post de quem você segue
            </h3>


            <p>
              Quando as pessoas que você acompanha
              publicarem algo, os posts aparecerão aqui.
            </p>


            <a
              href="explorar.html"
              class="empty-btn"
            >

              <i data-lucide="compass"></i>

              <span>
                Explorar pessoas
              </span>

            </a>

          </div>

        `;

      }


      else if (
        filtroFeedAtivo ===
        "communities"
      ) {

        const possuiComunidades =

          obterMinhasComunidades()
            .length > 0;


        feedEl.innerHTML = `

          <div class="empty-feed">

            <div class="empty-icon">

              <i data-lucide="users-round"></i>

            </div>


            <h3>

              ${
                possuiComunidades

                  ? "Nenhum post nesta comunidade"

                  : "Você ainda não participa de comunidades"
              }

            </h3>


            <p>

              ${
                possuiComunidades

                  ? "Quando houver publicações nas comunidades que você participa, elas aparecerão aqui."

                  : "Explore as comunidades do Pace e participe das que combinam com você."
              }

            </p>


            <a
              href="explorar.html"
              class="empty-btn"
            >

              <i data-lucide="compass"></i>

              <span>
                Explorar comunidades
              </span>

            </a>

          </div>

        `;

      }


      else {

        renderEmptyFeed();

      }


      atualizarSentinelaFeed(
        0
      );


      initLucide();

      return;

    }


    const postsVisiveis =

      postsFiltrados.slice(
        0,
        limitePostsVisiveis
      );


    feedEl.innerHTML =

      postsVisiveis

        .map(
          criarPostHTML
        )

        .join("");


    atualizarSentinelaFeed(
      postsFiltrados.length
    );


    initLucide();

  }


  /* =========================================================
     ELEMENTOS DOS COMENTÁRIOS
  ========================================================= */

  function obterElementosComentarios(
    postId
  ) {

    const card =
      obterCard(
        postId
      );


    if (
      !card
    ) {

      return {

        card:
          null,

        botao:
          null,

        contador:
          null,

        painel:
          null,

        lista:
          null,

        input:
          null,

      };

    }


    return {

      card,

      botao:
        card.querySelector(
          '[data-action="toggle-comments"]'
        ),

      contador:
        card.querySelector(
          '[data-role="comment-count"]'
        ),

      painel:
        card.querySelector(
          '[data-role="comments-panel"]'
        ),

      lista:
        card.querySelector(
          '[data-role="comments-list"]'
        ),

      input:
        card.querySelector(
          '[data-role="comment-input"]'
        ),

    };

  }


  function atualizarContadorComentarios(
    postId
  ) {

    const post =
      encontrarPost(
        postId
      );


    if (
      !post
    ) {

      return;

    }


    const {
      contador,
    } =
      obterElementosComentarios(
        postId
      );


    if (
      !contador
    ) {

      return;

    }


    contador.textContent =
      String(
        post.comentarios.length
      );

  }


  function renderComentariosDoPost(
    postId
  ) {

    const post =
      encontrarPost(
        postId
      );


    if (
      !post
    ) {

      return;

    }


    const {
      lista,
      contador,
    } =
      obterElementosComentarios(
        postId
      );


    if (
      !lista
    ) {

      return;

    }


    if (
      !post.comentarios.length
    ) {

      lista.innerHTML = `

        <div class="comentarios-vazio">
          Nenhum comentário ainda.
        </div>

      `;

    }

    else {

      lista.innerHTML =

        post.comentarios

          .map(
            (comentario) =>

              criarComentarioHTML(
                post,
                comentario
              )
          )

          .join("");

    }


    if (
      contador
    ) {

      contador.textContent =
        String(
          post.comentarios.length
        );

    }


    initLucide();

  }


  /* =========================================================
     LAZY LOAD DOS COMENTÁRIOS
  ========================================================= */

  async function alternarComentarios(
    postId,
    button
  ) {

    const post =
      encontrarPost(
        postId
      );


    if (
      !post
    ) {

      return;

    }


    const {
      painel,
      lista,
    } =
      obterElementosComentarios(
        postId
      );


    if (
      !painel ||
      !lista
    ) {

      return;

    }


    if (
      post.comentariosAbertos
    ) {

      post.comentariosAbertos =
        false;


      painel.hidden =
        true;


      button?.classList.remove(
        "active"
      );


      button?.setAttribute(
        "aria-expanded",
        "false"
      );


      return;

    }


    post.comentariosAbertos =
      true;


    painel.hidden =
      false;


    button?.classList.add(
      "active"
    );


    button?.setAttribute(
      "aria-expanded",
      "true"
    );


    if (
      post.comentariosCarregados
    ) {

      renderComentariosDoPost(
        postId
      );

      return;

    }


    lista.innerHTML = `

      <div class="comentarios-carregando">
        Carregando comentários...
      </div>

    `;


    try {

      const comentarios =
        await fetchComments(
          postId
        );


      post.comentarios =
        Array.isArray(
          comentarios
        )

          ? comentarios

          : [];


      post.comentariosCarregados =
        true;


      renderComentariosDoPost(
        postId
      );

    }

    catch (
      error
    ) {

      post.comentariosAbertos =
        false;


      painel.hidden =
        true;


      button?.classList.remove(
        "active"
      );


      button?.setAttribute(
        "aria-expanded",
        "false"
      );


      if (
        !handleAuthError(
          error,
          showToast
        )
      ) {

        showToast(

          error.message ||
          "Não foi possível carregar os comentários.",

          "error"

        );

      }

    }

  }


  /* =========================================================
     SEGUIR / DEIXAR DE SEGUIR
  ========================================================= */

  async function alternarFollow(
    userId,
    button
  ) {

    const userKey =
      String(
        userId
      );


    if (
      !userId ||
      !button ||
      button.disabled ||
      userKey ===
        String(
          usuario.id
        )
    ) {

      return;

    }


    const jaSegue =
      seguindoIds.has(
        userKey
      );


    button.disabled =
      true;


    try {

      if (
        jaSegue
      ) {

        await unfollowUser(
          userId
        );


        seguindoIds.delete(
          userKey
        );

      }

      else {

        await followUser(
          userId
        );


        seguindoIds.add(
          userKey
        );

      }


      postsCarregados.forEach(
        (post) => {

          if (
            String(
              post.userId
            ) ===
            userKey
          ) {

            post.seguindo =
              seguindoIds.has(
                userKey
              );

          }

        }
      );


      const botoes =
        feedEl?.querySelectorAll(

          `[data-action="toggle-follow"][data-user-id="${userId}"]`

        );


      botoes?.forEach(
        (btn) => {

          const seguindo =
            seguindoIds.has(
              userKey
            );


          btn.classList.toggle(
            "seguindo",
            seguindo
          );


          btn.textContent =
            seguindo

              ? "Seguindo"

              : "Seguir";

        }
      );

    }

    catch (
      error
    ) {

      if (
        !handleAuthError(
          error,
          showToast
        )
      ) {

        showToast(

          error.message ||
          "Erro ao atualizar seguimento.",

          "error"

        );

      }

    }

    finally {

      button.disabled =
        false;

    }

  }


  /* =========================================================
     CURTIDAS
  ========================================================= */

  async function alternarLike(
    postId,
    likeButton
  ) {

    const post =
      encontrarPost(
        postId
      );


    if (
      !post ||
      !likeButton ||
      likeButton.disabled
    ) {

      return;

    }


    const curtidoAntes =
      post.liked;


    const likesAntes =
      post.likes;


    const contador =
      likeButton.querySelector(
        "span"
      );


    likeButton.disabled =
      true;


    post.liked =
      !post.liked;


    post.likes =

      post.liked

        ? post.likes + 1

        : Math.max(
            0,
            post.likes - 1
          );


    likeButton.classList.toggle(
      "liked",
      post.liked
    );


    if (
      contador
    ) {

      contador.textContent =
        String(
          post.likes
        );

    }


    try {

      if (
        curtidoAntes
      ) {

        await unlikePost(
          postId
        );

      }

      else {

        await likePost(
          postId
        );

      }


      const atualizado =
        await fetchPostById(
          postId
        );


      atualizarPostNaLista({

        id:
          postId,

        liked:
          atualizado.liked,

        likes:
          atualizado.likes,

      });


      likeButton.classList.toggle(
        "liked",
        atualizado.liked
      );


      if (
        contador
      ) {

        contador.textContent =
          String(
            atualizado.likes
          );

      }

    }

    catch (
      error
    ) {

      post.liked =
        curtidoAntes;


      post.likes =
        likesAntes;


      likeButton.classList.toggle(
        "liked",
        post.liked
      );


      if (
        contador
      ) {

        contador.textContent =
          String(
            post.likes
          );

      }


      if (
        !handleAuthError(
          error,
          showToast
        )
      ) {

        showToast(

          error.message ||
          "Erro ao curtir post.",

          "error"

        );

      }

    }

    finally {

      likeButton.disabled =
        false;

    }

  }


  /* =========================================================
     CRIAR COMENTÁRIO
  ========================================================= */

  async function criarComentarioNoPost(
    postId,
    input
  ) {

    const texto =
      input.value.trim();


    if (
      !texto
    ) {

      showToast(
        "Escreva um comentário antes de enviar.",
        "error"
      );

      return;

    }


    const post =
      encontrarPost(
        postId
      );


    if (
      !post
    ) {

      return;

    }


    input.disabled =
      true;


    const {
      card,
    } =
      obterElementosComentarios(
        postId
      );


    const botaoEnviar =
      card?.querySelector(

        `[data-action="criar-comentario"][data-post-id="${postId}"]`

      );


    if (
      botaoEnviar
    ) {

      botaoEnviar.disabled =
        true;

    }


    try {

      const comentario =
        await createComment(
          postId,
          texto
        );


      post.comentarios.push(
        comentario
      );


      post.comentariosCarregados =
        true;


      post.comentariosAbertos =
        true;


      input.value =
        "";


      renderComentariosDoPost(
        postId
      );


      showToast(
        "Comentário publicado!",
        "success"
      );

    }

    catch (
      error
    ) {

      if (
        !handleAuthError(
          error,
          showToast
        )
      ) {

        showToast(

          error.message ||
          "Erro ao comentar.",

          "error"

        );

      }

    }

    finally {

      input.disabled =
        false;


      if (
        botaoEnviar
      ) {

        botaoEnviar.disabled =
          false;

      }


      input.focus();

    }

  }


  /* =========================================================
     EDITAR COMENTÁRIO
  ========================================================= */

  async function salvarEdicaoComentario() {

    if (
      !comentarioEmEdicao
    ) {

      return;

    }


    const novoTexto =
      editCommentInput
        .value
        .trim();


    if (
      !novoTexto
    ) {

      showToast(
        "O comentário não pode ficar vazio.",
        "error"
      );

      return;

    }


    const {
      postId,
      commentId,
    } =
      comentarioEmEdicao;


    const post =
      encontrarPost(
        postId
      );


    if (
      !post
    ) {

      return;

    }


    confirmEditCommentBtn.disabled =
      true;


    try {

      const atualizado =
        await updateComment(
          commentId,
          novoTexto
        );


      post.comentarios =
        post.comentarios.map(
          (comentario) =>

            comentario.id ===
            commentId

              ? {
                  ...comentario,
                  ...atualizado,
                }

              : comentario
        );


      comentarioEmEdicao =
        null;


      editCommentInput.value =
        "";


      fecharModal(
        editCommentModal
      );


      renderComentariosDoPost(
        postId
      );


      showToast(
        "Comentário atualizado!",
        "success"
      );

    }

    catch (
      error
    ) {

      if (
        !handleAuthError(
          error,
          showToast
        )
      ) {

        showToast(

          error.message ||
          "Erro ao editar comentário.",

          "error"

        );

      }

    }

    finally {

      confirmEditCommentBtn.disabled =
        false;

    }

  }


  /* =========================================================
     EXCLUIR COMENTÁRIO
  ========================================================= */

  async function excluirComentarioConfirmado() {

    if (
      !comentarioParaExcluir
    ) {

      return;

    }


    const {
      postId,
      commentId,
    } =
      comentarioParaExcluir;


    const post =
      encontrarPost(
        postId
      );


    if (
      !post
    ) {

      return;

    }


    confirmDeleteCommentBtn.disabled =
      true;


    try {

      await deleteComment(
        commentId
      );


      post.comentarios =
        post.comentarios.filter(
          (comentario) =>

            comentario.id !==
            commentId
        );


      comentarioParaExcluir =
        null;


      fecharModal(
        confirmDeleteCommentModal
      );


      renderComentariosDoPost(
        postId
      );


      showToast(
        "Comentário excluído!",
        "success"
      );

    }

    catch (
      error
    ) {

      if (
        !handleAuthError(
          error,
          showToast
        )
      ) {

        showToast(

          error.message ||
          "Erro ao excluir comentário.",

          "error"

        );

      }

    }

    finally {

      confirmDeleteCommentBtn.disabled =
        false;

    }

  }


  /* =========================================================
     EDITAR POST
  ========================================================= */

  async function salvarEdicaoPost() {

    if (
      !postEmEdicao
    ) {

      return;

    }


    const novoTexto =
      editPostTexto
        .value
        .trim();


    if (
      !novoTexto
    ) {

      showToast(
        "O texto do post não pode ficar vazio.",
        "error"
      );

      return;

    }


    salvarEditarPost.disabled =
      true;


    const postId =
      postEmEdicao.id;


    try {

      const resposta =
        await updatePost(

          postId,

          novoTexto,

          postEmEdicao.imagem ||
          ""

        );


      postEmEdicao.texto =

        resposta.conteudo ??

        novoTexto;


      const card =
        obterCard(
          postId
        );


      const textoEl =
        card?.querySelector(
          ".post-texto"
        );


      if (
        textoEl
      ) {

        textoEl.textContent =
          postEmEdicao.texto;

      }


      postEmEdicao =
        null;


      editPostTexto.value =
        "";


      fecharModal(
        modalEditarPost
      );


      showToast(
        "Post atualizado!",
        "success"
      );

    }

    catch (
      error
    ) {

      if (
        !handleAuthError(
          error,
          showToast
        )
      ) {

        showToast(

          error.message ||
          "Erro ao editar post.",

          "error"

        );

      }

    }

    finally {

      salvarEditarPost.disabled =
        false;

    }

  }


  /* =========================================================
     EXCLUIR POST
  ========================================================= */

  async function excluirPostConfirmado() {

    if (
      !postParaExcluir
    ) {

      return;

    }


    const postId =
      postParaExcluir.id;


    confirmDeleteBtn.disabled =
      true;


    try {

      await deletePost(
        postId
      );


      postsCarregados =
        postsCarregados.filter(
          (post) =>

            post.id !==
            postId
        );


      removerVinculoComunidadeDoPost(
        postId
      );


      postParaExcluir =
        null;


      fecharModal(
        confirmDeleteModal
      );


      const card =
        obterCard(
          postId
        );


      card?.remove();


      if (
        !obterPostsFiltrados()
          .length
      ) {

        renderFeed();

      }


      showToast(
        "Post excluído!",
        "success"
      );

    }

    catch (
      error
    ) {

      if (
        !handleAuthError(
          error,
          showToast
        )
      ) {

        showToast(

          error.message ||
          "Erro ao excluir post.",

          "error"

        );

      }

    }

    finally {

      confirmDeleteBtn.disabled =
        false;

    }

  }


  /* =========================================================
     EVENTOS DO FEED
  ========================================================= */

  feedEl?.addEventListener(
    "click",
    async (
      event
    ) => {

      const button =
        event.target.closest(
          "button"
        );


      if (
        !button
      ) {

        return;

      }


      const action =
        button.dataset.action;


      const postId =
        Number(
          button.dataset.postId
        );


      const commentId =
        Number(
          button.dataset.commentId
        );


      const userId =
        Number(
          button.dataset.userId
        );


      if (
        action ===
        "filtrar-comunidade"
      ) {

        const comunidadeId =
          button.dataset.communityId;


        if (
          !comunidadeId
        ) {

          return;

        }


        const participaDaComunidade =

          obterMinhasComunidades()

            .some(
              (comunidade) =>

                String(
                  comunidade.id
                ) ===

                String(
                  comunidadeId
                )
            );


        if (
          !participaDaComunidade
        ) {

          localStorage.setItem(

            "paceOpenCommunityId",

            String(
              comunidadeId
            )

          );


          window.location.href =

            `explorar.html?tab=communities&community=${encodeURIComponent(
              String(
                comunidadeId
              )
            )}`;


          return;

        }


        filtroFeedAtivo =
          "communities";


        comunidadeFiltroAtiva =
          String(
            comunidadeId
          );


        feedFilterButtons.forEach(
          (item) => {

            item.classList.toggle(

              "active",

              item.dataset.feedFilter ===
                "communities"

            );

          }
        );


        communityFilters
          ?.classList
          .remove(
            "hidden"
          );


        renderizarFiltrosComunidades();


        resetarPaginacaoFeed();


        renderFeed();


        document
          .querySelector(
            ".feed-filters"
          )
          ?.scrollIntoView({

            behavior:
              "smooth",

            block:
              "start",

          });


        return;

      }


      if (
        action ===
        "toggle-follow"
      ) {

        await alternarFollow(
          userId,
          button
        );

        return;

      }


      if (
        action ===
        "toggle-like"
      ) {

        await alternarLike(
          postId,
          button
        );

        return;

      }


      if (
        action ===
        "toggle-comments"
      ) {

        await alternarComentarios(
          postId,
          button
        );

        return;

      }


      if (
        action ===
        "criar-comentario"
      ) {

        const input =
          feedEl.querySelector(

            `[data-role="comment-input"][data-post-id="${postId}"]`

          );


        if (
          input
        ) {

          await criarComentarioNoPost(
            postId,
            input
          );

        }


        return;

      }


      if (
        action ===
        "abrir-editar-post"
      ) {

        const post =
          encontrarPost(
            postId
          );


        if (
          !post
        ) {

          return;

        }


        postEmEdicao =
          post;


        editPostTexto.value =
          post.texto ||
          "";


        abrirModal(
          modalEditarPost
        );


        return;

      }


      if (
        action ===
        "abrir-excluir-post"
      ) {

        postParaExcluir =
          encontrarPost(
            postId
          );


        abrirModal(
          confirmDeleteModal
        );


        return;

      }


      if (
        action ===
        "abrir-editar-comentario"
      ) {

        const post =
          encontrarPost(
            postId
          );


        const comentario =
          post?.comentarios.find(
            (item) =>

              item.id ===
              commentId
          );


        if (
          !comentario
        ) {

          return;

        }


        comentarioEmEdicao = {
          postId,
          commentId,
        };


        editCommentInput.value =
          comentario.texto ||
          "";


        abrirModal(
          editCommentModal
        );


        return;

      }


      if (
        action ===
        "abrir-excluir-comentario"
      ) {

        comentarioParaExcluir = {
          postId,
          commentId,
        };


        abrirModal(
          confirmDeleteCommentModal
        );


        return;

      }

    }
  );


  /* =========================================================
     ENTER NO COMENTÁRIO
  ========================================================= */

  feedEl?.addEventListener(
    "keydown",
    async (
      event
    ) => {

      const input =
        event.target.closest(
          '[data-role="comment-input"]'
        );


      if (
        input &&
        event.key ===
        "Enter"
      ) {

        event.preventDefault();


        await criarComentarioNoPost(

          Number(
            input.dataset.postId
          ),

          input

        );

      }

    }
  );


  /* =========================================================
     EVENTOS DOS MODAIS
  ========================================================= */

  cancelDeleteBtn
    ?.addEventListener(
      "click",
      () => {

        postParaExcluir =
          null;


        fecharModal(
          confirmDeleteModal
        );

      }
    );


  confirmDeleteBtn
    ?.addEventListener(
      "click",
      excluirPostConfirmado
    );


  cancelDeleteCommentBtn
    ?.addEventListener(
      "click",
      () => {

        comentarioParaExcluir =
          null;


        fecharModal(
          confirmDeleteCommentModal
        );

      }
    );


  confirmDeleteCommentBtn
    ?.addEventListener(
      "click",
      excluirComentarioConfirmado
    );


  cancelarEditarPost
    ?.addEventListener(
      "click",
      () => {

        postEmEdicao =
          null;


        fecharModal(
          modalEditarPost
        );

      }
    );


  salvarEditarPost
    ?.addEventListener(
      "click",
      salvarEdicaoPost
    );


  cancelEditCommentBtn
    ?.addEventListener(
      "click",
      () => {

        comentarioEmEdicao =
          null;


        fecharModal(
          editCommentModal
        );

      }
    );


  confirmEditCommentBtn
    ?.addEventListener(
      "click",
      salvarEdicaoComentario
    );


  /* =========================================================
     FILTROS PRINCIPAIS
  ========================================================= */

  const feedFilterButtons =
    document.querySelectorAll(
      "[data-feed-filter]"
    );


  feedFilterButtons.forEach(
    (button) => {

      button.addEventListener(
        "click",
        () => {


          feedFilterButtons.forEach(
            (item) =>

              item.classList.remove(
                "active"
              )
          );


          button.classList.add(
            "active"
          );


          filtroFeedAtivo =

            button.dataset.feedFilter ||

            "general";


          const comunidadesAtivas =

            filtroFeedAtivo ===
            "communities";


          communityFilters
            ?.classList
            .toggle(
              "hidden",
              !comunidadesAtivas
            );


          if (
            comunidadesAtivas
          ) {

            renderizarFiltrosComunidades();

          }


          resetarPaginacaoFeed();


          renderFeed();

        }
      );

    }
  );


  /* =========================================================
     FILTRO DA COMUNIDADE
  ========================================================= */

  communityFilters
    ?.addEventListener(
      "click",
      (
        event
      ) => {

        const button =
          event.target.closest(
            "[data-community-filter]"
          );


        if (
          !button
        ) {

          return;

        }


        comunidadeFiltroAtiva =

          button.dataset.communityFilter ||

          "all";


        renderizarFiltrosComunidades();


        resetarPaginacaoFeed();


        renderFeed();

      }
    );


  /* =========================================================
     PROGRESSO
  ========================================================= */

  function chaveDataLocal(
    valor
  ) {

    const data =

      valor instanceof Date

        ? valor

        : new Date(
            valor
          );


    if (
      Number.isNaN(
        data.getTime()
      )
    ) {

      return null;

    }


    const ano =
      data.getFullYear();


    const mes =
      String(
        data.getMonth() + 1
      )
        .padStart(
          2,
          "0"
        );


    const dia =
      String(
        data.getDate()
      )
        .padStart(
          2,
          "0"
        );


    return (
      `${ano}-${mes}-${dia}`
    );

  }


  function formatarDuracaoPainel(
    segundos
  ) {

    const total =
      Math.max(
        0,
        Number(
          segundos
        ) || 0
      );


    const horas =
      Math.floor(
        total / 3600
      );


    const minutos =
      Math.floor(
        (
          total % 3600
        ) / 60
      );


    if (
      horas > 0
    ) {

      return minutos > 0

        ? `${horas}h ${minutos}min`

        : `${horas}h`;

    }


    if (
      minutos > 0
    ) {

      return `${minutos}min`;

    }


    return "0min";

  }


  function calcularSequenciaPainel(
    sessoes
  ) {

    const diasAtivos =
      new Set(

        sessoes

          .filter(
            (sessao) =>

              Number(
                sessao?.duracao
              ) > 0
          )

          .map(
            (sessao) =>

              chaveDataLocal(
                sessao?.inicio
              )
          )

          .filter(
            Boolean
          )

      );


    if (
      !diasAtivos.size
    ) {

      return 0;

    }


    let cursor =
      new Date();


    const hoje =
      chaveDataLocal(
        cursor
      );


    if (
      !diasAtivos.has(
        hoje
      )
    ) {

      cursor.setDate(
        cursor.getDate() - 1
      );

    }


    let sequencia =
      0;


    while (
      diasAtivos.has(
        chaveDataLocal(
          cursor
        )
      )
    ) {

      sequencia +=
        1;


      cursor.setDate(
        cursor.getDate() - 1
      );

    }


    return sequencia;

  }


  function escolherMetaEmAndamento(
    metas
  ) {

    const andamento =

      metas.filter(
        (meta) =>

          meta?.status ===
          "em andamento"
      );


    if (
      !andamento.length
    ) {

      return null;

    }


    return andamento

      .slice()

      .sort(
        (
          a,
          b
        ) => {


          if (
            a?.prazo &&
            b?.prazo
          ) {

            return (

              new Date(
                a.prazo
              )

              -

              new Date(
                b.prazo
              )

            );

          }


          if (
            a?.prazo
          ) {

            return -1;

          }


          if (
            b?.prazo
          ) {

            return 1;

          }


          return (

            Number(
              a?.id
            )

            -

            Number(
              b?.id
            )

          );

        }
      )[0];

  }


  function renderizarMetaPainel(
    metas
  ) {

    if (
      !progressGoalTitle ||
      !progressGoalStatus ||
      !progressGoalDescription
    ) {

      return;

    }


    if (
      !metas.length
    ) {

      progressGoalTitle.textContent =
        "Sua primeira meta começa aqui";


      progressGoalStatus.textContent =
        "Começar";


      progressGoalDescription.textContent =
        "Crie uma meta e transforme intenção em direção.";


      return;

    }


    const metaAtiva =
      escolherMetaEmAndamento(
        metas
      );


    if (
      !metaAtiva
    ) {

      progressGoalTitle.textContent =
        "Você concluiu todas as suas metas";


      progressGoalStatus.textContent =
        "Concluídas";


      progressGoalDescription.textContent =
        "Excelente. Quando quiser, defina seu próximo passo.";


      return;

    }


    progressGoalTitle.textContent =

      metaAtiva.titulo ||

      "Meta em andamento";


    progressGoalStatus.textContent =
      "Em andamento";


    if (
      metaAtiva.prazo
    ) {

      const prazo =
        new Date(
          `${metaAtiva.prazo}T12:00:00`
        );


      progressGoalDescription.textContent =

        Number.isNaN(
          prazo.getTime()
        )

          ? "Continue avançando no seu ritmo."

          : `Prazo: ${
              new Intl.DateTimeFormat(
                "pt-BR",
                {
                  day:
                    "2-digit",

                  month:
                    "short",

                  year:
                    "numeric",
                }
              ).format(
                prazo
              )
            }`;


      return;

    }


    progressGoalDescription.textContent =

      metaAtiva.descricao ||

      "Continue avançando no seu ritmo.";

  }


  function renderizarPainelIndisponivel() {

    if (
      progressStreak
    ) {

      progressStreak.textContent =
        "--";

    }


    if (
      progressStreakLabel
    ) {

      progressStreakLabel.textContent =
        "Dados indisponíveis";

    }


    if (
      progressFocusToday
    ) {

      progressFocusToday.textContent =
        "--";

    }


    if (
      progressGoalTitle
    ) {

      progressGoalTitle.textContent =
        "Não foi possível carregar";

    }


    if (
      progressGoalStatus
    ) {

      progressGoalStatus.textContent =
        "Indisponível";

    }


    if (
      progressGoalDescription
    ) {

      progressGoalDescription.textContent =
        "Seu feed continua funcionando normalmente.";

    }

  }


  async function carregarPainelProgresso() {

    try {

      const metasResposta =
        await apiFetch(

          "/metas/listar_metas",

          {

            auth:
              true,

            fallbackMessage:
              "Não foi possível carregar suas metas.",

          }

        );


      const metas =
        Array.isArray(
          metasResposta
        )

          ? metasResposta

          : [];


      renderizarMetaPainel(
        metas
      );


      const resultadosSessoes =
        await Promise.allSettled(

          metas.map(
            (meta) =>

              apiFetch(

                `/sessoes/meta/${meta.id}`,

                {

                  auth:
                    true,

                  fallbackMessage:
                    "Não foi possível carregar suas sessões.",

                }

              )
          )

        );


      const sessoes =
        resultadosSessoes.flatMap(
          (resultado) =>

            resultado.status ===
            "fulfilled"

              ? (
                  Array.isArray(
                    resultado.value
                  )

                    ? resultado.value

                    : []
                )

              : []
        );


      const hoje =
        chaveDataLocal(
          new Date()
        );


      const focoHoje =

        sessoes

          .filter(
            (sessao) =>

              chaveDataLocal(
                sessao?.inicio
              ) ===
              hoje
          )

          .reduce(

            (
              total,
              sessao
            ) =>

              total +

              Math.max(
                0,
                Number(
                  sessao?.duracao
                ) || 0
              ),

            0

          );


      const sequencia =
        calcularSequenciaPainel(
          sessoes
        );


      if (
        progressStreak
      ) {

        progressStreak.textContent =
          String(
            sequencia
          );

      }


      if (
        progressStreakLabel
      ) {

        progressStreakLabel.textContent =

          sequencia === 1

            ? "dia de constância"

            : "dias de constância";

      }


      if (
        progressFocusToday
      ) {

        progressFocusToday.textContent =
          formatarDuracaoPainel(
            focoHoje
          );

      }


      initLucide();

    }

    catch (
      error
    ) {

      if (
        handleAuthError(
          error,
          showToast
        )
      ) {

        return;

      }


      console.error(
        "Erro ao carregar painel de progresso:",
        error
      );


      renderizarPainelIndisponivel();

    }

  }


  /* =========================================================
     INICIALIZAÇÃO DO FEED
  ========================================================= */

  async function initFeed() {

    try {

      const userAPI =
        await fetchCurrentProfile();


      usuario = {

        ...usuario,
        ...userAPI,

      };


      saveCurrentUser(
        usuario
      );


      updateSidebarPhoto(
        usuario
      );


      void carregarPainelProgresso();


      try {

        const seguindoResposta =
          await fetchFollowing(
            usuario.id
          );


        seguindoIds =
          new Set(

            (
              seguindoResposta?.usuarios ||
              []
            )

              .map(
                (user) =>
                  String(
                    user.id
                  )
              )

          );

      }

      catch {

        seguindoIds =
          new Set();

      }


      const feed =
        await fetchFeed();


      postsCarregados =
        aplicarVinculosComunidades(

          feed.map(
            (post) => ({

              ...post,

              seguindo:

                seguindoIds.has(
                  String(
                    post.userId
                  )
                ),

              comentarios:
                [],

              comentariosCarregados:
                false,

              comentariosAbertos:
                false,

            })
          )

        );


      renderizarFiltrosComunidades();


      resetarPaginacaoFeed();


      renderFeed();


      configurarInfiniteScroll();

    }

    catch (
      error
    ) {

      if (
        !handleAuthError(
          error,
          showToast
        )
      ) {

        showToast(

          error.message ||
          "Não foi possível carregar o feed.",

          "error"

        );


        renderEmptyFeed();

      }

    }

  }


  initFeed();

}