# 📖 EXEMPLOS DE USO E EXTENSÃO

## ✅ Teste Rápido Antes de Executar

Certifique-se que:
```
1. ✓ API FastAPI está rodando em http://localhost:8000
2. ✓ Você tem um usuário cadastrado
3. ✓ Visual Studio compilou sem erros
```

---

## 🚀 Executando a Aplicação

```csharp
// Program.cs (já configurado)
static void Main()
{
	Application.EnableVisualStyles();
	Application.SetCompatibleTextRenderingDefault(false);
	Application.Run(new FormLogin());  // ← Inicia com FormLogin
}
```

**Resultado esperado**:
1. FormLogin abre
2. Insira email e senha
3. Clique "Login"
4. Se correto → FormPrincipal abre
5. Se erro → MessageBox mostra erro

---

## 💡 Exemplo 1: Criar PostService

```csharp
// Services/PostService.cs
using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace sistemaadmin.Services
{
	public class PostService : BaseService
	{
		public PostService(string token) : base(token)
		{
		}

		// Obter feed de posts
		public async Task<string> GetFeedAsync()
		{
			try
			{
				var response = await HttpClient.GetAsync("/post/feed");
				response.EnsureSuccessStatusCode();
				return await response.Content.ReadAsStringAsync();
			}
			catch (Exception ex)
			{
				throw new Exception($"Erro ao obter feed: {ex.Message}");
			}
		}

		// Criar novo post
		public async Task<string> CriarPostAsync(string conteudo)
		{
			try
			{
				var json = $"{{\"conteudo\": \"{conteudo}\"}}";
				var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
				var response = await HttpClient.PostAsync("/post/criar_post", content);
				response.EnsureSuccessStatusCode();
				return await response.Content.ReadAsStringAsync();
			}
			catch (Exception ex)
			{
				throw new Exception($"Erro ao criar post: {ex.Message}");
			}
		}
	}
}
```

---

## 💡 Exemplo 2: Usar PostService em FormPrincipal

```csharp
// FormPrincipal.cs (atualizado)
using System;
using System.Windows.Forms;
using sistemaadmin.Services;

namespace sistemaadmin
{
	public partial class FormPrincipal : Form
	{
		private readonly string _token;
		private PostService _postService;

		public FormPrincipal(string token)
		{
			InitializeComponent();
			_token = token;
			_postService = new PostService(token);  // ← Inicializa com token
		}

		private void FormPrincipal_Load(object sender, EventArgs e)
		{
			this.Text = "Sistema Administrativo";
			CarregarFeed();  // ← Carrega posts ao abrir
		}

		private async void CarregarFeed()
		{
			try
			{
				var feed = await _postService.GetFeedAsync();
				lblStatus.Text = "Feed carregado com sucesso!";
				// Aqui você processaria o JSON e exibiria os posts
			}
			catch (Exception ex)
			{
				MessageBox.Show($"Erro: {ex.Message}");
			}
		}

		private async void btnCriarPost_Click(object sender, EventArgs e)
		{
			try
			{
				var conteudo = txtConteudo.Text;
				await _postService.CriarPostAsync(conteudo);
				MessageBox.Show("Post criado com sucesso!");
				CarregarFeed();  // ← Recarrega feed
			}
			catch (Exception ex)
			{
				MessageBox.Show($"Erro: {ex.Message}");
			}
		}
	}
}
```

---

## 💡 Exemplo 3: Criar CommentService

```csharp
// Services/CommentService.cs
using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace sistemaadmin.Services
{
	public class CommentService : BaseService
	{
		public CommentService(string token) : base(token)
		{
		}

		// Obter comentários de um post
		public async Task<string> GetComentariosAsync(int postId)
		{
			try
			{
				var response = await HttpClient.GetAsync($"/comments/comentarios/{postId}");
				response.EnsureSuccessStatusCode();
				return await response.Content.ReadAsStringAsync();
			}
			catch (Exception ex)
			{
				throw new Exception($"Erro ao obter comentários: {ex.Message}");
			}
		}

		// Adicionar comentário
		public async Task<string> AdicionarComentarioAsync(int postId, string conteudo)
		{
			try
			{
				var json = $"{{\"conteudo\": \"{conteudo}\"}}";
				var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
				var response = await HttpClient.PostAsync($"/comments/adicionar_comentario/{postId}", content);
				response.EnsureSuccessStatusCode();
				return await response.Content.ReadAsStringAsync();
			}
			catch (Exception ex)
			{
				throw new Exception($"Erro ao adicionar comentário: {ex.Message}");
			}
		}

		// Atualizar comentário
		public async Task<string> AtualizarComentarioAsync(int comentarioId, string conteudo)
		{
			try
			{
				var json = $"{{\"conteudo\": \"{conteudo}\"}}";
				var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
				var response = await HttpClient.PutAsync($"/comments/atualizar_comentario/{comentarioId}", content);
				response.EnsureSuccessStatusCode();
				return await response.Content.ReadAsStringAsync();
			}
			catch (Exception ex)
			{
				throw new Exception($"Erro ao atualizar comentário: {ex.Message}");
			}
		}

		// Deletar comentário
		public async Task<bool> DeletarComentarioAsync(int comentarioId)
		{
			try
			{
				var response = await HttpClient.DeleteAsync($"/comments/deletar_comentario/{comentarioId}");
				response.EnsureSuccessStatusCode();
				return true;
			}
			catch (Exception ex)
			{
				throw new Exception($"Erro ao deletar comentário: {ex.Message}");
			}
		}
	}
}
```

