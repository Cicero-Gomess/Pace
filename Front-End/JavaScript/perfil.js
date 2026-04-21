/* ===== DARK MODE ===== */
const darkMode = localStorage.getItem("darkMode");
if (darkMode === "true") {
  document.body.classList.add("dark");
}

lucide.createIcons();

/* ===== API ===== */
const API_URL = "http://127.0.0.1:8000";
const PERFIL_STATS_CACHE_KEY = "perfilStatsCache";

/* ===== USUÁRIO ===== */
let usuario = JSON.parse(localStorage.getItem("usuarioLogado"));

if (!usuario) {
  alert("Você precisa estar logado.");
  window.location.href = "login.html";
}

/* ===== ELEMENTOS ===== */
const nomeEl = document.getElementById("nomeUsuario");
const emailEl = document.getElementById("emailUsuario");
const fotoEl = document.getElementById("fotoPerfil");
const inputFoto = document.getElementById("inputFoto");

const bioInput = document.getElementById("bioUsuario");
const btnSalvarBio = document.getElementById("salvarBio");

/* ===== FOTO GLOBAL ===== */
function atualizarFotoGlobal() {
  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const userData = usuarios[user.username];
  const foto = userData?.foto || user.foto || "../Images/image.person.png";

  document.querySelectorAll(".foto-perfil").forEach(f => {
    f.src = foto;
  });

  if (fotoEl) fotoEl.src = foto;
}

/* ===== MOSTRAR DADOS ===== */
nomeEl.innerText = usuario.username;
emailEl.innerText = usuario.email;

/* ===== BIO ===== */
const usuariosStorage = JSON.parse(localStorage.getItem("usuarios")) || {};

if (usuariosStorage[usuario.username]?.bio) {
  bioInput.value = usuariosStorage[usuario.username].bio;
}

btnSalvarBio.addEventListener("click", () => {
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  usuarios[usuario.username] = {
    ...usuarios[usuario.username],
    username: usuario.username,
    bio: bioInput.value,
    foto: usuarios[usuario.username]?.foto || usuario.foto
  };

  localStorage.setItem("usuarios", JSON.stringify(usuarios));
});

