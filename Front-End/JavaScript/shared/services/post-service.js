import { apiFetch } from "../api.js";
import { formatarDataRelativa } from "../utils.js";
import { AVATAR_PLACEHOLDER } from "../config.js";


export function normalizarComentario(
  comentario
) {
  return {
    id:
      comentario.id,

    texto:
      comentario.conteudo ??
      comentario.texto ??
      comentario.comentario ??
      "",

    userId:
      comentario.usuario?.id ??
      comentario.usuario_id ??
      null,

    username:
      comentario.usuario?.username ??
      comentario.username ??
      "Usuario",

    foto:
      comentario.usuario?.foto_perfil ??
      comentario.foto_perfil ??
      AVATAR_PLACEHOLDER,
  };
}


export function normalizarPost(
  post
) {
  const tipo =
    post.tipo ??
    "geral";

  const meta =
    post.meta
      ? {
          id:
            post.meta.id,

          titulo:
            post.meta.titulo ??
            "",

          categoria:
            post.meta.categoria ??
            "",

          status:
            post.meta.status ??
            "",
        }
      : null;


  return {
    id:
      post.id,

    userId:
      post.usuario?.id ??
      post.usuario_id ??
      null,

    nome:
      post.usuario?.username ??
      "Usuario",

    usuario:
      `@${
        post.usuario?.username ??
        "usuario"
      }`,

    texto:
      post.conteudo ??
      post.texto ??
      "",

    imagem:
      post.imagem ??
      "",

    likes:
      Number(
        post.likes ??
        0
      ),

    liked:
      Boolean(
        post.liked ??
        false
      ),

    foto:
      post.usuario?.foto_perfil ??
      AVATAR_PLACEHOLDER,

    data:
      post.data_postagem ??
      post.data ??
      "",

    totalComentarios:
      Number(
        post.total_comentarios ??
        0
      ),

    comentarios:
      Array.isArray(
        post.comentarios
      )
        ? post.comentarios.map(
            normalizarComentario
          )
        : [],

    comunidade:
      post.comunidade
        ? {
            id:
              post.comunidade.id,

            nome:
              post.comunidade.nome ??
              "Comunidade",
          }
        : null,

    comunidadeId:
      post.comunidade_id ??
      post.comunidade?.id ??
      null,

    tipo,

    metaId:
      post.meta_id ??
      post.meta?.id ??
      null,

    meta,

    sessaoId:
      post.sessao_id ??
      post.sessao?.id ??
      null,

    sessao:
      post.sessao
        ? {
            id:
              post.sessao.id,

            metaId:
              post.sessao.meta_id ??
              null,

            inicio:
              post.sessao.inicio ??
              null,

            duracao:
              Number(
                post.sessao.duracao ??
                0
              ),
          }
        : null,
  };
}


/* =========================================================
   FEEDS
========================================================= */

export async function fetchFeed(
  offset = 0,
  limit = 4,
  tipo = null
) {
  const params =
    new URLSearchParams({
      offset:
        String(offset),

      limit:
        String(limit),
    });


  if (tipo) {
    params.set(
      "tipo",
      String(tipo)
    );
  }


  const data =
    await apiFetch(
      `/post/feed?${params.toString()}`,
      {
        auth:
          true,

        fallbackMessage:
          "Erro ao buscar posts.",
      }
    );


  return Array.isArray(data)
    ? data.map(
        normalizarPost
      )
    : [];
}


export async function fetchFeedSeguindo(
  offset = 0,
  limit = 4,
  tipo = null
) {
  const params =
    new URLSearchParams({
      offset:
        String(offset),

      limit:
        String(limit),
    });


  if (tipo) {
    params.set(
      "tipo",
      String(tipo)
    );
  }


  const data =
    await apiFetch(
      `/post/feed/seguindo?${params.toString()}`,
      {
        auth:
          true,

        fallbackMessage:
          "Erro ao buscar posts de quem você segue.",
      }
    );


  return Array.isArray(data)
    ? data.map(
        normalizarPost
      )
    : [];
}


export async function fetchFeedComunidades(
  comunidadeId = null,
  offset = 0,
  limit = 4,
  tipo = null
) {
  const params =
    new URLSearchParams({
      offset:
        String(offset),

      limit:
        String(limit),
    });


  if (
    comunidadeId !== null &&
    comunidadeId !== undefined
  ) {
    params.set(
      "comunidade_id",
      String(
        comunidadeId
      )
    );
  }


  if (tipo) {
    params.set(
      "tipo",
      String(tipo)
    );
  }


  const data =
    await apiFetch(
      `/post/feed/comunidades?${params.toString()}`,
      {
        auth:
          true,

        fallbackMessage:
          "Erro ao buscar posts das comunidades.",
      }
    );


  return Array.isArray(data)
    ? data.map(
        normalizarPost
      )
    : [];
}


