const formCadastro = document.getElementById("cadastroForm");

if (formCadastro) {

  formCadastro.addEventListener("submit", function (e) {

    e.preventDefault();

    const usuario = document.getElementById("cadastroUsuario").value;
    const email = document.getElementById("cadastroEmail").value;
    const senha = document.getElementById("cadastroSenha").value;
    const confirmar = document.getElementById("cadastroConfirmarSenha").value;

    const mensagem = document.getElementById("cadastroMensagem");

    if (usuario === "" || email === "" || senha === "" || confirmar === "") {
      mensagem.innerText = "Preencha todos os campos.";
      mensagem.style.color = "red";
      return;
    }

    if (senha.length < 6) {
      mensagem.innerText = "A senha precisa ter pelo menos 6 caracteres.";
      mensagem.style.color = "red";
      return;
    }

    if (senha !== confirmar) {
      mensagem.innerText = "As senhas não coincidem!";
      mensagem.style.color = "red";
      return;
    }

    fetch("http://localhost:8000/auth/criar_usuario", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        username: usuario,
        email: email,
        senha: senha
      })
    })
      .then(response => {
        if (!response.ok) {
          return response.json().then(err => { throw err });
        }
        return response.json();
      })
      .then(data => {
        mensagem.innerText = "Cadastro realizado com sucesso!";
        mensagem.style.color = "green";

        setTimeout(() => {
          window.location.href = "entrar.html";
        }, 1000);
      })
      .catch(error => {
        console.error(error);
        mensagem.innerText = error.detail || "Erro ao cadastrar.";
        mensagem.style.color = "red";
      });

  });

}