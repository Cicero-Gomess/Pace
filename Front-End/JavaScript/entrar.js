const formLogin = document.getElementById("loginForm");

if (formLogin) {

  formLogin.addEventListener("submit", function (e) {

    e.preventDefault();

    const usuario = document.getElementById("loginEmail").value;
    const senha = document.getElementById("loginSenha").value;

    const mensagem = document.getElementById("loginMensagem");

    if (usuario === "" || senha === "") {
      mensagem.innerText = "Preencha todos os campos.";
      mensagem.style.color = "red";
      return;
    }

    fetch("http://localhost:8000/auth/token", {
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

        // 🔐 salva token
        localStorage.setItem("token", data.access_token);

        // 🔥 buscar dados do usuário
        return fetch("http://localhost:8000/auth/me", {
          headers: {
            "Authorization": "Bearer " + data.access_token
          }
        });

      })
      .then(response => response.json())
      .then(usuarioData => {

        /* ===== NÃO MEXER (SEU PEDIDO) ===== */
        localStorage.setItem("usuarioLogado", JSON.stringify({
          id: usuarioData.id,
          username: usuarioData.username,
          email: usuarioData.email,
          foto: "../Images/image.person.png"
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
        mensagem.innerText = error.detail || "Erro ao fazer login.";
        mensagem.style.color = "red";
      });

  });

}