# Sistema Administrativo - Cliente Windows Forms

## 📋 Descrição

Cliente Windows Forms para o sistema administrativo que consome a API FastAPI existente em `http://localhost:8000`.

## 🏗️ Estrutura do Projeto

```
sistemaadmin/
├── Services/
│   ├── AuthService.cs      # Serviço de autenticação (Login)
│   └── BaseService.cs      # Classe base com HttpClient configurado
├── FormLogin.cs            # Tela de login
├── FormLogin.Designer.cs   # Design da tela de login
├── FormPrincipal.cs        # Tela principal do sistema
├── FormPrincipal.Designer.cs # Design da tela principal
├── Program.cs              # Ponto de entrada da aplicação
└── [Arquivos padrão do projeto]
```

## 🚀 Como Usar

### Pré-requisitos

- .NET Framework 4.7.2
- API FastAPI rodando em `http://localhost:8000`

### Funcionamento

1. **Iniciar a Aplicação**
   - A aplicação inicia com a `FormLogin`
   - Insira email e senha registrados na API

2. **Autenticação**
   - `AuthService` envia credenciais para `POST /auth/token`
   - Recebe um token JWT em troca
   - Token é validado e armazenado

3. **Acesso ao Sistema**
   - Após login bem-sucedido, abre `FormPrincipal`
   - Token é passado para a tela principal
   - Indica que está conectado à API ✓

### Fluxo de Autenticação

```
FormLogin (email/senha)
	↓
AuthService.LoginAsync()
	↓
POST /auth/token (FormUrlEncodedContent)
	↓
Recebe: { "access_token": "...", "token_type": "bearer" }
	↓
Extrai token e retorna
	↓
FormPrincipal (com token)
```

## 🔑 Componentes

### AuthService
- `LoginAsync(email, senha)` - Realiza autenticação e retorna token JWT
- Trata erros de conexão e autenticação
- Extrai token da resposta JSON da API

### BaseService
- Classe base para outros serviços
- Configura `HttpClient` com:
  - `BaseAddress`: `http://localhost:8000`
  - `Authorization Header`: `Bearer {token}`

### FormLogin
- Campos: Email e Senha
- Validação de campos obrigatórios
- Exibe mensagens de erro em caso de falha
- Feedback visual durante a conexão

### FormPrincipal
- Recebe token do login
- Exibe status de conexão
- Botão para sair da aplicação

## ⚙️ Configuração

### URL da API
Alterar em `AuthService` e `BaseService`:
```csharp
private readonly string _baseUrl = "http://localhost:8000";
```

### Tratamento de Erros
- Login inválido: Mensagem descritiva
- Conexão falha: Mensagem de erro da API
- Campo vazio: Validação na interface

## 📝 Notas Importantes

✅ Consume API existente (sem mockups)  
✅ Usa async/await para operações assíncronas  
✅ Trata erros com try/catch  
✅ Código organizado em Services  
✅ Autenticação Bearer com JWT  
✅ Pronto para extensão com mais endpoints  

## 🔐 Segurança

- Token armazenado em memória
- Senha mascarada no formulário
- Validação de campos obrigatórios
- Headers de autenticação automáticos

## 📦 Próximas Etapas

Para adicionar novas funcionalidades:

1. Criar novo Service estendendo `BaseService`:
```csharp
public class PostService : BaseService
{
	public PostService(string token) : base(token) { }

	public async Task<List<Post>> GetFeedAsync()
	{
		var response = await HttpClient.GetAsync("/post/feed");
		// processar resposta
	}
}
```

2. Usar o serviço na interface:
```csharp
var postService = new PostService(token);
var posts = await postService.GetFeedAsync();
```

---

**Status**: ✅ Base implementada com autenticação funcional
