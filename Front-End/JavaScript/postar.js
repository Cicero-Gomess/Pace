/* ===== SINCRONIZAR FOTO GLOBAL ===== */
(function () {
  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const userData = usuarios[user.username];
  const foto = userData?.foto || user.foto || "../Images/image.person.png";

  document.querySelectorAll(".foto-perfil").forEach(f => {
    f.src = foto;
  });

  const fotoAutor = document.getElementById("fotoAutor");
  if (fotoAutor) {
    fotoAutor.src = foto;
  }
})();

/* ===== CONFIG ===== */
const darkMode = localStorage.getItem("darkMode");
if (darkMode === "true") document.body.classList.add("dark");
lucide.createIcons();

/* ===== USUÁRIO ===== */
let user = {
  id: null,
  nome: "Usuário",
  usuario: "@anonimo",
  foto: "../Images/image.person.png"
};

const logado = localStorage.getItem("usuarioLogado");

if (logado) {
  try {
    const dados = JSON.parse(logado);
    user.id = dados.id || null;
    user.nome = dados.username || "Usuário";
    user.usuario = dados.username ? `@${dados.username}` : "@anonimo";
    user.foto = dados.foto || "../Images/image.person.png";
  } catch (e) {}
}

const nomeAutor = document.getElementById("nomeAutor");
const fotoAutor = document.getElementById("fotoAutor");

if (nomeAutor) nomeAutor.innerText = user.nome;
if (fotoAutor) fotoAutor.src = user.foto;

/* ===== ELEMENTOS ===== */
const btn = document.getElementById("btnPostar");
const textarea = document.getElementById("textoPost");
const contador = document.getElementById("contador");
const fileInput = document.getElementById("imagemPost");

const previewBox = document.getElementById("previewImagem");
const imgPreview = document.getElementById("imgPreview");
const nomeImagem = document.getElementById("nomeImagem");
const removerBtn = document.getElementById("removerImagem");

const chips = document.querySelectorAll(".inspira-chip");

/* ===== CONTADOR ===== */
if (textarea && contador) {
  textarea.addEventListener("input", () => {
    contador.innerText = `${textarea.value.length}/200`;
  });
}

/* ===== CHIPS DE INSPIRAÇÃO ===== */
chips.forEach(chip => {
  chip.addEventListener("click", () => {
    if (!textarea.value.trim()) {
      textarea.value = chip.dataset.texto;
    } else {
      textarea.value = `${textarea.value.trim()} ${chip.dataset.texto}`;
    }

    textarea.dispatchEvent(new Event("input"));
    textarea.focus();
  });
});

/* ===== PREVIEW IMAGEM ===== */
fileInput.addEventListener("change", () => {
  const file = fileInput.files[0];
  if (!file) return;

  const reader = new FileReader();

  reader.onload = () => {
    imgPreview.src = reader.result;
    nomeImagem.innerText = file.name;
    previewBox.classList.remove("hidden");
  };

  reader.readAsDataURL(file);
});

/* ===== REMOVER IMAGEM ===== */
removerBtn.addEventListener("click", () => {
  fileInput.value = "";
  previewBox.classList.add("hidden");
  imgPreview.src = "";
  nomeImagem.innerText = "";
});

/* ===== COMPACTAR IMAGEM ===== */
async function compactarImagem(file, maxWidth = 1280, quality = 0.82) {
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

/* ===== ENVIAR PARA API ===== */
async function enviarPost(conteudo, imagem) {
  const token = localStorage.getItem("token");

  const response = await fetch("http://127.0.0.1:8000/post/criar_post", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`
    },
    body: JSON.stringify({
      conteudo: conteudo,
      imagem: imagem
    })
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.detail || "Erro ao postar");
  }

  return data;
}

/* ===== POSTAR ===== */
btn.addEventListener("click", async () => {
  const texto = textarea.value.trim();
  const file = fileInput.files[0];

  if (!texto && !file) {
    alert("Escreva algo ou selecione uma imagem!");
    return;
  }

  btn.disabled = true;
  btn.innerHTML = `
    <i data-lucide="loader-circle"></i>
    <span>Publicando...</span>
  `;
  lucide.createIcons();

  const salvarPost = async (imagemBase64 = null) => {
    const novoPost = {
      id: Date.now(),
      userId: user.id,
      nome: user.nome,
      usuario: user.usuario,
      texto: texto,
      imagem: imagemBase64,
      likes: 0,
      liked: false,
      username: user.nome,
      data: new Date().toLocaleString("pt-BR"),
      comentarios: []
    };

    let posts = JSON.parse(localStorage.getItem("posts")) || [];
    posts.unshift(novoPost);
    localStorage.setItem("posts", JSON.stringify(posts));

    try {
      await enviarPost(texto, imagemBase64);
      window.location.href = "feed.html";
    } catch (error) {
      btn.disabled = false;
      btn.innerHTML = `
        <i data-lucide="send"></i>
        <span>Publicar agora</span>
      `;
      lucide.createIcons();
      alert(error.message || "Erro ao publicar.");
    }
  };

  try {
    if (file) {
      const imagemCompactada = await compactarImagem(file);
      await salvarPost(imagemCompactada);
    } else {
      await salvarPost();
    }
  } catch (error) {
    btn.disabled = false;
    btn.innerHTML = `
      <i data-lucide="send"></i>
      <span>Publicar agora</span>
    `;
    lucide.createIcons();
    alert(error.message || "Erro ao processar imagem.");
  }
});
