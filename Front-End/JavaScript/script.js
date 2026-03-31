let lastScrollTop = 0;

/* REVEAL SCROLL */

function revealOnScroll() {

const reveals = document.querySelectorAll(".reveal");
const windowHeight = window.innerHeight;

reveals.forEach((element) => {

const elementTop = element.getBoundingClientRect().top;
const revealPoint = 50;

if (elementTop < windowHeight - revealPoint) {

element.classList.add("active");

}

});

}

window.addEventListener("scroll", revealOnScroll);
window.addEventListener("load", revealOnScroll);



/* BOTÃO SAIBA MAIS */

const btn = document.getElementById("btn-saiba-mais");
const destino = document.getElementById("porque");

if(btn && destino){

btn.addEventListener("click", function (e) {

e.preventDefault();

const targetPosition = destino.offsetTop;
const startPosition = window.pageYOffset;
const distance = targetPosition - startPosition;
const duration = 2000;

let start = null;

function animation(currentTime) {

if (start === null) start = currentTime;

const timeElapsed = currentTime - start;

const run = easeInOutQuad(timeElapsed, startPosition, distance, duration);

window.scrollTo(0, run);

if (timeElapsed < duration) requestAnimationFrame(animation);

}

function easeInOutQuad(t, b, c, d) {

t /= d / 2;

if (t < 1) return (c / 2) * t * t + b;

t--;

return (-c / 2) * (t * (t - 2) - 1) + b;

}

requestAnimationFrame(animation);

});

}



/* VALIDAÇÃO CADASTRO */

const cadastroForm = document.querySelector("#cadastroForm");

if(cadastroForm){

cadastroForm.addEventListener("submit", function(e){

e.preventDefault();

const usuario = document.querySelector("#cadastroUsuario").value.trim();
const email = document.querySelector("#cadastroEmail").value.trim();
const senha = document.querySelector("#cadastroSenha").value;
const confirmar = document.querySelector("#cadastroConfirmarSenha").value;
const msg = document.querySelector("#cadastroMensagem");

if(usuario === "" || email === "" || senha === "" || confirmar === ""){

msg.innerText = "Preencha todos os campos.";
msg.style.color = "red";
return;

}

if(senha.length < 6){

msg.innerText = "A senha precisa ter pelo menos 6 caracteres.";
msg.style.color = "red";
return;

}

if(senha !== confirmar){

msg.innerText = "As senhas não são iguais.";
msg.style.color = "red";
return;

}

msg.innerText = "Conta criada com sucesso!";
msg.style.color = "green";

cadastroForm.reset();

});

}

/* LOGIN */

const loginForm = document.querySelector("#loginForm");

if(loginForm){

loginForm.addEventListener("submit", function(e){

e.preventDefault();

const email = document.querySelector("#loginEmail").value.trim();
const senha = document.querySelector("#loginSenha").value;
const msg = document.querySelector("#loginMensagem");

const emailValido = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

if(email === "" || senha === ""){

msg.innerText = "Preencha todos os campos.";
msg.style.color = "red";
return;

}

if(!emailValido.test(email)){

msg.innerText = "Digite um email válido.";
msg.style.color = "red";
return;

}

if(senha.length < 6){

msg.innerText = "Senha inválida.";
msg.style.color = "red";
return;

}

msg.innerText = "Login realizado!";
msg.style.color = "green";

loginForm.reset();

});

}

/* ================= CADASTRO ================= */

const formCadastro = document.getElementById("cadastroForm");

if(formCadastro){

formCadastro.addEventListener("submit", function(e){

e.preventDefault();

const usuario = document.getElementById("cadastroUsuario").value;
const email = document.getElementById("cadastroEmail").value;
const senha = document.getElementById("cadastroSenha").value;
const confirmar = document.getElementById("cadastroConfirmarSenha").value;

const mensagem = document.getElementById("cadastroMensagem");

if(senha !== confirmar){
mensagem.innerText = "As senhas não coincidem!";
mensagem.style.color = "red";
return;
}

/* CRIA OBJETO USUÁRIO */
const novoUsuario = {
usuario,
email,
senha
};

/* SALVA NO LOCALSTORAGE */
localStorage.setItem("usuario", JSON.stringify(novoUsuario));

mensagem.innerText = "Cadastro realizado com sucesso!";
mensagem.style.color = "green";

/* REDIRECIONA */
setTimeout(() => {
window.location.href = "entrar.html";
}, 1000);

});

}


/* ================= LOGIN ================= */

const formLogin = document.getElementById("loginForm");

if(formLogin){

formLogin.addEventListener("submit", function(e){

e.preventDefault();

const email = document.getElementById("loginEmail").value;
const senha = document.getElementById("loginSenha").value;

const mensagem = document.getElementById("loginMensagem");

/* PEGA USUÁRIO SALVO */
const usuarioSalvo = JSON.parse(localStorage.getItem("usuario"));

if(!usuarioSalvo){
mensagem.innerText = "Nenhum usuário cadastrado!";
mensagem.style.color = "red";
return;
}

/* VALIDA LOGIN */
if(email === usuarioSalvo.email && senha === usuarioSalvo.senha){

localStorage.setItem("logado", "true");

/* salva nome pra usar depois */
localStorage.setItem("usuarioNome", usuarioSalvo.usuario);

window.location.href = "feed.html";

}else{
mensagem.innerText = "Email ou senha incorretos!";
mensagem.style.color = "red";
}

});

}


/* ================= PROTEÇÃO DO FEED ================= */

if(window.location.pathname.includes("feed.html")){

if(!localStorage.getItem("logado")){
window.location.href = "entrar.html";
}

}


/* ================= LOGOUT ================= */

function logout(){
localStorage.removeItem("logado");
window.location.href = "entrar.html";
}

if(localStorage.getItem("darkMode") === "true"){
document.body.classList.add("dark");
}