import {
  initAppShell,
} from "./shared/app-shell.js";

import {
  isAuthenticated,
  getCurrentUser,
} from "./shared/auth.js";

import {
  initLucide,
} from "./shared/ui.js";

import {
  escaparHTML,
  normalizarTexto,
  formatarDataRelativa,
} from "./shared/utils.js";

import {
  AVATAR_PLACEHOLDER,
} from "./shared/config.js";

import {
  getUsersCache,
} from "./shared/users-cache.js";

import {
  searchProfiles,
} from "./shared/services/profile-service.js";

import {
  apiFetch,
} from "./shared/api.js";


await initAppShell({
  requireLogin: false,
});


/* =========================
   CONFIGURAÇÃO
========================= */

const COMMUNITY_STORAGE_KEY =
  "paceCommunities";

const COMMUNITY_MEMBERS_STORAGE_KEY =
  "paceCommunityMembers";

const COMMUNITY_POSTS_STORAGE_KEY =
  "paceCommunityPosts";


const fallbackProfiles = [
  {
    nome:
      "Lara Mendes",

    username:
      "@laradisciplina",

    bio:
      "Transformando rotina em resultado com constância.",

    avatar:
      AVATAR_PLACEHOLDER,

    tags: [
      "Disciplina",
      "Mindset",
    ],
  },
];


let profilesData = [];

let modalPostsCache = [];

let activeExploreTab =
  "people";

let filtroAtual =
  "todos";

let termoAtual =
  "";

let selectedCommunityId =
  null;


/* =========================
   ELEMENTOS
========================= */

const profilesGrid =
  document.getElementById(
    "profilesGrid"
  );

const searchInput =
  document.getElementById(
    "searchInput"
  );

const chips =
  document.querySelectorAll(
    ".chip"
  );

const profileModal =
  document.getElementById(
    "profileModal"
  );

const closeProfileModal =
  document.getElementById(
    "closeProfileModal"
  );


const exploreTabs =
  document.querySelectorAll(
    "[data-explore-tab]"
  );

const peopleView =
  document.getElementById(
    "peopleView"
  );

const communitiesView =
  document.getElementById(
    "communitiesView"
  );

const communitiesGrid =
  document.getElementById(
    "communitiesGrid"
  );


const openCreateCommunity =
  document.getElementById(
    "openCreateCommunity"
  );

const communityModal =
  document.getElementById(
    "communityModal"
  );

const closeCommunityModal =
  document.getElementById(
    "closeCommunityModal"
  );

const communityForm =
  document.getElementById(
    "communityForm"
  );

const communityFormError =
  document.getElementById(
    "communityFormError"
  );


const communityDetailsModal =
  document.getElementById(
    "communityDetailsModal"
  );

const closeCommunityDetails =
  document.getElementById(
    "closeCommunityDetails"
  );

const communityDetailsBody =
  document.getElementById(
    "communityDetailsBody"
  );


const communityManageModal =
  document.getElementById(
    "communityManageModal"
  );

const closeCommunityManage =
  document.getElementById(
    "closeCommunityManage"
  );

const communityManageForm =
  document.getElementById(
    "communityManageForm"
  );

const communityManageError =
  document.getElementById(
    "communityManageError"
  );

const communityManageMembers =
  document.getElementById(
    "communityManageMembers"
  );

const communityManageMembersCount =
  document.getElementById(
    "communityManageMembersCount"
  );

const deleteManagedCommunity =
  document.getElementById(
    "deleteManagedCommunity"
  );

const communityDeleteModal =
  document.getElementById(
    "communityDeleteModal"
  );

const cancelDeleteCommunity =
  document.getElementById(
    "cancelDeleteCommunity"
  );

const confirmDeleteCommunity =
  document.getElementById(
    "confirmDeleteCommunity"
  );


/* =========================
   PERFIS
========================= */

function buildProfileFromAPI(
  user
) {

  const rawUsername =
    user.username ||
    "Perfil Pace";


  const withoutAt =
    rawUsername.replace(
      /^@/,
      ""
    );


  return {

    id:
      user.id,

    nome:
      withoutAt,

    username:
      `@${withoutAt}`,

    bio:
      user.email
        ? user.email
        : "Perfil no Pace",

    avatar:
      user.foto_perfil ||
      AVATAR_PLACEHOLDER,

    tags: [],

  };

}


function loadSavedProfiles() {

  const savedUsers =
    getUsersCache();


  return Object.entries(
    savedUsers
  ).map(
    ([username, data]) => {

      const clean =
        username.replace(
          /^@/,
          ""
        );


      return {

        nome:
          clean,

        username:
          `@${clean}`,

        bio:
          data.bio ||
          data.email ||
          "Perfil salvo localmente",

        avatar:
          data.foto ||
          data.foto_perfil ||
          AVATAR_PLACEHOLDER,

        tags: [],

      };

    }
  );

}


async function fetchProfiles(
  query = ""
) {

  try {

    const data =
      await searchProfiles({
        username: query,
      });


    if (
      Array.isArray(data) &&
      data.length
    ) {

      profilesData =
        data.map(
          buildProfileFromAPI
        );

      return;

    }


    profilesData =
      loadSavedProfiles();


    if (
      !profilesData.length
    ) {

      profilesData =
        fallbackProfiles;

    }

  } catch (error) {

    console.error(
      "Erro ao buscar perfis:",
      error
    );


    profilesData =
      loadSavedProfiles();


    if (
      !profilesData.length
    ) {

      profilesData =
        fallbackProfiles;

    }

  }

}


/* =========================
   BUSCA
========================= */

function combinarBusca(
  ...campos
) {

  return normalizarTexto(
    campos.join(" ")
  );

}


function profileMatch(
  profile
) {

  const base =
    combinarBusca(
      profile.nome,
      profile.username,
      profile.bio,
      profile.tags.join(" ")
    );


  const termoOk =
    !termoAtual ||
    base.includes(
      normalizarTexto(
        termoAtual
      )
    );


  const filtroOk =
    filtroAtual ===
      "todos"

    ||

    profile.tags.some(
      (tag) =>
        normalizarTexto(
          tag
        ).includes(
          normalizarTexto(
            filtroAtual
          )
        )
    )

    ||

    base.includes(
      normalizarTexto(
        filtroAtual
      )
    );


  return (
    termoOk &&
    filtroOk
  );

}


