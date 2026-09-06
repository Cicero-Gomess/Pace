import { initAppShell } from "./shared/app-shell.js";

import {
  getCurrentUser,
  handleAuthError,
} from "./shared/auth.js";

import {
  createPost,
} from "./shared/services/post-service.js";

import {
  initLucide,
  syncProfilePhotos,
} from "./shared/ui.js";

import {
  compactarImagem,
  escaparHTML,
} from "./shared/utils.js";

import {
  resolveUserPhoto,
} from "./shared/users-cache.js";

import {
  ApiError,
} from "./shared/api.js";


const COMMUNITY_STORAGE_KEY =
  "paceCommunities";

const COMMUNITY_MEMBERS_STORAGE_KEY =
  "paceCommunityMembers";

const COMMUNITY_POSTS_STORAGE_KEY =
  "paceCommunityPosts";


const shellOk =
  await initAppShell();


if (shellOk) {

  initLucide();

  syncProfilePhotos();


  const user =
    getCurrentUser();


  const nomeAutor =
    document.getElementById(
      "nomeAutor"
    );

  const fotoAutor =
    document.getElementById(
      "fotoPerfil"
    );


  const btn =
    document.getElementById(
      "btnPostar"
    );

  const textarea =
    document.getElementById(
      "textoPost"
    );

  const contador =
    document.getElementById(
      "contador"
    );

  const fileInput =
    document.getElementById(
      "imagemPost"
    );

  const previewBox =
    document.getElementById(
      "previewImagem"
    );

  const imgPreview =
    document.getElementById(
      "imgPreview"
    );

  const nomeImagem =
    document.getElementById(
      "nomeImagem"
    );

  const removerBtn =
    document.getElementById(
      "removerImagem"
    );

  const chips =
    document.querySelectorAll(
      ".inspira-chip"
    );


  const communityOptions =
    document.getElementById(
      "communityOptions"
    );

  const communityEmptyState =
    document.getElementById(
      "communityEmptyState"
    );


  if (
    nomeAutor &&
    user
  ) {

    nomeAutor.innerText =
      user.username ||
      "Usuário";

  }


  if (
    fotoAutor &&
    user
  ) {

    fotoAutor.src =
      resolveUserPhoto(
        user
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

    }

    catch {

      return [];

    }

  }


  function salvarArrayLocalStorage(
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


  function obterIdUsuarioAtual() {

    const id =

      user?.id ??

      user?.usuario_id ??

      user?.user_id;


    return (

      id === undefined ||

      id === null ||

      id === ""

    )

      ? ""

      : String(
          id
        );

  }


  /* =========================================================
     COMUNIDADES DO USUÁRIO
  ========================================================= */

  function obterMinhasComunidades() {

    const usuarioId =
      obterIdUsuarioAtual();


    if (
      !usuarioId
    ) {

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
            (
              membro
            ) =>

              String(
                membro.usuarioId
              ) ===
              usuarioId
          )

          .map(
            (
              membro
            ) =>

              String(
                membro.comunidadeId
              )
          )

      );


    return comunidades.filter(
      (
        comunidade
      ) =>

        idsParticipando.has(
          String(
            comunidade.id
          )
        )
    );

  }


  /* =========================================================
     DESTINO DO POST
  ========================================================= */

  function renderizarDestinos() {

    if (
      !communityOptions
    ) {

      return;

    }


    const comunidades =
      obterMinhasComunidades();


    communityOptions.innerHTML = `

      <label class="community-option">

        <input
          type="radio"
          name="comunidadePost"
          value=""
          checked
        >

        <span>
          Feed geral
        </span>

      </label>


      ${

        comunidades

          .map(
            (
              comunidade
            ) => `

              <label class="community-option">

                <input
                  type="radio"
                  name="comunidadePost"
                  value="${escaparHTML(
                    String(
                      comunidade.id
                    )
                  )}"
                >

                <span>

                  ${escaparHTML(
                    comunidade.nome
                  )}

                </span>

              </label>

            `
          )

          .join("")

      }

    `;


    communityEmptyState
      ?.classList
      .toggle(
        "hidden",
        comunidades.length > 0
      );


    initLucide();

  }


  function obterComunidadeSelecionada() {

    const selecionado =
      document.querySelector(
        'input[name="comunidadePost"]:checked'
      );


    const valor =
      selecionado?.value ??
      "";


    return valor

      ? String(
          valor
        )

      : null;

  }


  function usuarioParticipaDaComunidade(
    comunidadeId
  ) {

    if (
      !comunidadeId
    ) {

      return true;

    }


    return obterMinhasComunidades()

      .some(
        (
          comunidade
        ) =>

          String(
            comunidade.id
          ) ===

          String(
            comunidadeId
          )
      );

  }


  /* =========================================================
     VÍNCULO POST ↔ COMUNIDADE
  ========================================================= */

  function obterPostId(
    postCriado
  ) {

    const id =

      postCriado?.id ??

      postCriado?.post_id ??

      postCriado?.postId;


    return (

      id === undefined ||

      id === null ||

      id === ""

    )

      ? null

      : String(
          id
        );

  }


  function salvarVinculoComunidade(
    postCriado,
    comunidadeId
  ) {

    /*
      Post comum não precisa de associação.
    */

    if (
      !comunidadeId
    ) {

      return;

    }


    const postId =
      obterPostId(
        postCriado
      );


    if (
      !postId
    ) {

      throw new Error(
        "O post foi criado, mas o Pace não recebeu o ID necessário para vinculá-lo à comunidade."
      );

    }


    const usuarioId =
      obterIdUsuarioAtual();


    const vinculos =
      obterArrayLocalStorage(
        COMMUNITY_POSTS_STORAGE_KEY
      );


    /*
      Evita vínculo duplicado caso algo
      seja executado novamente.
    */

    const vinculosSemDuplicata =
      vinculos.filter(
        (
          vinculo
        ) =>

          String(
            vinculo.postId
          ) !==
          postId
      );


    vinculosSemDuplicata.push({

      postId,

      comunidadeId:
        String(
          comunidadeId
        ),

      usuarioId,

      dataPublicacao:
        new Date()
          .toISOString(),

    });


    salvarArrayLocalStorage(
      COMMUNITY_POSTS_STORAGE_KEY,
      vinculosSemDuplicata
    );

  }


  /* =========================================================
     CONTADOR
  ========================================================= */

  if (
    textarea &&
    contador
  ) {

    textarea.addEventListener(
      "input",
      () => {

        contador.innerText =
          `${textarea.value.length}/2000`;

      }
    );

  }


  /* =========================================================
     SUGESTÕES
  ========================================================= */

  chips.forEach(
    (
      chip
    ) => {

      chip.addEventListener(
        "click",
        () => {

          if (
            !textarea.value.trim()
          ) {

            textarea.value =
              chip.dataset.texto;

          }

          else {

            textarea.value =
              `${textarea.value.trim()} ${chip.dataset.texto}`;

          }


          textarea.dispatchEvent(
            new Event(
              "input"
            )
          );


          textarea.focus();

        }
      );

    }
  );


  /* =========================================================
     IMAGEM
  ========================================================= */

  fileInput
    ?.addEventListener(
      "change",
      () => {

        const file =
          fileInput.files[0];


        if (
          !file
        ) {

          return;

        }


        const reader =
          new FileReader();


        reader.onload =
          () => {

            imgPreview.src =
              reader.result;


            nomeImagem.innerText =
              file.name;


            previewBox.classList.remove(
              "hidden"
            );

          };


        reader.readAsDataURL(
          file
        );

      }
    );


  removerBtn
    ?.addEventListener(
      "click",
      () => {

        fileInput.value =
          "";


        previewBox.classList.add(
          "hidden"
        );


        imgPreview.src =
          "";


        nomeImagem.innerText =
          "";

      }
    );


  /* =========================================================
     BOTÃO
  ========================================================= */

  function resetButton() {

    btn.disabled =
      false;


    btn.innerHTML = `

      <i data-lucide="send"></i>

      <span>
        Publicar agora
      </span>

    `;


    initLucide();

  }


  /* =========================================================
     PUBLICAR
  ========================================================= */

  btn
    ?.addEventListener(
      "click",
      async () => {

        const texto =
          textarea.value.trim();


        const file =
          fileInput.files[0];


        const comunidadeId =
          obterComunidadeSelecionada();


        if (
          !texto &&
          !file
        ) {

          alert(
            "Escreva algo ou selecione uma imagem!"
          );

          return;

        }


        /*
          Confere novamente a participação
          antes de publicar.
        */

        if (
          comunidadeId &&
          !usuarioParticipaDaComunidade(
            comunidadeId
          )
        ) {

          alert(
            "Você não participa mais desta comunidade. Escolha outro destino."
          );


          renderizarDestinos();

          return;

        }


        btn.disabled =
          true;


        btn.innerHTML = `

          <i data-lucide="loader-circle"></i>

          <span>
            Publicando...
          </span>

        `;


        initLucide();


        try {

          let imagemBase64 =
            null;


          if (
            file
          ) {

            imagemBase64 =
              await compactarImagem(
                file
              );

          }


          /*
            O backend continua exatamente
            como estava.
          */

          const postCriado =
            await createPost(
              texto,
              imagemBase64
            );


          /*
            Se foi publicado em comunidade,
            guardamos apenas a associação
            no navegador.
          */

          salvarVinculoComunidade(
            postCriado,
            comunidadeId
          );


          window.location.href =
            "feed.html";

        }

        catch (
          error
        ) {

          resetButton();


          if (
            handleAuthError(
              error
            )
          ) {

            return;

          }


          alert(

            error instanceof ApiError

              ? error.message

              : (
                  error?.message ||
                  "Erro ao publicar."
                )

          );

        }

      }
    );


  /* =========================================================
     INICIALIZAÇÃO
  ========================================================= */

  renderizarDestinos();


  /*
    Atualiza caso as comunidades sejam
    modificadas em outra aba do navegador.
  */

  window.addEventListener(
    "storage",
    (
      event
    ) => {

      if (

        event.key ===
          COMMUNITY_STORAGE_KEY

        ||

        event.key ===
          COMMUNITY_MEMBERS_STORAGE_KEY

      ) {

        renderizarDestinos();

      }

    }
  );

}