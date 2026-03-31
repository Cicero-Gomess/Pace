function revealOnScroll() {
  const reveals = document.querySelectorAll(".reveal");
  const windowHeight = window.innerHeight;

  reveals.forEach((el) => {
    const elementTop = el.getBoundingClientRect().top;
    const revealPoint = 100;

    if (elementTop < windowHeight - revealPoint) {
      el.classList.add("active");
    }
  });
}

window.addEventListener("scroll", revealOnScroll);
window.addEventListener("load", revealOnScroll);

/* BOTÃO */

const btn = document.getElementById("btn-saiba-mais");
const destino = document.getElementById("porque");

if (btn && destino) {
  btn.addEventListener("click", function (e) {
    e.preventDefault();
    destino.scrollIntoView({ behavior: "smooth" });
  });
}