function renderEmpty(
  container,
  titulo,
  descricao,
  icon = "search-x"
) {

  if (!container) {
    return;
  }


  container.innerHTML = `

    <div class="empty-state">

      <i
        data-lucide="${icon}"
      ></i>

      <h3>
        ${escaparHTML(
          titulo
        )}
      </h3>

      <p>
        ${escaparHTML(
          descricao
        )}
      </p>

    </div>

  `;


  initLucide();

}


/* =========================
   POSTS DO PERFIL
========================= */

async function fetchUserPosts(
  profile
) {

  if (
    !isAuthenticated()
  ) {

    return null;

  }


  try {

    const data =
      await apiFetch(
        "/post/feed",
        {
          auth: true,

          fallbackMessage:
            "Falha ao carregar posts.",
        }
      );


    if (
      !Array.isArray(data)
    ) {

      return [];

    }


    const requestedUsername =
      String(
        profile.username
      )
        .replace(
          /^@/,
          ""
        )
        .toLowerCase();


    return data.filter(
      (post) => {

        const postUserId =
          String(
            post.usuario?.id ??
            ""
          );


        const postUsername =
          String(
            post.usuario
              ?.username ??
            ""
          ).toLowerCase();


        return (

          postUserId ===
            String(
              profile.id
            )

          ||

          postUsername ===
            requestedUsername

        );

      }
    );

  } catch {

    return null;

  }

}


function normalizarPostModal(
  post
) {

  return {

    ...post,

    id:
      Number(
        post.id
      ),

    likes:
      Number(
        post.likes ?? 0
      ),

    liked:
      post.liked === true,

  };

}


function atualizarBotaoLikeModal(
  post
) {

  const button =
    document.querySelector(
      `.modal-like-btn[data-post-id="${post.id}"]`
    );


  if (!button) {
    return;
  }


  button.classList.toggle(
    "liked",
    post.liked
  );


  button.innerHTML = `

    <i data-lucide="heart"></i>

    <span>
      ${post.likes}
    </span>

  `;


  initLucide();

}


async function curtirPostModal(
  postId
) {

  if (
    !isAuthenticated()
  ) {

    alert(
      "Faça login para curtir posts."
    );

    return;

  }


  const post =
    modalPostsCache.find(
      (item) =>
        item.id ===
        Number(postId)
    );


  if (!post) {
    return;
  }


  const likedAntes =
    post.liked;

  const likesAntes =
    post.likes;


  post.liked =
    !likedAntes;


  post.likes =
    likedAntes

      ? Math.max(
          0,
          likesAntes - 1
        )

      : likesAntes + 1;


  atualizarBotaoLikeModal(
    post
  );


  try {

    await apiFetch(

      likedAntes

        ? `/post/remover_curtida/${post.id}`

        : `/post/curtir/${post.id}`,

      {

        method:
          likedAntes
            ? "DELETE"
            : "POST",

        auth: true,

        fallbackMessage:
          "Erro ao curtir post.",

      }
    );

  } catch (error) {

    post.liked =
      likedAntes;

    post.likes =
      likesAntes;


    atualizarBotaoLikeModal(
      post
    );


    alert(
      error.message ||
      "Erro ao curtir post."
    );

  }

}


function attachModalLikeButtons() {

  document
    .querySelectorAll(
      ".modal-like-btn"
    )
    .forEach(
      (button) => {

        button.addEventListener(
          "click",
          () => {

            void curtirPostModal(
              button.dataset.postId
            );

          }
        );

      }
    );

}


function attachProfileButtons() {

  document
    .querySelectorAll(
      ".profile-btn"
    )
    .forEach(
      (button) => {

        button.addEventListener(
          "click",
          async () => {

            const username =
              button.dataset
                .profileUsername;


            const profile =
              profilesData.find(
                (item) =>
                  item.username ===
                  username
              );


            if (profile) {

              await openProfileModal(
                profile
              );

            }

          }
        );

      }
    );

}


async function openProfileModal(
  profile
) {

  if (!profileModal) {
    return;
  }


  const body =
    profileModal.querySelector(
      ".modal-body"
    );


  if (!body) {
    return;
  }


  body.innerHTML = `

    <div class="modal-header">

      <img
        class="modal-avatar"
        src="${escaparHTML(
          profile.avatar
        )}"
        alt=""
      >

      <div class="modal-meta">

        <h2>
          ${escaparHTML(
            profile.nome
          )}
        </h2>

        <p>
          ${escaparHTML(
            profile.username
          )}
        </p>

        <p>
          ${escaparHTML(
            profile.bio
          )}
        </p>

      </div>

    </div>


    <div class="modal-section">

      <h3>
        Postagens
      </h3>

      <div class="modal-posts">

        <div class="modal-loading">
          Carregando...
        </div>

      </div>

    </div>

  `;


  openModal(
    profileModal
  );


  const posts =
    await fetchUserPosts(
      profile
    );


  const postsContainer =
    body.querySelector(
      ".modal-posts"
    );


  if (!postsContainer) {
    return;
  }


  if (
    posts === null
  ) {

    postsContainer.innerHTML = `

      <div class="modal-empty">
        Faça login para ver as postagens.
      </div>

    `;

    return;

  }


  if (
    !posts.length
  ) {

    postsContainer.innerHTML = `

      <div class="modal-empty">
        Nenhuma postagem encontrada.
      </div>

    `;

    return;

  }


  modalPostsCache =
    posts.map(
      normalizarPostModal
    );


  postsContainer.innerHTML =
    modalPostsCache
      .map(
        (post) => {

          const content =
            post.conteudo ||
            "Sem descrição";


          const dataFmt =
            post.data_postagem

              ? formatarDataRelativa(
                  post.data_postagem
                )

              : "";


          return `

            <article class="modal-post-card">

              <h4>

                ${escaparHTML(
                  content.substring(
                    0,
                    120
                  )
                )}

                ${
                  content.length >
                  120
                    ? "..."
                    : ""
                }

              </h4>


              <p>
                ${escaparHTML(
                  content
                )}
              </p>


              ${
                post.imagem

                  ? `

                    <img
                      src="${escaparHTML(
                        post.imagem
                      )}"
                      alt=""
                      class="modal-post-image"
                    >

                  `

                  : ""
              }


              <div class="modal-post-meta">

                <span>
                  ${escaparHTML(
                    dataFmt
                  )}
                </span>


                <button
                  type="button"
                  class="modal-like-btn ${
                    post.liked
                      ? "liked"
                      : ""
                  }"
                  data-post-id="${post.id}"
                >

                  <i data-lucide="heart"></i>

                  <span>
                    ${post.likes}
                  </span>

                </button>

              </div>

            </article>

          `;

        }
      )
      .join("");


  initLucide();

  attachModalLikeButtons();

}


