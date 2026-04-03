/* ===== CONFIG ===== */
const API_URL = "http://localhost:8000";

/* ===== ELEMENTOS ===== */
const formLogin = document.getElementById("loginForm");
const mensagem = document.getElementById("loginMensagem");

/* ===== LOGIN ===== */
if (formLogin) {

  formLogin.addEventListener("submit", function (e) {

    e.preventDefault();

    const usuario = document.getElementById("loginEmail").value.trim();
    const senha = document.getElementById("loginSenha").value.trim();

    /* ===== VALIDAÇÃO ===== */
    if (usuario === "" || senha === "") {
      mensagem.innerText = "Preencha todos os campos.";
      mensagem.style.color = "red";
      return;
    }

    /* ===== REQUISIÇÃO LOGIN ===== */
    fetch(`${API_URL}/auth/token`, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: new URLSearchParams({
        username: usuario,
        password: senha
      })
    })
      .then(response => {
        if (!response.ok) {
          return response.json().then(err => { throw err });
        }
        return response.json();
      })

      .then(data => {

        /* ===== SALVA TOKEN ===== */
        localStorage.setItem("token", data.access_token);

        /* ===== BUSCAR USUÁRIO ===== */
        return fetch(`${API_URL}/auth/me`, {
          method: "GET",
          headers: {
            "Authorization": "Bearer " + data.access_token
          }
        });

      })

      .then(response => {
        if (!response.ok) {
          throw new Error("Erro ao obter usuário.");
        }
        return response.json();
      })

      .then(usuarioData => {

        /* ===== BUSCAR FOTO SALVA LOCAL ===== */
        const usuarios = JSON.parse(localStorage.getItem("usuarios")) || {};

        let fotoUsuario = "../Images/image.person.png";

        if (usuarios[usuarioData.username] && usuarios[usuarioData.username].foto) {
          fotoUsuario = usuarios[usuarioData.username].foto;
        }

        /* ===== SALVAR USUÁRIO LOGADO ===== */
        localStorage.setItem("usuarioLogado", JSON.stringify({
          id: usuarioData.id,
          username: usuarioData.username,
          email: usuarioData.email,
          foto: fotoUsuario
        }));

        /* ===== SUCESSO ===== */
        mensagem.innerText = "Login realizado com sucesso!";
        mensagem.style.color = "green";

        setTimeout(() => {
          window.location.href = "feed.html";
        }, 1000);

      })

      .catch(error => {
        console.error(error);
        mensagem.innerText = error.detail || error.message || "Erro ao fazer login.";
        mensagem.style.color = "red";
      });

  });

}