# 🏗️ ARQUITETURA DO SISTEMA

## Diagrama de Fluxo

```
┌─────────────────────────────────────────────────────────────────┐
│                     APLICAÇÃO WINDOWS FORMS                      │
└─────────────────────────────────────────────────────────────────┘
								│
					┌───────────┴───────────┐
					│                       │
			┌───────▼────────┐    ┌────────▼────────┐
			│   FormLogin    │    │ FormPrincipal   │
			│                │    │                 │
			│ • Email        │    │ • Token         │
			│ • Senha        │    │ • Status        │
			│ • Botão Login  │    │ • Botão Sair    │
			└───────┬────────┘    └────────┬────────┘
					│                      │
					│ (armazena token)     │
					│                      │
					└──────────┬───────────┘
							  │
					┌─────────▼──────────┐
					│  AuthService       │
					│                    │
					│ • Login(e, s)      │
					│ • POST /auth/token │
					│ • Extrai token     │
					└─────────┬──────────┘
							  │
					┌─────────▼──────────┐
					│   BaseService      │
					│                    │
					│ • HttpClient       │
					│ • Bearer token     │
					│ • BaseAddress      │
					└─────────┬──────────┘
							  │
							  │ HTTP
							  │ Content-Type: 
							  │ application/x-www-form-urlencoded
							  │
					┌─────────▼──────────┐
					│   API FastAPI      │
					│                    │
					│ POST /auth/token   │
					│                    │
					│ Valida credenciais │
					│ Retorna JWT        │
					└────────────────────┘
```

---

## Estrutura de Camadas

```
┌──────────────────────────────────────────┐
│         CAMADA DE APRESENTAÇÃO           │
│  (Windows Forms - Interfaces com usuário)│
│                                          │
│  • FormLogin - Tela de login             │
│  • FormPrincipal - Painel principal      │
└──────────────┬───────────────────────────┘
			   │
┌──────────────▼───────────────────────────┐
│         CAMADA DE SERVIÇOS               │
│  (Cliente HTTP - Consumo de API)         │
│                                          │
│  • AuthService - Login                   │
│  • BaseService - Base com Bearer token   │
└──────────────┬───────────────────────────┘
			   │
┌──────────────▼───────────────────────────┐
│      CAMADA DE TRANSPORTE (HTTP)         │
│                                          │
│  • HttpClient com Bearer Authorization   │
│  • BaseAddress: http://localhost:8000    │
└──────────────┬───────────────────────────┘
			   │
┌──────────────▼───────────────────────────┐
│         API FASTAPI (Backend)            │
│                                          │
│  • POST /auth/token - Autenticação       │
│  • GET /profile/me - Perfil              │
│  • POST /post/criar_post - Posts         │
│  • [Mais endpoints...]                   │
└──────────────────────────────────────────┘
```

---

## Fluxo de Autenticação Detalhado

```
1. INICIALIZAÇÃO
   └─> Program.Main()
	   └─> Abre FormLogin

2. FORMULÁRIO DE LOGIN
   ┌─────────────────────────────────┐
   │ FormLogin aparece               │
   │ • txtEmail (vazio)              │
   │ • txtSenha (vazio)              │
   │ • btnLogin (ativo)              │
   └─────────────────────────────────┘

3. USUÁRIO PREENCHE DADOS
   ┌─────────────────────────────────┐
   │ Email: usuario@email.com        │
   │ Senha: ••••••••••               │
   └─────────────────────────────────┘

4. USUÁRIO CLICA "LOGIN"
   └─> btnLogin_Click()
	   └─> btnLogin.Enabled = false
	   └─> btnLogin.Text = "Conectando..."

5. AUTHSERVICE.LOGIN() É CHAMADO
   ┌─────────────────────────────────┐
   │ Prepara formulário:             │
   │ • username = usuario@email.com  │
   │ • password = (da entrada)       │
   │                                 │
   │ Content-Type:                   │
   │ application/x-www-form-urlencoded
   └─────────────────────────────────┘

6. REQUISIÇÃO HTTP É ENVIADA
   ┌─────────────────────────────────┐
   │ POST http://localhost:8000/auth/token
   │                                 │
   │ Headers:                        │
   │ Content-Type: application/      │
   │   x-www-form-urlencoded        │
   │                                 │
   │ Body:                           │
   │ username=usuario@email.com&     │
   │ password=...                    │
   └─────────────────────────────────┘

7. API PROCESSA
   ┌─────────────────────────────────┐
   │ ✅ SE CREDENCIAIS CORRETAS:     │
   │                                 │
   │ Retorna (200 OK):               │
   │ {                               │
   │   "access_token": "eyJ0...",   │
   │   "token_type": "bearer"        │
   │ }                               │
   │                                 │
   │ ❌ SE CREDENCIAIS ERRADAS:      │
   │                                 │
   │ Retorna (401 Unauthorized):     │
   │ {...erro...}                    │
   └─────────────────────────────────┘

8. AUTHSERVICE PROCESSA RESPOSTA
   ┌─────────────────────────────────┐
   │ if (response.IsSuccessStatusCode)│
   │   Extrai access_token           │
   │   Retorna token para FormLogin   │
   │ else                             │
   │   Lança Exception                │
   └─────────────────────────────────┘

9. FORMLOGIN RECEBE TOKEN
   ┌─────────────────────────────────┐
   │ ✅ SE TOKEN RECEBIDO:           │
   │   • Cria FormPrincipal(token)   │
   │   • Esconde FormLogin           │
   │   • Abre FormPrincipal          │
   │                                 │
   │ ❌ SE ERRO:                     │
   │   • Mostra MessageBox           │
   │   • Reabilita btnLogin          │
   │   • Permanece em FormLogin      │
   └─────────────────────────────────┘

10. FORMPRINCIPAL ABRE
	┌─────────────────────────────────┐
	│ FormPrincipal recebe token      │
	│                                 │
	│ Status:                         │
	│ "Sistema administrativo         │
	│  conectado à API ✓"             │
	│                                 │
	│ Token disponível para:          │
	│ • BaseService                   │
	│ • Outros serviços               │
	└─────────────────────────────────┘
```

