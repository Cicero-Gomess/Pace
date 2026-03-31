lucide.createIcons();

const toggle = document.getElementById("darkToggle");

/* CARREGAR TEMA */
if(localStorage.getItem("darkMode") === "true"){
document.body.classList.add("dark");
toggle.checked = true;
}

/* TROCAR TEMA */
toggle.addEventListener("change", () => {

if(toggle.checked){
document.body.classList.add("dark");
localStorage.setItem("darkMode", "true");
}else{
document.body.classList.remove("dark");
localStorage.setItem("darkMode", "false");
}

});

/* LOGOUT */
const logoutBtn = document.querySelector(".logout");

logoutBtn.addEventListener("click", () => {

sessionStorage.removeItem("logado");

window.location.href = "entrar.html";

});