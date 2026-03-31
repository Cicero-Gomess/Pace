/* ===== CONFIG ===== */
const API_URL = "http://localhost:8000";

/* ===== ELEMENTOS ===== */
const formLogin = document.getElementById("loginForm");
const mensagem = document.getElementById("loginMensagem");

/* ===== LOGIN ===== */
if (formLogin) {
  formLogin.addEventListener("submit", async (e) => {
    e.preventDefault();

    const usuario = document.getElementById("loginEmail").value.trim();
    const senha = document.getElementById("loginSenha").value.trim();

    /* ===== VALIDAÇÃO ===== */
    if (!usuario || !senha) {
      mensagem.innerText = "Preencha todos os campos.";
      mensagem.style.color = "red";
      return;
    }

    try {
      /* ===== LOGIN NA API ===== */
      const response = await fetch(`${API_URL}/auth/token`, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: new URLSearchParams({
          username: usuario,
          password: senha
        })
      });

      if (!response.ok) {
        const erro = await response.json();
        throw new Error(erro.detail || "Credenciais inválidas.");
      }

      const data = await response.json();

      /* ===== SALVA TOKEN ===== */
      localStorage.setItem("token", data.access_token);

      /* ===== BUSCA USUÁRIO REAL ===== */
      const meResponse = await fetch(`${API_URL}/auth/me`, {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${data.access_token}`
        }
      });

      if (!meResponse.ok) {
        throw new Error("Erro ao obter usuário.");
      }

      const usuarioData = await meResponse.json();

      /* ===== SALVA USUÁRIO NO FRONTEND ===== */
      localStorage.setItem("usuarioLogado", JSON.stringify({
        id: usuarioData.id,
        username: usuarioData.username,
        email: usuarioData.email,
        foto: "../Images/image.person.png"
      }));

      /* ===== SUCESSO ===== */
      mensagem.innerText = "Login realizado com sucesso!";
      mensagem.style.color = "green";

      /* ===== REDIRECIONA ===== */
      setTimeout(() => {
        window.location.href = "feed.html";
      }, 1000);

    } catch (error) {
      console.error(error);
      mensagem.innerText = error.message;
      mensagem.style.color = "red";
    }
  });
}