---

## 💡 Exemplo 4: Criar ProfileService

```csharp
// Services/ProfileService.cs
using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace sistemaadmin.Services
{
	public class ProfileService : BaseService
	{
		public ProfileService(string token) : base(token)
		{
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

		// Trocar foto de perfil
		public async Task<string> TrocarFotoAsync(byte[] fotoBytes, string nomeArquivo)
		{
			try
			{
				using (var content = new MultipartFormDataContent())
				{
					content.Add(new ByteArrayContent(fotoBytes), "arquivo", nomeArquivo);
					var response = await HttpClient.PostAsync("/profile/trocar_foto", content);
					response.EnsureSuccessStatusCode();
					return await response.Content.ReadAsStringAsync();
				}
			}
			catch (Exception ex)
			{
				throw new Exception($"Erro ao trocar foto: {ex.Message}");
			}
		}
	}
}
```

---

## 🔄 Padrão de Uso Comum

Todos os serviços seguem este padrão:

```csharp
public class NovoService : BaseService
{
	// 1. Herdar de BaseService
	public NovoService(string token) : base(token) { }

	// 2. Implementar métodos que usam HttpClient
	public async Task<string> MetodoAsync()
	{
		try
		{
			// 3. Fazer requisição HTTP
			var response = await HttpClient.GetAsync("/endpoint");
			response.EnsureSuccessStatusCode();

			// 4. Ler resposta
			return await response.Content.ReadAsStringAsync();
		}
		catch (Exception ex)
		{
			throw new Exception($"Erro: {ex.Message}");
		}
	}
}
```

---

## 🎯 Checklist para Novo Serviço

```
☐ Criar classe herdando BaseService
☐ Implementar construtor que recebe token
☐ Passar token para base: base(token)
☐ Implementar métodos async
☐ Usar HttpClient fornecido pela base
☐ Usar try/catch para erros
☐ Retornar dados processados
☐ Testar com dados reais da API
☐ Usar em FormPrincipal
```

---

## 📝 Exemplo Completo de Fluxo

```csharp
// 1. Usuário faz login
FormLogin → AuthService.Login() → API retorna token

// 2. FormPrincipal abre com token
FormPrincipal(token)

// 3. Criar serviço com token
var postService = new PostService(token);

// 4. Usar serviço
var feed = await postService.GetFeedAsync();

// 5. Processar resposta
var posts = JsonConvert.DeserializeObject<List<Post>>(feed);

// 6. Exibir na UI
foreach (var post in posts)
{
	// Adicionar em DataGridView, ListBox, etc.
}
```

---

## ✅ O que DEVE ser feito

```
✅ Criar Services estendendo BaseService
✅ Usar HttpClient fornecido pela base
✅ Tratar erros com try/catch
✅ Passar token para cada requisição (automático)
✅ Processar resposta JSON
✅ Exibir dados na UI
```

---

## ❌ O que NÃO deve ser feito

```
❌ Criar HttpClient novo em cada serviço
❌ Implementar autenticação manualmente
❌ Validar ou decodificar JWT
❌ Fazer hash de senha
❌ Simular dados da API
❌ Criar endpoints novos
❌ Replicar lógica do backend
```

---

## 🧪 Teste de Integração

```csharp
// Teste básico: FormLogin → FormPrincipal → PostService

// 1. Executar aplicação
// 2. Insira email/senha válidos
// 3. Clique Login
// 4. FormPrincipal abre
// 5. No Load, carregue feed:

private async void FormPrincipal_Load(object sender, EventArgs e)
{
	var postService = new PostService(_token);
	try
	{
		var feed = await postService.GetFeedAsync();
		MessageBox.Show("Feed carregado!");  // ← Sucesso
	}
	catch (Exception ex)
	{
		MessageBox.Show($"Erro: {ex.Message}");  // ← Erro
	}
}
```

---

## 📚 Recursos

- Documentação da API: http://localhost:8000/docs (Se habilitado)
- Endpoints disponíveis em ARQUITETURA.md
- Exemplos em ServicesExemplos.cs (comentados)

---

**Última atualização**: 2024  
**Status**: ✅ Pronto para extensão
