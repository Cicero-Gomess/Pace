/* ===== DARK MODE ===== */
const darkMode = localStorage.getItem("darkMode");
if (darkMode === "true") document.body.classList.add("dark");

lucide.createIcons();

/* ===== FOTO GLOBAL ===== */
(function () {
  const user = JSON.parse(localStorage.getItem("usuarioLogado"));
  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  if (!user) return;

  const foto = usuarios[user.username]?.foto || "../Images/image.person.png";

  document.querySelectorAll(".foto-perfil").forEach(f => f.src = foto);
})();

/* ===== POSTS ===== */
function getPosts(){
  return JSON.parse(localStorage.getItem("posts")) || [];
}

/* ===== IA SIMPLES ===== */
function gerarRecomendados(posts){

  const usuario = JSON.parse(localStorage.getItem("usuarioLogado"));

  if (!usuario) return posts;

  // comunidades mais usadas
  const minhasComunidades = posts
    .filter(p => p.userId === usuario.id)
    .map(p => p.comunidade);

  return posts.sort((a,b) => {

    let scoreA = 0;
    let scoreB = 0;

    // likes
    scoreA += (a.likes || 0);
    scoreB += (b.likes || 0);

    // comunidade favorita
    if (minhasComunidades.includes(a.comunidade)) scoreA += 5;
    if (minhasComunidades.includes(b.comunidade)) scoreB += 5;

    // aleatório leve
    scoreA += Math.random()*2;
    scoreB += Math.random()*2;

    return scoreB - scoreA;
  });
}

/* ===== RENDER ===== */
function renderLista(lista, containerId){

  const container = document.getElementById(containerId);
  if (!container) return;

  container.innerHTML = "";

  const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

  lista.slice(0,6).forEach(post => {

    const foto =
      usuarios[post.username]?.foto || "../Images/image.person.png";

    const div = document.createElement("div");
    div.classList.add("explorar-card");

    div.innerHTML = `
      ${
        post.imagem
          ? `<img src="${post.imagem}">`
          : `<img src="${foto}">`
      }
      <p>${post.texto || "Post"}</p>
    `;

    container.appendChild(div);
  });
}

/* ===== MAIN ===== */
function renderExplorar(){

  const posts = getPosts();

  const recomendados = gerarRecomendados([...posts]);
  const trending = [...posts].sort((a,b)=> (b.likes||0)-(a.likes||0));

  renderLista(recomendados, "explorarRecomendado");
  renderLista(trending, "explorarTrending");

  renderLista(posts.filter(p=>p.comunidade==="programacao"), "explorarProgramacao");
  renderLista(posts.filter(p=>p.comunidade==="estudos"), "explorarEstudos");
  renderLista(posts.filter(p=>p.comunidade==="academia"), "explorarAcademia");

}

renderExplorar();