export async function fetchPostsUsuario(
  usuarioId,
  offset = 0,
  limit = 20
) {
  const params =
    new URLSearchParams({
      offset:
        String(offset),

      limit:
        String(limit),
    });


  const data =
    await apiFetch(
      `/post/usuario/${usuarioId}?${params.toString()}`,
      {
        auth:
          true,

        fallbackMessage:
          "Erro ao buscar posts do usuário.",
      }
    );


  return Array.isArray(data)
    ? data.map(
        normalizarPost
      )
    : [];
}


/* =========================================================
   POST INDIVIDUAL
========================================================= */

export async function fetchPostById(
  postId
) {
  const data =
    await apiFetch(
      `/post/${postId}`,
      {
        auth:
          true,

        fallbackMessage:
          "Não foi possível buscar o post.",
      }
    );


  return normalizarPost(
    data
  );
}


/* =========================================================
   CRIAR POST
========================================================= */

export async function createPost(
  conteudo,
  imagem = null,
  comunidadeId = null,
  tipo = "geral",
  metaId = null,
  sessaoId = null
) {
  const body = {
    conteudo,
    imagem,
    tipo,
  };


  if (
    comunidadeId !== null &&
    comunidadeId !== undefined
  ) {
    body.comunidade_id =
      comunidadeId;
  }


  if (
    metaId !== null &&
    metaId !== undefined
  ) {
    body.meta_id =
      metaId;
  }


  if (
    sessaoId !== null &&
    sessaoId !== undefined
  ) {
    body.sessao_id =
      sessaoId;
  }


  const data =
    await apiFetch(
      "/post/criar_post",
      {
        method:
          "POST",

        auth:
          true,

        body,

        fallbackMessage:
          tipo ===
          "conquista"
            ? "Erro ao compartilhar conquista."
            : tipo ===
              "foco"
              ? "Erro ao compartilhar sessão de foco."
              : "Erro ao publicar.",
      }
    );


  return normalizarPost(
    data
  );
}


/* =========================================================
   CURTIDAS
========================================================= */

export async function likePost(
  postId
) {
  return apiFetch(
    `/post/curtir/${postId}`,
    {
      method:
        "POST",

      auth:
        true,

      fallbackMessage:
        "Não foi possível curtir o post.",
    }
  );
}


export async function unlikePost(
  postId
) {
  return apiFetch(
    `/post/remover_curtida/${postId}`,
    {
      method:
        "DELETE",

      auth:
        true,

      fallbackMessage:
        "Não foi possível remover a curtida.",
    }
  );
}


/* =========================================================
   EDITAR POST
========================================================= */

export async function updatePost(
  postId,
  conteudo,
  imagem = "",
  comunidadeId = undefined,
  tipo = undefined,
  metaId = undefined,
  sessaoId = undefined
) {
  const body = {
    conteudo,
    imagem,
  };


  /*
    undefined = não altera a comunidade
    null      = remove a comunidade
    number    = define comunidade
  */
  if (
    comunidadeId !== undefined
  ) {
    body.comunidade_id =
      comunidadeId;
  }


  if (
    tipo !== undefined
  ) {
    body.tipo =
      tipo;
  }


  /*
    undefined = não altera a meta
    null      = remove vínculo
    number    = define vínculo
  */
  if (
    metaId !== undefined
  ) {
    body.meta_id =
      metaId;
  }


  if (
    sessaoId !== undefined
  ) {
    body.sessao_id =
      sessaoId;
  }


  const data =
    await apiFetch(
      `/post/atualizar_post/${postId}`,
      {
        method:
          "PUT",

        auth:
          true,

        body,

        fallbackMessage:
          "Não foi possível editar o post.",
      }
    );


  return normalizarPost(
    data
  );
}


/* =========================================================
   EXCLUIR
========================================================= */

export async function deletePost(
  postId
) {
  return apiFetch(
    `/post/deletar/${postId}`,
    {
      method:
        "DELETE",

      auth:
        true,

      fallbackMessage:
        "Não foi possível excluir o post.",
    }
  );
}


/* =========================================================
   BUSCA
========================================================= */

export async function searchPosts(
  termo
) {
  const q =
    String(
      termo ||
      ""
    ).trim();


  if (!q) {
    return [];
  }


  const data =
    await apiFetch(
      `/post/buscar_post_conteudo/?q=${encodeURIComponent(q)}`,
      {
        auth:
          true,

        fallbackMessage:
          "Erro ao buscar posts.",
      }
    );


  return Array.isArray(data)
    ? data.map(
        normalizarPost
      )
    : [];
}


export {
  formatarDataRelativa,
};