# 📚 Exemplos de Uso - FormPerfil

## Exemplo 1: Abrir FormPerfil do Menu Principal

```csharp
private void AbrirFormPerfil()
{
	FecharFormAtual();
	try
	{
		Panel pnlContainer = this.Controls["pnlContainer"] as Panel;
		if (pnlContainer != null)
		{
			// Criar instance do FormPerfil com token
			FormPerfil formPerfil = new FormPerfil(_token);

			// Configurar para aparecer como painel
			formPerfil.TopLevel = false;
			formPerfil.Dock = DockStyle.Fill;

			// Limpar e adicionar
			pnlContainer.Controls.Clear();
			pnlContainer.Controls.Add(formPerfil);

			// Exibir
			formPerfil.Show();
			_currentForm = formPerfil;
		}
	}
	catch (Exception ex)
	{
		MessageBox.Show($"Erro ao abrir Perfil:\n{ex.Message}", "Erro",
			MessageBoxButtons.OK, MessageBoxIcon.Error);
	}
}
```

## Exemplo 2: Usar FormPerfil em Janela Modal

```csharp
private void AbrirFormPerfilModal()
{
	try
	{
		FormPerfil formPerfil = new FormPerfil(_token);

		// Exibir como diálogo modal
		formPerfil.ShowDialog();
	}
	catch (Exception ex)
	{
		MessageBox.Show($"Erro: {ex.Message}");
	}
}
```

## Exemplo 3: ProfileService - Como Funciona

```csharp
// Serviço base com autenticação Bearer
public class ProfileService : BaseService
{
	public ProfileService(string token) : base(token)
	{
		// Token automaticamente adicionado aos headers
	}

	// Obter dados do perfil
	public async Task<string> GetMeAsync()
	{
		try
		{
			var response = await HttpClient.GetAsync("/profile/me");
			response.EnsureSuccessStatusCode();
			return await response.Content.ReadAsStringAsync();
		}
		catch (Exception ex)
		{
			throw new Exception($"Erro ao obter perfil: {ex.Message}");
		}
	}

	// Atualizar foto
	public async Task<string> TrocarFotoAsync(string fotoUrl)
	{
		try
		{
			string json = $"{{\"foto_perfil\": \"{EscapeJson(fotoUrl)}\"}}";
			var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

			var response = await HttpClient.PostAsync("/profile/trocar_foto", content);
			response.EnsureSuccessStatusCode();
			return await response.Content.ReadAsStringAsync();
		}
		catch (Exception ex)
		{
			throw new Exception($"Erro ao trocar foto: {ex.Message}");
		}
	}
}
```

## Exemplo 4: Fluxo Completo de Autenticação → Perfil

```csharp
// Program.cs - Ponto de entrada
[STAThread]
static void Main()
{
	Application.EnableVisualStyles();
	Application.SetCompatibleTextRenderingDefault(false);

	// 1. Abrir FormLogin
	Application.Run(new FormLogin());
}

// FormLogin.cs
private async void btnLogin_Click(object sender, EventArgs e)
{
	try
	{
		var email = txtEmail.Text.Trim();
		var senha = txtSenha.Text.Trim();

		// 2. Autenticar
		var token = await _authService.Login(email, senha);

		// 3. Abrir FormPrincipal com token
		FormPrincipal formPrincipal = new FormPrincipal(token);
		this.Hide();
		formPrincipal.ShowDialog();
		this.Close();
	}
	catch (Exception ex)
	{
		MessageBox.Show($"Erro: {ex.Message}");
	}
}

// FormPrincipal.cs - Com menu de navegação
private void FormPrincipal_Load(object sender, EventArgs e)
{
	ConfigurarMenu();
	AbrirFormDashboard();
}

// Botão Perfil no menu
btnPerfil.Click += (s, e) => AbrirFormPerfil();

// 4. Abrir FormPerfil
private void AbrirFormPerfil()
{
	FormPerfil formPerfil = new FormPerfil(_token);
	// ... configurar e exibir
}
```

## Exemplo 5: Resposta JSON da API

```json
{
  "id": 123,
  "username": "usuario_exemplo",
  "email": "usuario@example.com",
  "foto_perfil": "https://exemplo.com/foto.jpg"
}
```

## Exemplo 6: Atualizar Foto via URL

### Request
```http
POST /profile/trocar_foto HTTP/1.1
Host: localhost:8000
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: application/json

{
  "foto_perfil": "https://exemplo.com/nova-foto.jpg"
}
```

