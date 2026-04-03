/* ===== SINCRONIZAR FOTO GLOBAL ===== */
(function () {
  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const userData = usuarios[user.username];
  const foto = userData?.foto || "../Images/image.person.png";

  document.querySelectorAll(".foto-perfil").forEach(f => {
    f.src = foto;
  });
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

    } catch (e) {}
}

/* ===== ELEMENTOS ===== */
const btn = document.getElementById("btnPostar");
const textarea = document.getElementById("textoPost");
const contador = document.getElementById("contador");
const fileInput = document.getElementById("imagemPost");

/* ===== COMUNIDADE ===== */
const selectComunidade = document.getElementById("comunidadePost");

/* ===== PREVIEW ===== */
const previewBox = document.getElementById("previewImagem");
const imgPreview = document.getElementById("imgPreview");
const nomeImagem = document.getElementById("nomeImagem");
const removerBtn = document.getElementById("removerImagem");

/* ===== CONTADOR ===== */
if (textarea && contador) {
    textarea.addEventListener("input", () => {
        contador.innerText = `${textarea.value.length}/200`;
    });
}

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
});

/* ===== POSTAR ===== */
btn.addEventListener("click", () => {

    const texto = textarea.value.trim();
    const file = fileInput.files[0];

    if (!texto && !file) {
        alert("Escreva algo ou selecione uma imagem!");
        return;
    }

    const salvarPost = (imagemBase64 = null) => {

        const novoPost = {
            id: Date.now(),
            userId: user.id,
            nome: user.nome,
            usuario: user.usuario,
            texto: texto,
            imagem: imagemBase64,
            comunidade: selectComunidade.value, // 🔥 CORRETO
            likes: 0,
            liked: false,
            foto: user.foto,
            data: new Date().toLocaleString("pt-BR"),
            comentarios: []
        };

        let posts = JSON.parse(localStorage.getItem("posts")) || [];
        posts.unshift(novoPost);

        localStorage.setItem("posts", JSON.stringify(posts));

        window.location.href = "feed.html";
    };

    if (file) {
        const reader = new FileReader();
        reader.onload = () => salvarPost(reader.result);
        reader.readAsDataURL(file);
    } else {
        salvarPost();
    }
});