---

## Classes e Responsabilidades

### AuthService
```
Responsabilidade:
  • Consumir endpoint /auth/token
  • Enviar credenciais de forma correta
  • Extrair token da resposta
  • Lançar exceção em caso de erro

Entrada:
  • email (string)
  • senha (string)

Saída:
  • token (string)

Não faz:
  • Validação de email/senha
  • Hash de senha
  • Geração de token
  • Persistência de dados
```

### BaseService
```
Responsabilidade:
  • Configurar HttpClient
  • Adicionar header Authorization com token
  • Servir como base para outros serviços

Construtor:
  • Recebe token (string)

Fornece:
  • HttpClient configurado
  • BaseAddress definida
  • Authorization header configurado

Não faz:
  • Chamadas HTTP diretas
  • Lógica de autenticação
```

### FormLogin
```
Responsabilidade:
  • Coletar email e senha do usuário
  • Chamar AuthService para autenticar
  • Abrir FormPrincipal se sucesso
  • Mostrar erro se falha

Não faz:
  • Validação de credenciais
  • Hash de senha
  • Lógica de autenticação
```

### FormPrincipal
```
Responsabilidade:
  • Exibir painel principal
  • Manter token armazenado
  • Base para implementar funcionalidades

Não faz:
  • Nenhuma funcionalidade ainda
  • Acesso a API (sem BaseService estendido)
```

---

## Fluxo de Dados

```
FormLogin
	↓
	txtEmail.Text = "usuario@email.com"
	txtSenha.Text = "senha123"
	↓
AuthService.Login(email, senha)
	↓
	FormUrlEncodedContent {
		"username": "usuario@email.com",
		"password": "senha123"
	}
	↓
	POST /auth/token
	↓
	Resposta JSON: {"access_token": "...", "token_type": "bearer"}
	↓
	Extrai token
	↓
FormLogin recebe token
	↓
	FormPrincipal(token) criado
	↓
FormPrincipal
	↓
	_token = "JWT..."
	↓
	Disponível para BaseService
```

---

## Segurança

```
┌─────────────────────────────────────┐
│  CAMADA DE SEGURANÇA                │
│                                     │
│  1. HTTPS (conforme API requer)    │
│     • Criptografa transmissão       │
│     • Protege token em trânsito     │
│                                     │
│  2. Bearer Token                    │
│     • Authorization: Bearer {token} │
│     • Token em header (não em URL)  │
│                                     │
│  3. Armazenamento em Memória        │
│     • Token não persiste no disco   │
│     • Não está em arquivo/BD        │
│                                     │
│  4. Sem Lógica Sensível             │
│     • Nenhuma criptografia manual   │
│     • Nenhum hash de senha          │
│     • Nenhuma validação de JWT      │
│                                     │
│  5. Responsabilidade da API         │
│     • API valida credenciais        │
│     • API gera token                │
│     • API assina JWT                │
└─────────────────────────────────────┘
```

---

## Extensão Futura

```
Estrutura para adicionar novos serviços:

1. Criar novo Service estendendo BaseService
   public class PostService : BaseService { }

2. Implementar métodos que usam HttpClient
   public async Task GetFeedAsync() { }

3. Usar em FormPrincipal
   var postService = new PostService(token);
   var posts = await postService.GetFeedAsync();

Endpoints disponíveis:
  • GET /profile/me
  • POST /profile/trocar_foto
  • POST /post/criar_post
  • GET /post/feed
  • PUT /post/atualizar_post/{id}
  • DELETE /post/deletar/{id}
  • POST /comments/adicionar_comentario/{post_id}
  • PUT /comments/atualizar_comentario/{comentario_id}
  • DELETE /comments/deletar_comentario/{comentario_id}
  • GET /comments/comentarios/{post_id}
```

---

**Diagrama atualizado**: 2024  
**Status**: ✅ Arquitetura validada
