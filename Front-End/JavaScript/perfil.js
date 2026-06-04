import { initAppShell } from "./shared/app-shell.js";
import {
  getCurrentUser,
  saveCurrentUser,
  handleAuthError,
} from "./shared/auth.js";
import { showToast, initLucide } from "./shared/ui.js";
import { escaparHTML, formatarDataCurta, compactarImagem } from "./shared/utils.js";
import { STORAGE_KEYS } from "./shared/config.js";
import { getUsersCache, upsertUserCache, resolveUserPhoto } from "./shared/users-cache.js";
import { fetchCurrentProfile, updateProfilePhoto } from "./shared/services/profile-service.js";
import { fetchFeed } from "./shared/services/post-service.js";
import { fetchComments } from "./shared/services/comment-service.js";

const shellOk = await initAppShell();

if (shellOk) {
  let usuario = getCurrentUser();

  const nomeEl = document.getElementById("nomeUsuario");
  const emailEl = document.getElementById("emailUsuario");
  const fotoEl = document.getElementById("fotoPerfil");
  const inputFoto = document.getElementById("inputFoto");
  const bioInput = document.getElementById("bioUsuario");
  const btnSalvarBio = document.getElementById("salvarBio");
  const modal = document.getElementById("modalPost");
  const modalImg = document.getElementById("modalImg");
  const modalTexto = document.getElementById("modalTexto");
  const modalLikes = document.getElementById("modalLikes");
  const modalComentarios = document.getElementById("modalComentarios");
  const fecharModalBtn = document.getElementById("fecharModal");

  function totalSeguidoresUsuario() {
    return (
      usuario?.seguidores_count ??
      usuario?.total_seguidores ??
      usuario?.followers_count ??
      usuario?.seguidores ??
      usuario?.followers ??
      0
    );
  }

  function totalSeguindoUsuario() {
    return (
      usuario?.seguindo_count ??
      usuario?.total_seguindo ??
      usuario?.following_count ??
      usuario?.seguindo ??
      usuario?.following ??
      0
    );
  }

  function atualizarFotoGlobal() {
    const user = getCurrentUser();
    if (!user) return;

    const foto = resolveUserPhoto(user);

    document.querySelectorAll(".foto-perfil").forEach((img) => {
      img.src = foto;
    });

    if (fotoEl) fotoEl.src = foto;
  }

  function preencherDadosPerfil() {
    if (!usuario) return;

    if (nomeEl) nomeEl.innerText = usuario.username || "";
    if (emailEl) emailEl.innerText = usuario.email || "";

    const cache = getUsersCache();
    if (bioInput) bioInput.value = cache[usuario.username]?.bio || "";

    atualizarFotoGlobal();
  }

  btnSalvarBio?.addEventListener("click", () => {
    upsertUserCache(usuario.username, {
      bio: bioInput.value,
      foto: resolveUserPhoto(usuario),
    });

    showToast("Bio salva com sucesso!", "success");
  });

  inputFoto?.addEventListener("change", async () => {
    const file = inputFoto.files?.[0];
    if (!file) return;

    const fotoAnterior = resolveUserPhoto(usuario);

    try {
      const novaFoto = await compactarImagem(file, 300, 0.8);
      const resposta = await updateProfilePhoto(novaFoto);

      usuario.foto = resposta.foto_perfil || novaFoto;
      usuario.foto_perfil = resposta.foto_perfil || novaFoto;

      saveCurrentUser(usuario);
      upsertUserCache(usuario.username, { foto: usuario.foto_perfil });

      atualizarFotoGlobal();
      showToast("Foto atualizada com sucesso!", "success");
    } catch (error) {
      if (fotoEl) fotoEl.src = fotoAnterior;

      if (!handleAuthError(error, showToast)) {
        showToast(error.message || "Erro ao atualizar foto.", "error");
      }
    } finally {
      inputFoto.value = "";
    }
  });

  function carregarStatsCache() {
    const cache = JSON.parse(localStorage.getItem(STORAGE_KEYS.perfilStats));
    if (!cache || cache.userId !== usuario.id) return;

    const totalPostsEl = document.getElementById("totalPosts");
    const totalSeguidoresEl = document.getElementById("totalSeguidores");
    const totalSeguindoEl = document.getElementById("totalSeguindo");

    if (totalPostsEl) totalPostsEl.innerText = cache.totalPosts ?? 0;
    if (totalSeguidoresEl) totalSeguidoresEl.innerText = cache.totalSeguidores ?? 0;
    if (totalSeguindoEl) totalSeguindoEl.innerText = cache.totalSeguindo ?? 0;
  }

  function salvarStatsCache(stats) {
    localStorage.setItem(
      STORAGE_KEYS.perfilStats,
      JSON.stringify({ userId: usuario.id, ...stats })
    );
  }

  function carregarStatsUsuario(posts) {
    const stats = {
      totalPosts: posts.length,
      totalSeguidores: totalSeguidoresUsuario(),
      totalSeguindo: totalSeguindoUsuario(),
    };

    const totalPostsEl = document.getElementById("totalPosts");
    const totalSeguidoresEl = document.getElementById("totalSeguidores");
    const totalSeguindoEl = document.getElementById("totalSeguindo");

    if (totalPostsEl) totalPostsEl.innerText = stats.totalPosts;
    if (totalSeguidoresEl) totalSeguidoresEl.innerText = stats.totalSeguidores;
    if (totalSeguindoEl) totalSeguindoEl.innerText = stats.totalSeguindo;

    salvarStatsCache(stats);
  }

  function abrirModal(post) {
    if (!modal) return;

    if (modalImg) {
      modalImg.src = post.imagem || "";
      modalImg.style.display = post.imagem ? "block" : "none";
    }

    if (modalTexto) modalTexto.innerText = post.texto || "";
    if (modalLikes) modalLikes.innerText = post.likes || 0;
    if (modalComentarios) {
      modalComentarios.innerText = (post.comentarios || []).length;
    }

    modal.classList.remove("hidden");
  }

  async function carregarPostsUsuario() {
    const imagensContainer = document.getElementById("postsImagem");
    const textoContainer = document.getElementById("postsTexto");

    if (!imagensContainer || !textoContainer) return [];

    imagensContainer.innerHTML = "";
    textoContainer.innerHTML = "";

    const posts = await fetchFeed();
    const meusPostsBase = posts.filter((p) => p.userId === usuario.id);

    const meusPosts = await Promise.all(
      meusPostsBase.map(async (post) => {
        try {
          const comentarios = await fetchComments(post.id);
          return { ...post, comentarios };
        } catch (error) {
          if (handleAuthError(error, showToast)) throw error;
          return { ...post, comentarios: [] };
        }
      })
    );

    meusPosts.forEach((post) => {
      if (post.imagem) {
        const div = document.createElement("div");
        div.classList.add("post-item");

        div.innerHTML = `
          <img src="${escaparHTML(post.imagem)}" alt="">
          <div class="post-overlay">❤️ ${post.likes || 0} • 💬 ${(post.comentarios || []).length}</div>
        `;

        div.onclick = () => abrirModal(post);
        imagensContainer.appendChild(div);
      }

      if (post.texto) {
        const div = document.createElement("div");
        div.classList.add("post-texto-card");

        div.innerHTML = `
          <p>${escaparHTML(post.texto)}</p>
          <small>${escaparHTML(formatarDataCurta(post.data))} • ❤️ ${post.likes || 0} • 💬 ${(post.comentarios || []).length}</small>
        `;

        div.onclick = () => abrirModal(post);
        textoContainer.appendChild(div);
      }
    });

    return meusPosts;
  }

  fecharModalBtn?.addEventListener("click", () => {
    modal?.classList.add("hidden");
  });

  modal?.addEventListener("click", (event) => {
    if (event.target === modal) {
      modal.classList.add("hidden");
    }
  });

  async function initPerfil() {
    try {
      const userAPI = await fetchCurrentProfile();
      usuario = userAPI;

      saveCurrentUser(userAPI);

      upsertUserCache(userAPI.username, {
        foto: userAPI.foto_perfil || "",
        bio: getUsersCache()[userAPI.username]?.bio || "",
      });

      preencherDadosPerfil();
      carregarStatsCache();
    } catch (error) {
      if (handleAuthError(error, showToast)) return;
      preencherDadosPerfil();
    }

    try {
      const meusPosts = await carregarPostsUsuario();
      carregarStatsUsuario(meusPosts);
    } catch (error) {
      if (!handleAuthError(error, showToast)) {
        showToast(error.message || "Erro ao carregar perfil.", "error");
      }
    }
  }

  initPerfil();
  initLucide();
}