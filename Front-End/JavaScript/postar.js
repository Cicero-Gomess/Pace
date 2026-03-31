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

/* ===== CONTADOR ===== */
if (textarea && contador) {
    textarea.addEventListener("input", () => {
        const atual = textarea.value.length;
        contador.innerText = `${atual}/200`;
    });
}

/* ===== POSTAR ===== */
if (btn) {
    btn.addEventListener("click", () => {

        const texto = textarea.value.trim();

        if (!texto) {
            alert("Escreva algo!");
            return;
        }

        const novoPost = {
            id: Date.now(),
            userId: user.id,
            nome: user.nome,
            usuario: user.usuario,
            texto: texto,
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
    });
}