/* =========================
   RENDER PERFIS
========================= */

async function renderProfiles() {

  if (!profilesGrid) {
    return;
  }


  profilesGrid.innerHTML = `

    <div
      class="empty-state loading-state"
    >

      <i data-lucide="refresh-cw"></i>

      <h3>
        Buscando perfis
      </h3>

      <p>
        Aguarde um momento...
      </p>

    </div>

  `;


  initLucide();


  await fetchProfiles(
    termoAtual
  );


  const filtrados =
    profilesData.filter(
      profileMatch
    );


  if (
    !filtrados.length
  ) {

    renderEmpty(
      profilesGrid,
      "Nenhum perfil encontrado",
      "Tente outro termo ou filtro."
    );

    return;

  }


  profilesGrid.innerHTML =
    filtrados
      .map(
        (
          profile,
          index
        ) => `

          <article
            class="profile-card"
            style="animation-delay:${
              0.04 +
              index * 0.04
            }s"
          >

            <div class="profile-topo">

              <img
                src="${escaparHTML(
                  profile.avatar
                )}"
                alt=""
                class="profile-avatar"
              >

              <div>

                <h3 class="profile-nome">
                  ${escaparHTML(
                    profile.nome
                  )}
                </h3>

                <p class="profile-user">
                  ${escaparHTML(
                    profile.username
                  )}
                </p>

              </div>

            </div>


            <p class="profile-bio">
              ${escaparHTML(
                profile.bio
              )}
            </p>


            <div class="profile-stats">

              ${
                profile.tags
                  .map(
                    (tag) => `

                      <span class="profile-pill">
                        ${escaparHTML(
                          tag
                        )}
                      </span>

                    `
                  )
                  .join("")
              }

            </div>


            <button
              type="button"
              class="profile-btn"
              data-profile-username="${escaparHTML(
                profile.username
              )}"
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


/* =========================
   LOCAL STORAGE
========================= */

function getStoredArray(
  key
) {

  try {

    const value =
      JSON.parse(
        localStorage.getItem(
          key
        )
      );


    return Array.isArray(
      value
    )
      ? value
      : [];

  } catch {

    return [];

  }

}


function saveStoredArray(
  key,
  value
) {

  localStorage.setItem(
    key,
    JSON.stringify(
      value
    )
  );

}


function getCommunities() {

  return getStoredArray(
    COMMUNITY_STORAGE_KEY
  );

}


function getCommunityMembers() {

  return getStoredArray(
    COMMUNITY_MEMBERS_STORAGE_KEY
  );

}


/* =========================
   USUÁRIO LOCAL
========================= */

function getCurrentLocalUserId() {

  const currentUser =
    getCurrentUser?.();


  const currentId =
    currentUser?.id ??
    currentUser?.usuario_id ??
    currentUser?.user_id;


  if (
    currentId !== undefined &&
    currentId !== null &&
    currentId !== ""
  ) {

    return String(
      currentId
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
        id !== null &&
        id !== ""
      ) {

        return String(
          id
        );

      }

    } catch {

      // Continua procurando.

    }

  }


  return null;

}


function requireCurrentCommunityUserId() {

  const currentUserId =
    getCurrentLocalUserId();


  if (
    !currentUserId
  ) {

    alert(
      "Faça login para participar ou criar comunidades."
    );

    return null;

  }


  return currentUserId;

}


/* =========================
   COMUNIDADES
========================= */

function makeCommunityId() {

  if (
    window.crypto
      ?.randomUUID
  ) {

    return crypto.randomUUID();

  }


  return `community-${
    Date.now()
  }-${
    Math.random()
      .toString(16)
      .slice(2)
  }`;

}


function normalizeTopics(
  rawValue
) {

  const unique = [];


  String(
    rawValue
  )
    .split(",")
    .map(
      (item) =>
        item.trim()
    )
    .filter(Boolean)
    .forEach(
      (topic) => {

        const normalized =
          normalizarTexto(
            topic
          );


        const exists =
          unique.some(
            (item) =>
              normalizarTexto(
                item
              ) ===
              normalized
          );


        if (!exists) {

          unique.push(
            topic
          );

        }

      }
    );


  return unique.slice(
    0,
    5
  );

}


function communityMatches(
  community
) {

  if (!termoAtual) {
    return true;
  }


  const base =
    combinarBusca(
      community.nome,
      community.descricao,
      ...(
        community.topicos ||
        []
      )
    );


  return base.includes(
    normalizarTexto(
      termoAtual
    )
  );

}


function getCommunityMembership(
  communityId
) {

  const currentUserId =
    getCurrentLocalUserId();


  if (
    !currentUserId
  ) {

    return null;

  }


  return getCommunityMembers()
    .find(
      (member) =>

        String(
          member.comunidadeId
        ) ===
        String(
          communityId
        )

        &&

        String(
          member.usuarioId
        ) ===
        String(
          currentUserId
        )
    );

}


function countCommunityMembers(
  communityId
) {

  return getCommunityMembers()
    .filter(
      (member) =>

        String(
          member.comunidadeId
        ) ===
        String(
          communityId
        )
    )
    .length;

}


function isCommunityCreator(
  community
) {

  const currentUserId =
    getCurrentLocalUserId();


  if (
    !currentUserId
  ) {

    return false;

  }


  return (
    String(
      community.criadorId
    ) ===
    String(
      currentUserId
    )
  );

}


/* =========================
   CARD COMUNIDADE
========================= */

function renderCommunities() {

  if (!communitiesGrid) {
    return;
  }


  const allCommunities =
    getCommunities();


  const communities =
    allCommunities.filter(
      communityMatches
    );


  if (
    !communities.length
  ) {

    const hasCommunities =
      allCommunities.length >
      0;


    renderEmpty(

      communitiesGrid,

      hasCommunities

        ? "Nenhuma comunidade encontrada"

        : "Nenhuma comunidade por enquanto",

      hasCommunities

        ? "Tente pesquisar usando outro nome ou tópico."

        : "Crie a primeira comunidade do Pace e comece a reunir pessoas com interesses em comum.",

      hasCommunities

        ? "search-x"

        : "users-round"

    );


    return;

  }


  communitiesGrid.innerHTML =
    communities
      .map(
        (
          community,
          index
        ) => {

          const topics =
            Array.isArray(
              community.topicos
            )

              ? community.topicos

              : [];


          const membersCount =
            countCommunityMembers(
              community.id
            );


          const membership =
            getCommunityMembership(
              community.id
            );


          const creator =
            isCommunityCreator(
              community
            );


          let statusText =
            "Participar";


          let statusClass =
            "";


          if (creator) {

            statusText =
              "Criador";

            statusClass =
              "joined";

          } else if (
            membership
          ) {

            statusText =
              "Participando";

            statusClass =
              "joined";

          }


          return `

            <article
              class="community-card"
              data-community-id="${escaparHTML(
                String(
                  community.id
                )
              )}"
              style="animation-delay:${
                0.04 +
                index * 0.04
              }s"
              tabindex="0"
              role="button"
              aria-label="Ver comunidade ${escaparHTML(
                community.nome
              )}"
            >


              <div class="community-card-top">

                <div class="community-card-icon">

                  <i data-lucide="users-round"></i>

                </div>


                <span class="community-badge">

                  ${
                    community.privacidade ===
                    "privada"

                      ? "Privada"

                      : "Pública"
                  }

                </span>

              </div>


              <h3>
                ${escaparHTML(
                  community.nome
                )}
              </h3>


              <p>
                ${escaparHTML(
                  community.descricao
                )}
              </p>


              <div class="community-topics">

                ${
                  topics
                    .map(
                      (topic) => `

                        <span class="community-topic">

                          #${escaparHTML(
                            String(
                              topic
                            ).replace(
                              /^#/,
                              ""
                            )
                          )}

                        </span>

                      `
                    )
                    .join("")
                }

              </div>


              <div class="community-card-footer">

                <span class="community-members">

                  ${membersCount}

                  ${
                    membersCount ===
                    1

                      ? "membro"

                      : "membros"
                  }

                </span>


                <span
                  class="community-status ${statusClass}"
                >

                  ${statusText}

                </span>

              </div>


              <div class="community-card-hint">

                <i data-lucide="mouse-pointer-click"></i>

                Clique para ver detalhes

              </div>

            </article>

          `;

        }
      )
      .join("");


  initLucide();

  attachCommunityCards();

}


/* =========================
   MODAL DA COMUNIDADE
========================= */

function openCommunityDetails(
  communityId
) {

  const community =
    getCommunities()
      .find(
        (item) =>
          String(
            item.id
          ) ===
          String(
            communityId
          )
      );


  if (
    !community ||
    !communityDetailsBody
  ) {

    return;

  }


  selectedCommunityId =
    community.id;


  const membersCount =
    countCommunityMembers(
      community.id
    );


  const membership =
    getCommunityMembership(
      community.id
    );


  const creator =
    isCommunityCreator(
      community
    );


  const topics =
    Array.isArray(
      community.topicos
    )

      ? community.topicos

      : [];


  let actionHTML =
    "";


  if (
    creator
  ) {

    actionHTML = `

      <button
        type="button"
        class="community-action-btn secondary"
        id="manageSelectedCommunity"
      >

        <i data-lucide="settings"></i>

        Gerenciar comunidade

      </button>

    `;

  } else if (
    membership
  ) {

    actionHTML = `

      <button
        type="button"
        class="community-action-btn secondary"
        id="leaveSelectedCommunity"
      >

        <i data-lucide="log-out"></i>

        Sair da comunidade

      </button>

    `;

  } else {

    actionHTML = `

      <button
        type="button"
        class="community-action-btn"
        id="joinSelectedCommunity"
      >

        <i data-lucide="user-plus"></i>

        Participar

      </button>

    `;

  }


  communityDetailsBody.innerHTML = `

    <div class="community-modal-header">

      <div class="community-modal-icon">

        <i data-lucide="users-round"></i>

      </div>


      <div class="community-modal-copy">

        <span class="secao-kicker">

          ${
            community.privacidade ===
            "privada"

              ? "Comunidade privada"

              : "Comunidade pública"
          }

        </span>


        <h2>
          ${escaparHTML(
            community.nome
          )}
        </h2>


        <p>
          ${escaparHTML(
            community.descricao
          )}
        </p>


        <div class="community-modal-meta">

          <span>

            <i data-lucide="users"></i>

            ${membersCount}

            ${
              membersCount ===
              1

                ? "membro"

                : "membros"
            }

          </span>


          ${
            creator

              ? `

                <span>

                  <i data-lucide="crown"></i>

                  Você criou esta comunidade

                </span>

              `

              : ""
          }

        </div>

      </div>

    </div>


    <div
      class="community-topics"
      style="margin-top: 1.2rem;"
    >

      ${
        topics
          .map(
            (topic) => `

              <span class="community-topic">

                #${escaparHTML(
                  String(
                    topic
                  ).replace(
                    /^#/,
                    ""
                  )
                )}

              </span>

            `
          )
          .join("")
      }

    </div>


    <div class="community-feed-note">

      <i data-lucide="newspaper"></i>


      <div>

        <strong>
          Onde vejo as atividades desta comunidade?
        </strong>

        <p>
          As publicações desta comunidade aparecem
          no Feed do Pace. Lá você poderá acompanhar
          os posts, curtir e comentar normalmente.
        </p>

      </div>

    </div>


    <div class="community-modal-actions">

      ${actionHTML}

    </div>

  `;


  openModal(
    communityDetailsModal
  );


  document
    .getElementById(
      "joinSelectedCommunity"
    )
    ?.addEventListener(
      "click",
      joinSelectedCommunity
    );


  document
    .getElementById(
      "leaveSelectedCommunity"
    )
    ?.addEventListener(
      "click",
      leaveSelectedCommunity
    );


  document
    .getElementById(
      "manageSelectedCommunity"
    )
    ?.addEventListener(
      "click",
      () => {

        openCommunityManagement(
          community.id
        );

      }
    );


  initLucide();

}


function attachCommunityCards() {

  document
    .querySelectorAll(
      ".community-card"
    )
    .forEach(
      (card) => {

        const openCard =
          () => {

            openCommunityDetails(
              card.dataset
                .communityId
            );

          };


        card.addEventListener(
          "click",
          openCard
        );


        card.addEventListener(
          "keydown",
          (event) => {

            if (
              event.key ===
                "Enter"

              ||

              event.key ===
                " "
            ) {

              event.preventDefault();

              openCard();

            }

          }
        );

      }
    );

}


/* =========================
   GERENCIAMENTO
========================= */

function showCommunityManageError(
  message = ""
) {

  if (
    !communityManageError
  ) {

    return;

  }


  communityManageError.textContent =
    message;


  communityManageError
    .classList
    .toggle(
      "hidden-form-message",
      !message
    );

}


function getMemberDisplayData(
  userId
) {

  const id =
    String(
      userId
    );


  const currentUser =
    getCurrentUser?.();


  const currentUserId =
    currentUser?.id ??
    currentUser?.usuario_id ??
    currentUser?.user_id;


  if (
    currentUserId !== undefined &&
    currentUserId !== null &&
    String(
      currentUserId
    ) === id
  ) {

    const rawUsername =
      currentUser?.username ||
      currentUser?.nome ||
      "Você";


    return {

      nome:
        rawUsername.replace?.(
          /^@/,
          ""
        ) || "Você",

      username:
        currentUser?.username

          ? `@${String(
              currentUser.username
            ).replace(
              /^@/,
              ""
            )}`

          : "Sua conta",

      avatar:
        currentUser?.foto_perfil ||
        currentUser?.foto ||
        AVATAR_PLACEHOLDER,

    };

  }


  const profile =
    profilesData.find(
      (item) =>
        item?.id !== undefined &&
        item?.id !== null &&
        String(
          item.id
        ) === id
    );


  if (
    profile
  ) {

    return {

      nome:
        profile.nome ||
        `Usuário ${id}`,

      username:
        profile.username ||
        `ID ${id}`,

      avatar:
        profile.avatar ||
        AVATAR_PLACEHOLDER,

    };

  }


  return {

    nome:
      `Usuário ${id}`,

    username:
      `ID ${id}`,

    avatar:
      AVATAR_PLACEHOLDER,

  };

}


function renderManagedCommunityMembers(
  community
) {

  if (
    !communityManageMembers ||
    !communityManageMembersCount
  ) {

    return;

  }


  const members =
    getCommunityMembers()
      .filter(
        (member) =>
          String(
            member.comunidadeId
          ) ===
          String(
            community.id
          )
      );


  communityManageMembersCount.textContent =
    `${members.length} ${
      members.length === 1
        ? "membro"
        : "membros"
    }`;


  if (
    !members.length
  ) {

    communityManageMembers.innerHTML = `

      <div class="community-manage-members-empty">

        Nenhum membro encontrado.

      </div>

    `;

    return;

  }


  communityManageMembers.innerHTML =
    members
      .map(
        (member) => {

          const display =
            getMemberDisplayData(
              member.usuarioId
            );


          const isCreator =
            String(
              member.usuarioId
            ) ===
            String(
              community.criadorId
            );


          return `

            <div
              class="community-manage-member"
              data-member-user-id="${escaparHTML(
                String(
                  member.usuarioId
                )
              )}"
            >

              <img
                src="${escaparHTML(
                  display.avatar
                )}"
                alt=""
                class="community-manage-member-avatar"
              >


              <div class="community-manage-member-copy">

                <strong>
                  ${escaparHTML(
                    display.nome
                  )}
                </strong>

                <span>
                  ${escaparHTML(
                    display.username
                  )}
                </span>

              </div>


              <span class="community-manage-member-role ${
                isCreator
                  ? "creator"
                  : ""
              }">

                ${
                  isCreator
                    ? "Criador"
                    : "Membro"
                }

              </span>


              ${
                isCreator

                  ? ""

                  : `

                    <button
                      type="button"
                      class="community-manage-remove-member"
                      data-action="remove-community-member"
                      data-user-id="${escaparHTML(
                        String(
                          member.usuarioId
                        )
                      )}"
                      aria-label="Remover ${escaparHTML(
                        display.nome
                      )} da comunidade"
                    >

                      <i data-lucide="user-minus"></i>

                      Remover

                    </button>

                  `
              }

            </div>

          `;

        }
      )
      .join("");


  initLucide();

}


function openCommunityManagement(
  communityId
) {

  const community =
    getCommunities()
      .find(
        (item) =>
          String(
            item.id
          ) ===
          String(
            communityId
          )
      );


  if (
    !community ||
    !isCommunityCreator(
      community
    ) ||
    !communityManageModal ||
    !communityManageForm
  ) {

    return;

  }


  selectedCommunityId =
    community.id;


  const nameInput =
    communityManageForm.querySelector(
      '[name="nome"]'
    );

  const descriptionInput =
    communityManageForm.querySelector(
      '[name="descricao"]'
    );

  const topicsInput =
    communityManageForm.querySelector(
      '[name="topicos"]'
    );


  if (
    nameInput
  ) {

    nameInput.value =
      community.nome ||
      "";

  }


  if (
    descriptionInput
  ) {

    descriptionInput.value =
      community.descricao ||
      "";

  }


  if (
    topicsInput
  ) {

    topicsInput.value =
      Array.isArray(
        community.topicos
      )

        ? community.topicos.join(
            ", "
          )

        : "";

  }


  communityManageForm
    .querySelectorAll(
      '[name="privacidade"]'
    )
    .forEach(
      (radio) => {

        radio.checked =
          radio.value ===
          (
            community.privacidade ||
            "publica"
          );

      }
    );


  showCommunityManageError(
    ""
  );


  renderManagedCommunityMembers(
    community
  );


  closeModal(
    communityDetailsModal
  );


  openModal(
    communityManageModal
  );

}


function saveManagedCommunity(
  event
) {

  event.preventDefault();


  if (
    !selectedCommunityId ||
    !communityManageForm
  ) {

    return;

  }


  const currentCommunity =
    getCommunities()
      .find(
        (community) =>
          String(
            community.id
          ) ===
          String(
            selectedCommunityId
          )
      );


  if (
    !currentCommunity ||
    !isCommunityCreator(
      currentCommunity
    )
  ) {

    return;

  }


  const formData =
    new FormData(
      communityManageForm
    );


  const nome =
    String(
      formData.get(
        "nome"
      ) ||
      ""
    ).trim();


  const descricao =
    String(
      formData.get(
        "descricao"
      ) ||
      ""
    ).trim();


  const topicos =
    normalizeTopics(
      formData.get(
        "topicos"
      )
    );


  const privacidade =
    String(
      formData.get(
        "privacidade"
      ) ||
      "publica"
    );


  if (
    nome.length < 3
  ) {

    showCommunityManageError(
      "O nome da comunidade precisa ter pelo menos 3 caracteres."
    );

    return;

  }


  if (
    descricao.length < 10
  ) {

    showCommunityManageError(
      "Escreva uma descrição um pouco mais completa."
    );

    return;

  }


  if (
    !topicos.length
  ) {

    showCommunityManageError(
      "Adicione pelo menos 1 tópico à comunidade."
    );

    return;

  }


  const communities =
    getCommunities();


  const duplicatedName =
    communities.some(
      (community) =>

        String(
          community.id
        ) !==
          String(
            selectedCommunityId
          )

        &&

        normalizarTexto(
          community.nome
        ) ===
          normalizarTexto(
            nome
          )
    );


  if (
    duplicatedName
  ) {

    showCommunityManageError(
      "Já existe uma comunidade com esse nome neste navegador."
    );

    return;

  }


  const updatedCommunities =
    communities.map(
      (community) =>

        String(
          community.id
        ) ===
        String(
          selectedCommunityId
        )

          ? {
              ...community,

              nome,

              descricao,

              topicos,

              privacidade,

              dataAtualizacao:
                new Date()
                  .toISOString(),
            }

          : community
    );


  saveStoredArray(
    COMMUNITY_STORAGE_KEY,
    updatedCommunities
  );


  showCommunityManageError(
    ""
  );


  renderCommunities();


  closeModal(
    communityManageModal
  );


  openCommunityDetails(
    selectedCommunityId
  );

}


function removeMemberFromManagedCommunity(
  userId
) {

  if (
    !selectedCommunityId
  ) {

    return;

  }


  const community =
    getCommunities()
      .find(
        (item) =>
          String(
            item.id
          ) ===
          String(
            selectedCommunityId
          )
      );


  if (
    !community ||
    !isCommunityCreator(
      community
    )
  ) {

    return;

  }


  if (
    String(
      userId
    ) ===
    String(
      community.criadorId
    )
  ) {

    return;

  }


  const updatedMembers =
    getCommunityMembers()
      .filter(
        (member) =>
          !(
            String(
              member.comunidadeId
            ) ===
              String(
                selectedCommunityId
              )

            &&

            String(
              member.usuarioId
            ) ===
              String(
                userId
              )
          )
      );


  saveStoredArray(
    COMMUNITY_MEMBERS_STORAGE_KEY,
    updatedMembers
  );


  renderManagedCommunityMembers(
    community
  );


  renderCommunities();

}


function openDeleteCommunityConfirmation() {

  if (
    !selectedCommunityId
  ) {

    return;

  }


  const community =
    getCommunities()
      .find(
        (item) =>
          String(
            item.id
          ) ===
          String(
            selectedCommunityId
          )
      );


  if (
    !community ||
    !isCommunityCreator(
      community
    )
  ) {

    return;

  }


  openModal(
    communityDeleteModal
  );

}


function deleteManagedCommunityConfirmed() {

  if (
    !selectedCommunityId
  ) {

    return;

  }


  const communityId =
    String(
      selectedCommunityId
    );


  const community =
    getCommunities()
      .find(
        (item) =>
          String(
            item.id
          ) ===
          communityId
      );


  if (
    !community ||
    !isCommunityCreator(
      community
    )
  ) {

    return;

  }


  saveStoredArray(

    COMMUNITY_STORAGE_KEY,

    getCommunities()
      .filter(
        (item) =>
          String(
            item.id
          ) !==
          communityId
      )

  );


  saveStoredArray(

    COMMUNITY_MEMBERS_STORAGE_KEY,

    getCommunityMembers()
      .filter(
        (member) =>
          String(
            member.comunidadeId
          ) !==
          communityId
      )

  );


  saveStoredArray(

    COMMUNITY_POSTS_STORAGE_KEY,

    getStoredArray(
      COMMUNITY_POSTS_STORAGE_KEY
    )
      .filter(
        (link) =>
          String(
            link.comunidadeId
          ) !==
          communityId
      )

  );


  selectedCommunityId =
    null;


  closeModal(
    communityDeleteModal
  );


  closeModal(
    communityManageModal
  );


  closeModal(
    communityDetailsModal
  );


  renderCommunities();

}


/* =========================
   PARTICIPAR / SAIR
========================= */

function joinSelectedCommunity() {

  if (
    !selectedCommunityId
  ) {

    return;

  }


  const currentUserId =
    requireCurrentCommunityUserId();


  if (
    !currentUserId
  ) {

    return;

  }


  const members =
    getCommunityMembers();


  const alreadyExists =
    members.some(
      (member) =>

        String(
          member.comunidadeId
        ) ===
        String(
          selectedCommunityId
        )

        &&

        String(
          member.usuarioId
        ) ===
        String(
          currentUserId
        )
    );


  if (
    alreadyExists
  ) {

    return;

  }


  members.push({

    comunidadeId:
      selectedCommunityId,

    usuarioId:
      currentUserId,

    cargo:
      "membro",

    dataEntrada:
      new Date()
        .toISOString(),

  });


  saveStoredArray(
    COMMUNITY_MEMBERS_STORAGE_KEY,
    members
  );


  renderCommunities();


  openCommunityDetails(
    selectedCommunityId
  );

}


function leaveSelectedCommunity() {

  if (
    !selectedCommunityId
  ) {

    return;

  }


  const currentUserId =
    requireCurrentCommunityUserId();


  if (
    !currentUserId
  ) {

    return;

  }


  const community =
    getCommunities()
      .find(
        (item) =>
          String(
            item.id
          ) ===
          String(
            selectedCommunityId
          )
      );


  if (
    community &&
    isCommunityCreator(
      community
    )
  ) {

    alert(
      "O criador não pode sair da própria comunidade."
    );

    return;

  }


  const updatedMembers =
    getCommunityMembers()
      .filter(
        (member) => {

          const sameCommunity =
            String(
              member.comunidadeId
            ) ===
            String(
              selectedCommunityId
            );


          const sameUser =
            String(
              member.usuarioId
            ) ===
            String(
              currentUserId
            );


          return !(
            sameCommunity &&
            sameUser
          );

        }
      );


  saveStoredArray(
    COMMUNITY_MEMBERS_STORAGE_KEY,
    updatedMembers
  );


  renderCommunities();


  openCommunityDetails(
    selectedCommunityId
  );

}


/* =========================
   CRIAR COMUNIDADE
========================= */

function showCommunityFormError(
  message = ""
) {

  if (
    !communityFormError
  ) {

    return;

  }


  communityFormError.textContent =
    message;


  communityFormError
    .classList
    .toggle(
      "hidden-form-message",
      !message
    );

}


function openCommunityCreationModal() {

  if (
    !communityModal
  ) {

    return;

  }


  communityForm?.reset();


  showCommunityFormError(
    ""
  );


  openModal(
    communityModal
  );


  requestAnimationFrame(
    () => {

      document
        .getElementById(
          "communityName"
        )
        ?.focus();

    }
  );

}


function closeCommunityCreationModal() {

  closeModal(
    communityModal
  );


  showCommunityFormError(
    ""
  );

}


function createCommunityFromForm(
  event
) {

  event.preventDefault();


  const formData =
    new FormData(
      communityForm
    );


  const nome =
    String(
      formData.get(
        "nome"
      ) ||
      ""
    ).trim();


  const descricao =
    String(
      formData.get(
        "descricao"
      ) ||
      ""
    ).trim();


  const privacidade =
    String(
      formData.get(
        "privacidade"
      ) ||
      "publica"
    );


  const topicos =
    normalizeTopics(
      formData.get(
        "topicos"
      )
    );


  if (
    nome.length <
    3
  ) {

    showCommunityFormError(
      "O nome da comunidade precisa ter pelo menos 3 caracteres."
    );

    return;

  }


  if (
    descricao.length <
    10
  ) {

    showCommunityFormError(
      "Escreva uma descrição um pouco mais completa."
    );

    return;

  }


  if (
    !topicos.length
  ) {

    showCommunityFormError(
      "Adicione pelo menos 1 tópico à comunidade."
    );

    return;

  }


  const communities =
    getCommunities();


  const duplicatedName =
    communities.some(
      (community) =>

        normalizarTexto(
          community.nome
        ) ===

        normalizarTexto(
          nome
        )
    );


  if (
    duplicatedName
  ) {

    showCommunityFormError(
      "Já existe uma comunidade com esse nome neste navegador."
    );

    return;

  }


  const communityId =
    makeCommunityId();


  const currentUserId =
    requireCurrentCommunityUserId();


  if (
    !currentUserId
  ) {

    return;

  }


  const now =
    new Date()
      .toISOString();


  const newCommunity = {

    id:
      communityId,

    nome,

    descricao,

    topicos,

    privacidade,

    criadorId:
      currentUserId,

    dataCriacao:
      now,

  };


  communities.unshift(
    newCommunity
  );


  saveStoredArray(
    COMMUNITY_STORAGE_KEY,
    communities
  );


  const members =
    getCommunityMembers();


  members.push({

    comunidadeId:
      communityId,

    usuarioId:
      currentUserId,

    cargo:
      "admin",

    dataEntrada:
      now,

  });


  saveStoredArray(
    COMMUNITY_MEMBERS_STORAGE_KEY,
    members
  );


  closeCommunityCreationModal();


  termoAtual =
    "";


  if (
    searchInput
  ) {

    searchInput.value =
      "";

  }


  renderCommunities();


  openCommunityDetails(
    communityId
  );

}


/* =========================
   ABAS
========================= */

function switchExploreTab(
  tab
) {

  activeExploreTab =
    tab;


  termoAtual =
    "";


  if (
    searchInput
  ) {

    searchInput.value =
      "";


    searchInput.placeholder =

      tab ===
        "people"

        ? "Pesquisar perfis"

        : "Pesquisar comunidades";

  }


  exploreTabs.forEach(
    (button) => {

      const isActive =
        button.dataset
          .exploreTab ===
        tab;


      button.classList.toggle(
        "active",
        isActive
      );


      button.setAttribute(
        "aria-selected",
        String(
          isActive
        )
      );

    }
  );


  peopleView
    ?.classList
    .toggle(
      "hidden-view",
      tab !==
        "people"
    );


  communitiesView
    ?.classList
    .toggle(
      "hidden-view",
      tab !==
        "communities"
    );


  if (
    tab ===
    "people"
  ) {

    void renderProfiles();

  } else {

    renderCommunities();

  }


  initLucide();

}


/* =========================
   MODAIS
========================= */

function openModal(
  modal
) {

  if (!modal) {
    return;
  }


  modal.classList.remove(
    "hidden"
  );


  modal.setAttribute(
    "aria-hidden",
    "false"
  );


  document.body
    .classList
    .add(
      "modal-open"
    );


  initLucide();

}


function closeModal(
  modal
) {

  if (!modal) {
    return;
  }


  modal.classList.add(
    "hidden"
  );


  modal.setAttribute(
    "aria-hidden",
    "true"
  );


  const anotherModalOpen =
    document.querySelector(
      ".modal:not(.hidden)"
    );


  if (
    !anotherModalOpen
  ) {

    document.body
      .classList
      .remove(
        "modal-open"
      );

  }

}


/* =========================
   EVENTOS
========================= */

closeProfileModal
  ?.addEventListener(
    "click",
    () => {

      closeModal(
        profileModal
      );

    }
  );


profileModal
  ?.addEventListener(
    "click",
    (event) => {

      if (
        event.target ===
        profileModal
      ) {

        closeModal(
          profileModal
        );

      }

    }
  );


closeCommunityDetails
  ?.addEventListener(
    "click",
    () => {

      closeModal(
        communityDetailsModal
      );

    }
  );


communityDetailsModal
  ?.addEventListener(
    "click",
    (event) => {

      if (
        event.target ===
        communityDetailsModal
      ) {

        closeModal(
          communityDetailsModal
        );

      }

    }
  );


openCreateCommunity
  ?.addEventListener(
    "click",
    openCommunityCreationModal
  );


closeCommunityModal
  ?.addEventListener(
    "click",
    closeCommunityCreationModal
  );


communityModal
  ?.addEventListener(
    "click",
    (event) => {

      if (
        event.target ===
        communityModal
      ) {

        closeCommunityCreationModal();

      }

    }
  );


communityForm
  ?.addEventListener(
    "submit",
    createCommunityFromForm
  );


searchInput
  ?.addEventListener(
    "input",
    async (event) => {

      termoAtual =
        event.target
          .value
          .trim();


      if (
        activeExploreTab ===
        "people"
      ) {

        await renderProfiles();

      } else {

        renderCommunities();

      }

    }
  );


chips.forEach(
  (chip) => {

    chip.addEventListener(
      "click",
      async () => {

        chips.forEach(
          (btn) =>
            btn.classList.remove(
              "active"
            )
        );


        chip.classList.add(
          "active"
        );


        filtroAtual =
          chip.dataset.filter;


        await renderProfiles();

      }
    );

  }
);


exploreTabs.forEach(
  (button) => {

    button.addEventListener(
      "click",
      () => {

        switchExploreTab(
          button.dataset
            .exploreTab
        );

      }
    );

  }
);


closeCommunityManage
  ?.addEventListener(
    "click",
    () => {

      closeModal(
        communityManageModal
      );


      if (
        selectedCommunityId
      ) {

        openCommunityDetails(
          selectedCommunityId
        );

      }

    }
  );


communityManageModal
  ?.addEventListener(
    "click",
    (event) => {

      if (
        event.target ===
        communityManageModal
      ) {

        closeModal(
          communityManageModal
        );


        if (
          selectedCommunityId
        ) {

          openCommunityDetails(
            selectedCommunityId
          );

        }

      }

    }
  );


communityManageForm
  ?.addEventListener(
    "submit",
    saveManagedCommunity
  );


communityManageMembers
  ?.addEventListener(
    "click",
    (event) => {

      const button =
        event.target.closest(
          '[data-action="remove-community-member"]'
        );


      if (
        !button
      ) {

        return;

      }


      removeMemberFromManagedCommunity(
        button.dataset.userId
      );

    }
  );


deleteManagedCommunity
  ?.addEventListener(
    "click",
    openDeleteCommunityConfirmation
  );


cancelDeleteCommunity
  ?.addEventListener(
    "click",
    () => {

      closeModal(
        communityDeleteModal
      );

    }
  );


confirmDeleteCommunity
  ?.addEventListener(
    "click",
    deleteManagedCommunityConfirmed
  );


communityDeleteModal
  ?.addEventListener(
    "click",
    (event) => {

      if (
        event.target ===
        communityDeleteModal
      ) {

        closeModal(
          communityDeleteModal
        );

      }

    }
  );


document.addEventListener(
  "keydown",
  (event) => {

    if (
      event.key !==
      "Escape"
    ) {

      return;

    }


    if (
      communityDeleteModal &&
      !communityDeleteModal
        .classList
        .contains(
          "hidden"
        )
    ) {

      closeModal(
        communityDeleteModal
      );

      return;

    }


    if (
      communityManageModal &&
      !communityManageModal
        .classList
        .contains(
          "hidden"
        )
    ) {

      closeModal(
        communityManageModal
      );


      if (
        selectedCommunityId
      ) {

        openCommunityDetails(
          selectedCommunityId
        );

      }


      return;

    }


    if (
      communityModal &&
      !communityModal
        .classList
        .contains(
          "hidden"
        )
    ) {

      closeCommunityCreationModal();

      return;

    }


    if (
      communityDetailsModal &&
      !communityDetailsModal
        .classList
        .contains(
          "hidden"
        )
    ) {

      closeModal(
        communityDetailsModal
      );

      return;

    }


    if (
      profileModal &&
      !profileModal
        .classList
        .contains(
          "hidden"
        )
    ) {

      closeModal(
        profileModal
      );

    }

  }
);


/* =========================
   ABERTURA VINDO DO FEED
========================= */

function initializeExploreFromNavigation() {

  const params =
    new URLSearchParams(
      window.location.search
    );


  const requestedTab =
    params.get(
      "tab"
    );


  const communityFromUrl =
    params.get(
      "community"
    );


  const communityFromStorage =
    localStorage.getItem(
      "paceOpenCommunityId"
    );


  const requestedCommunityId =
    communityFromUrl ||
    communityFromStorage;


  const shouldOpenCommunities =
    requestedTab ===
      "communities" ||
    Boolean(
      requestedCommunityId
    );


  if (
    !shouldOpenCommunities
  ) {

    switchExploreTab(
      "people"
    );

    return;

  }


  switchExploreTab(
    "communities"
  );


  if (
    !requestedCommunityId
  ) {

    return;

  }


  localStorage.removeItem(
    "paceOpenCommunityId"
  );


  const communityExists =
    getCommunities()
      .some(
        (community) =>
          String(
            community.id
          ) ===
          String(
            requestedCommunityId
          )
      );


  if (
    !communityExists
  ) {

    return;

  }


  requestAnimationFrame(
    () => {

      openCommunityDetails(
        requestedCommunityId
      );

    }
  );

}


/* =========================
   INICIALIZAÇÃO
========================= */

initializeExploreFromNavigation();