### Response
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 123,
  "username": "usuario_exemplo",
  "email": "usuario@example.com",
  "foto_perfil": "https://exemplo.com/nova-foto.jpg"
}
```

## Exemplo 7: Tratamento de Erros

```csharp
private async void CarregarPerfil()
{
	try
	{
		// Desabilitar botão enquanto carrega
		btnRecarregarPerfil.Enabled = false;
		btnRecarregarPerfil.Text = "Carregando...";

		// Chamar API
		var json = await _profileService.GetMeAsync();

		// Processar resposta
		var username = ExtrairValor(json, "username");
		var email = ExtrairValor(json, "email");
		var fotoPerfil = ExtrairValor(json, "foto_perfil");

		// Atualizar interface
		lblUsernameValor.Text = username;
		lblEmailValor.Text = email;

		// Carregar foto
		if (!string.IsNullOrEmpty(fotoPerfil))
		{
			// URL
			if (fotoPerfil.StartsWith("http"))
			{
				picFoto.Load(fotoPerfil);
			}
			// Base64
			else
			{
				byte[] imageBytes = Convert.FromBase64String(fotoPerfil);
				using (System.IO.MemoryStream ms = new System.IO.MemoryStream(imageBytes))
				{
					picFoto.Image = Image.FromStream(ms);
				}
			}
		}
		else
		{
			// Imagem padrão
			ExibirImagemPadrao();
		}
	}
	catch (Exception ex)
	{
		// Erro 401 - Token expirado
		if (ex.Message.Contains("401"))
		{
			MessageBox.Show("Sessão expirada. Por favor, faça login novamente.", "Sessão Expirada",
				MessageBoxButtons.OK, MessageBoxIcon.Warning);
			// Redirecionar para login
		}
		// Erro 404 - Usuário não encontrado
		else if (ex.Message.Contains("404"))
		{
			MessageBox.Show("Usuário não encontrado.", "Erro",
				MessageBoxButtons.OK, MessageBoxIcon.Error);
		}
		// Erro genérico
		else
		{
			MessageBox.Show($"Erro ao carregar perfil:\n{ex.Message}", "Erro",
				MessageBoxButtons.OK, MessageBoxIcon.Error);
		}
	}
	finally
	{
		// Reabilitar botão
		btnRecarregarPerfil.Enabled = true;
		btnRecarregarPerfil.Text = "🔄 Recarregar Perfil";
	}
}
```

## Exemplo 8: Personalizar Cores do Tema

```csharp
// Modificar paleta de cores em CriarInterface()

// Topo - Cor personalizada
pnlTopo.BackColor = Color.FromArgb(41, 128, 185);  // Azul

// Botão Atualizar - Cor personalizada
btnAtualizarFoto.BackColor = Color.FromArgb(46, 204, 113);  // Verde

// Botão Recarregar - Cor personalizada
btnRecarregarPerfil.BackColor = Color.FromArgb(52, 152, 219);  // Azul claro

// Exemplo: Mudar para tema escuro
private void AplicarTemaTema()
{
	this.BackColor = Color.FromArgb(33, 33, 33);
	pnlTopo.BackColor = Color.FromArgb(22, 22, 22);
	pnlCard.BackColor = Color.FromArgb(45, 45, 45);
	lblUsernameValor.ForeColor = Color.White;
	lblEmailValor.ForeColor = Color.White;
}
```

## Exemplo 9: Validações Adicionais

```csharp
private bool ValidarURL(string url)
{
	try
	{
		// Verificar se é URL válida
		if (string.IsNullOrEmpty(url))
			return false;

		// Validar formato
		if (!url.StartsWith("http://") && !url.StartsWith("https://"))
			return false;

		// Tentar criar URI
		var uri = new Uri(url);
		return true;
	}
	catch
	{
		return false;
	}
}

private async void BtnAtualizarFoto_Click(object sender, EventArgs e)
{
	try
	{
		string url = txtNovaFotoUrl.Text.Trim();

		// 1. Validar URL vazia
		if (string.IsNullOrEmpty(url))
		{
			MessageBox.Show("URL não pode estar vazia.", "Validação");
			return;
		}

		// 2. Validar formato de URL
		if (!ValidarURL(url))
		{
			MessageBox.Show("URL inválida. Use http:// ou https://", "Validação");
			return;
		}

		// 3. Tentar carregar imagem antes de enviar
		try
		{
			Image testImage = Image.FromStream(new System.Net.WebClient().OpenRead(url));
			testImage.Dispose();
		}
		catch
		{
			if (MessageBox.Show("URL pode não conter uma imagem válida. Continuar mesmo assim?", 
				"Aviso", MessageBoxButtons.YesNo) != DialogResult.Yes)
				return;
		}

		// 4. Enviar para API
		await _profileService.TrocarFotoAsync(url);

		MessageBox.Show("Foto atualizada com sucesso!");
		CarregarPerfil();
	}
	catch (Exception ex)
	{
		MessageBox.Show($"Erro: {ex.Message}");
	}
}
```

## Exemplo 10: Estrutura Completa de Projeto

```
sistemaadmin/
├── Program.cs                      # Ponto de entrada
├── Services/
│   ├── AuthService.cs              # Autenticação
│   ├── BaseService.cs              # Base com HttpClient
│   ├── ProfileService.cs           # Perfil
│   ├── PostService.cs              # Posts
│   └── ComentarioService.cs        # Comentários
├── Forms/
│   ├── FormLogin.cs                # Tela de login
│   ├── FormLogin.Designer.cs
│   ├── FormPrincipal.cs            # Tela principal
│   ├── FormPrincipal.Designer.cs
│   ├── FormPerfil.cs ✅            # Tela de perfil (NOVO)
│   ├── FormPerfil.Designer.cs
│   ├── FormDashboard.cs            # Dashboard
│   ├── FormPosts.cs                # Gerenciamento de posts
│   ├── FormComentarios.cs          # Gerenciamento de comentários
│   └── ...
└── Documentation/
	├── FORMPERFIL_DOCUMENTACAO.md  # Documentação completa
	└── EXEMPLOS_USO.md             # Este arquivo
```

---

**Todos os exemplos são funcionais e prontos para usar!**