/* ===== API FOTO ===== */
async function trocarFotoAPI(fotoUrl) {
  const token = localStorage.getItem("token");

  const response = await fetch(`${API_URL}/profile/trocar_foto`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`
    },
    body: JSON.stringify({
      foto_url: fotoUrl
    })
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.detail || "Erro ao atualizar foto.");
  }

  return data;
}

/* ===== COMPACTAR IMAGEM ===== */
async function compactarImagem(file, maxWidth = 300, quality = 0.8) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => {
      const img = new Image();

      img.onload = () => {
        const canvas = document.createElement("canvas");
        const scale = Math.min(1, maxWidth / img.width);

        canvas.width = Math.round(img.width * scale);
        canvas.height = Math.round(img.height * scale);

        const ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

        const imagemCompactada = canvas.toDataURL("image/jpeg", quality);
        resolve(imagemCompactada);
      };

      img.onerror = () => reject(new Error("Erro ao processar imagem."));
      img.src = reader.result;
    };

    reader.onerror = () => reject(new Error("Erro ao ler arquivo."));
    reader.readAsDataURL(file);
  });
}

/* ===== TROCAR FOTO ===== */
inputFoto.addEventListener("change", async () => {
  const file = inputFoto.files[0];
  if (!file) return;

  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};
  const userAtual = JSON.parse(localStorage.getItem("usuarioLogado"));

  if (!userAtual) return;

  const fotoAnterior =
    usuarios[userAtual.username]?.foto ||
    userAtual.foto ||
    "../Images/image.person.png";

  try {
    const novaFoto = await compactarImagem(file);

    await trocarFotoAPI(novaFoto);

    usuarios[userAtual.username] = {
      ...usuarios[userAtual.username],
      username: userAtual.username,
      foto: novaFoto,
      bio: usuarios[userAtual.username]?.bio || ""
    };

    localStorage.setItem("usuarios", JSON.stringify(usuarios));

    userAtual.foto = novaFoto;
    localStorage.setItem("usuarioLogado", JSON.stringify(userAtual));

    usuario = userAtual;
    atualizarFotoGlobal();
  } catch (error) {
    console.error("Erro completo ao trocar foto:", error);
    alert(`Erro ao atualizar foto: ${error.message || error}`);

    if (fotoEl) {
      fotoEl.src = fotoAnterior;
    }
  } finally {
    inputFoto.value = "";
  }
});

/* ===== FEED DA API ===== */
async function getPostsAPI() {
  try {
    const token = localStorage.getItem("token");

    const response = await fetch(`${API_URL}/post/feed`, {
      headers: {
        "Authorization": `Bearer ${token}`
      }
    });

    if (!response.ok) {
      throw new Error("Erro ao buscar posts.");
    }

    const data = await response.json();
    const postsLocal = JSON.parse(localStorage.getItem("posts")) || [];

    return data.map(post => {
      const postLocal = postsLocal.find(item => item.id === post.id);

      return {
        id: post.id,
        userId: post.usuario.id,
        nome: post.usuario.username,
        usuario: `@${post.usuario.username}`,
        texto: post.conteudo,
        imagem: post.imagem,
        comunidade: "geral",
        likes: post.likes ?? 0,
        liked: post.liked ?? false,
        username: post.usuario.username,
        foto: post.usuario.foto_perfil || "../Images/image.person.png",
        data: post.data_postagem,
        comentarios: postLocal?.comentarios || []
      };
    });
  } catch (error) {
    console.error("Erro ao buscar posts da API:", error);
    return JSON.parse(localStorage.getItem("posts")) || [];
  }
}

/* ===== CACHE DE STATS ===== */
function carregarStatsCache() {
  const cache = JSON.parse(localStorage.getItem(PERFIL_STATS_CACHE_KEY));

  if (!cache || cache.userId !== usuario.id) return;

  document.getElementById("totalPosts").innerText = cache.totalPosts ?? 0;
  document.getElementById("totalLikes").innerText = cache.totalLikes ?? 0;
  document.getElementById("totalComentarios").innerText = cache.totalComentarios ?? 0;
}

function salvarStatsCache(stats) {
  localStorage.setItem(
    PERFIL_STATS_CACHE_KEY,
    JSON.stringify({
      userId: usuario.id,
      ...stats
    })
  );
}

/* ===== STATS ===== */
async function carregarStatsUsuario() {
  const posts = await getPostsAPI();
  const meusPosts = posts.filter(p => p.userId === usuario.id);

  let totalLikes = 0;
  let totalComentarios = 0;

  meusPosts.forEach(post => {
    totalLikes += post.likes || 0;
    totalComentarios += (post.comentarios || []).length;
  });

  const stats = {
    totalPosts: meusPosts.length,
    totalLikes,
    totalComentarios
  };

  document.getElementById("totalPosts").innerText = stats.totalPosts;
  document.getElementById("totalLikes").innerText = stats.totalLikes;
  document.getElementById("totalComentarios").innerText = stats.totalComentarios;

  salvarStatsCache(stats);
}

/* ===== REINICIAR ANIMAÇÃO ===== */
function reiniciarAnimacaoPosts(imagensContainer, textoContainer) {
  if (imagensContainer) {
    imagensContainer.style.animation = "none";
  }

  if (textoContainer) {
    textoContainer.style.animation = "none";
  }

  void imagensContainer?.offsetWidth;
  void textoContainer?.offsetWidth;

  if (imagensContainer) {
    imagensContainer.style.animation = "";
  }

  if (textoContainer) {
    textoContainer.style.animation = "";
  }
}

/* ===== POSTS SEPARADOS ===== */
async function carregarPostsUsuario() {
  const posts = await getPostsAPI();

  const imagensContainer = document.getElementById("postsImagem");
  const textoContainer = document.getElementById("postsTexto");

  if (!imagensContainer || !textoContainer) return;

  imagensContainer.innerHTML = "";
  textoContainer.innerHTML = "";

  reiniciarAnimacaoPosts(imagensContainer, textoContainer);

  const meusPosts = posts.filter(p => p.userId === usuario.id);

  meusPosts.forEach(post => {
    if (post.imagem) {
      const div = document.createElement("div");
      div.classList.add("post-item");

      div.innerHTML = `
        <img src="${post.imagem}">
        <div class="post-overlay">
          ❤️ ${post.likes || 0} • 💬 ${(post.comentarios || []).length}
        </div>
      `;

      div.onclick = () => abrirModal(post);
      imagensContainer.appendChild(div);
    }

    if (post.texto) {
      const div = document.createElement("div");
      div.classList.add("post-texto-card");

      div.innerHTML = `
        <p>${post.texto}</p>
        <small>❤️ ${post.likes || 0} • 💬 ${(post.comentarios || []).length}</small>
      `;

      div.onclick = () => abrirModal(post);
      textoContainer.appendChild(div);
    }
  });
}

/* ===== MODAL ===== */
const modal = document.getElementById("modalPost");
const modalImg = document.getElementById("modalImg");
const modalTexto = document.getElementById("modalTexto");
const modalLikes = document.getElementById("modalLikes");
const modalComentarios = document.getElementById("modalComentarios");
const fecharModal = document.getElementById("fecharModal");

function abrirModal(post) {
  modalImg.src = post.imagem || "";
  modalTexto.innerText = post.texto || "";
  modalLikes.innerText = post.likes || 0;
  modalComentarios.innerText = (post.comentarios || []).length;

  modal.classList.remove("hidden");
}

fecharModal.onclick = () => modal.classList.add("hidden");

modal.onclick = e => {
  if (e.target === modal) modal.classList.add("hidden");
};

/* ===== INIT ===== */
async function initPerfil() {
  atualizarFotoGlobal();
  carregarStatsCache();
  await carregarStatsUsuario();
  await carregarPostsUsuario();
}

initPerfil();
