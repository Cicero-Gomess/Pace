import { initAppShell } from "./shared/app-shell.js";

import {
  getCurrentUser,
  handleAuthError,
} from "./shared/auth.js";

import {
  createPost,
} from "./shared/services/post-service.js";

import {
  fetchMinhasComunidades,
} from "./shared/services/community-service.js";

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


  let minhasComunidades = [];


  /* =========================================================
     USUÁRIO
  ========================================================= */

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
     COMUNIDADES DO USUÁRIO
  ========================================================= */

  async function carregarMinhasComunidades() {

    try {

      minhasComunidades =
        await fetchMinhasComunidades();


      return minhasComunidades;

    }

    catch (
      error
    ) {

      if (
        handleAuthError(
          error
        )
      ) {

        return [];

      }


      console.error(
        "Erro ao carregar comunidades:",
        error
      );


      minhasComunidades =
        [];


      return [];

    }

  }


  /* =========================================================
     DESTINO DO POST
  ========================================================= */

  async function renderizarDestinos() {

    if (
      !communityOptions
    ) {

      return;

    }


    const comunidades =
      await carregarMinhasComunidades();


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


    if (
      !valor
    ) {

      return null;

    }


    const id =
      Number(
        valor
      );


    return Number.isFinite(
      id
    )
      ? id
      : null;

  }


  function usuarioParticipaDaComunidade(
    comunidadeId
  ) {

    if (
      comunidadeId === null
    ) {

      return true;

    }


    return minhasComunidades.some(
      (
        comunidade
      ) =>

        Number(
          comunidade.id
        ) ===

        Number(
          comunidadeId
        )
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
          Se escolheu comunidade,
          atualiza a lista antes de publicar.

          Isso evita publicar em uma comunidade
          da qual o usuário acabou de sair
          em outra página/aba.
        */

        if (
          comunidadeId !== null
        ) {

          await carregarMinhasComunidades();


          if (
            !usuarioParticipaDaComunidade(
              comunidadeId
            )
          ) {

            alert(
              "Você não participa mais desta comunidade. Escolha outro destino."
            );


            await renderizarDestinos();


            return;

          }

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
            Agora o vínculo com comunidade
            é salvo diretamente no backend.

            Feed geral:
              comunidadeId = null

            Comunidade:
              comunidadeId = ID da comunidade
          */

          await createPost(
            texto,
            imagemBase64,
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

  await renderizarDestinos();

}