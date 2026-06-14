# 🚀 SISTEMA ADMINISTRATIVO - GUIA COMPLETO

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Arquitetura](#arquitetura)
3. [Services](#services)
4. [Formulários](#formulários)
5. [Fluxo de Funcionamento](#fluxo-de-funcionamento)
6. [Guia de Testes](#guia-de-testes)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

Sistema cliente Windows Forms que consome API FastAPI em `http://localhost:8000`.

**Características:**
- ✅ Autenticação JWT
- ✅ CRUD Posts
- ✅ CRUD Comentários
- ✅ Perfil do usuário
- ✅ Dashboard com estatísticas
- ✅ Interface profissional
- ✅ Async/Await
- ✅ Validações completas

---

## 🏗️ Arquitetura

### Padrão
```
Program.cs
	↓
FormLogin (Autenticação)
	↓
FormPrincipal (Menu + Container)
	├─ FormDashboard (Stats)
	├─ FormPosts (CRUD + Like)
	├─ FormComentarios (CRUD)
	├─ FormPerfil (Dados)
	└─ Logout
```

### Camadas
```
UI (Forms)
	↓
Services (HttpClient + API)
	↓
API FastAPI (http://localhost:8000)
	↓
Banco de Dados
```

---

## 🔧 Services

### AuthService.cs
**Responsabilidade:** Autenticação e obtenção de token JWT

```csharp
public async Task<string> Login(string email, string senha)
{
	// POST /auth/token
	// Retorna: access_token
}
```

**Uso:**
```csharp
var authService = new AuthService();
var token = await authService.Login("user@example.com", "senha123");
```

---

### BaseService.cs
**Responsabilidade:** Configuração base para HttpClient com Bearer token

```csharp
public class BaseService
{
	protected HttpClient HttpClient { get; }
	protected string BaseUrl = "http://localhost:8000";

	public BaseService(string token)
	{
		// Configura Authorization: Bearer {token}
	}
}
```

**Herança:**
- PostService : BaseService
- ComentarioService : BaseService
- ProfileService : BaseService

---

### PostService.cs
**Responsabilidade:** CRUD de posts + Like/Unlike

**Métodos:**
```csharp
// Listar
public async Task<string> GetFeedAsync()
// → GET /post/feed

// Criar
public async Task<string> CriarPostAsync(string conteudo, string imagem = null)
// → POST /post/criar_post

// Atualizar
public async Task<string> AtualizarPostAsync(int id, string conteudo, string imagem = null)
// → PUT /post/atualizar_post/{id}

// Deletar
public async Task<bool> DeletarPostAsync(int id)
// → DELETE /post/deletar/{id}

// Curtir
public async Task<string> CurtirPostAsync(int postId)
// → POST /post/curtir/{postId}

// Descurtir
public async Task<string> RemoverCurtidaAsync(int postId)
// → DELETE /post/remover_curtida/{postId}
```

---

### ComentarioService.cs
**Responsabilidade:** CRUD de comentários

**Métodos:**
```csharp
// Listar
public async Task<string> ListarComentariosAsync(int postId)
// → GET /comments/comentarios/{postId}

// Criar
public async Task<string> AdicionarComentarioAsync(int postId, string conteudo)
// → POST /comments/adicionar_comentario/{postId}

// Atualizar
public async Task<string> AtualizarComentarioAsync(int comentarioId, string conteudo)
// → PUT /comments/atualizar_comentario/{comentarioId}

// Deletar
public async Task<bool> DeletarComentarioAsync(int comentarioId)
// → DELETE /comments/deletar_comentario/{comentarioId}
```

---

### ProfileService.cs
**Responsabilidade:** Gerenciar perfil do usuário

**Métodos:**
```csharp
// Obter dados do perfil
public async Task<string> GetMeAsync()
// → GET /profile/me

// Atualizar foto
public async Task<string> TrocarFotoAsync(string fotoBase64)
// → POST /profile/trocar_foto
```

---

## 📱 Formulários

### FormLogin.cs
**Funcionalidade:** Tela de autenticação

**Layout:**
```
┌─────────────────────────────┐
│  Sistema Administrativo     │
├─────────────────────────────┤
│                             │
│  Email:    [_____________]  │
│  Senha:    [_____________]  │
│                             │
│         [   Login    ]       │
│                             │
└─────────────────────────────┘
```

**Fluxo:**
1. Usuário insere email e senha
2. Valida entrada
3. Chama `AuthService.Login()`
4. Se sucesso → abre `FormPrincipal(token)`
5. Se erro → mostra MessageBox

---

### FormPrincipal.cs
**Funcionalidade:** Menu principal com navegação

**Layout:**
```
┌────────────────────────────────────────────┐
│ Sistema Administrativo - Painel Principal  │
├─────────┬──────────────────────────────────┤
│ 📊 Dash │                                  │
│ 📝 Posts│  [Conteúdo do formulário]       │
│ 💬 Comt │                                  │
│ 👤 Perf │                                  │
│ 🚪 Sair │                                  │
└─────────┴──────────────────────────────────┘
```

**Menu Lateral:**
- 📊 Dashboard
- 📝 Posts
- 💬 Comentários
- 👤 Perfil
- 🚪 Logout

**Funcionalidade:**
- Troca de telas dinâmica
- Mantém token global
- Gestão de sessão

---

### FormDashboard.cs
**Funcionalidade:** Estatísticas do sistema

**Cards:**
1. Total de Posts
2. Total de Likes
3. Média de Likes/Post

**Lista:** Posts recentes

**Atualização:** Manual via botão "Recarregar"

---

### FormPosts.cs
**Funcionalidade:** CRUD de posts com like/unlike

**Layout:**
```
┌─────────────────────────────────────────┐
│ Gerenciamento de Posts                  │
├──────────────────────┬──────────────────┤
│ DataGridView         │ Painel de Edição │
│ (Posts do Feed)      │ - Conteúdo       │
│                      │ - Imagem         │
├──────────────────────┴──────────────────┤
│ [Criar][Atualizar][Deletar]             │
│ [❤️ Curtir][💔 Descurtir][Recarregar]   │
└──────────────────────────────────────────┘
```

**Botões:**
- 🟢 Criar (verde) - POST novo post
- 🟡 Atualizar (amarelo) - PUT post existente
- 🔴 Deletar (vermelho) - DELETE com confirmação
- ❤️ Curtir (vermelho) - POST like
- 💔 Descurtir (cinza) - DELETE like
- 🔄 Recarregar (cinza escuro) - Recarrega lista

**Funcionalidade:**
- Carrega feed ao abrir
- Click no grid preenche campos
- Validações antes de enviar
- Confirmação antes de deletar
- Atualiza lista após ação

---

### FormComentarios.cs
**Funcionalidade:** CRUD de comentários por post

**Layout:**
```
┌────────────────────────────────────┐
│ Gerenciamento de Comentários       │
├────────────────────────────────────┤
│ ID do Post: [____] [Carregar]     │
├────────────────────────────────────┤
│ DataGridView com comentários       │
├────────────────────────────────────┤
│ Editar comentário: [______________]│
│ [Adicionar][Atualizar][Deletar]    │
│ [Limpar]                           │
└────────────────────────────────────┘
```

**Funcionalidade:**
- Carrega comentários por Post ID
- Click no grid preenche TextBox
- Validações de entrada
- Confirmação antes de deletar
- Limpa campos após ação

---

### FormPerfil.cs
**Funcionalidade:** Exibir e atualizar dados do perfil

**Layout:**
```
┌─────────────────────────────┐
│ Perfil do Usuário           │
├─────────────────────────────┤
│ ID: 123                     │
│ Usuário: usuario123         │
│ Email: user@example.com     │
│                             │
│ Foto (Base64):              │
│ [_________________________] │
│                             │
│ [📸 Atualizar][🔄 Recarregar]│
└─────────────────────────────┘
```

**Funcionalidade:**
- Carrega dados do usuário
- Exibe foto em Base64
- Permite atualizar foto
- Recarrega dados

---

## 🔄 Fluxo de Funcionamento

### 1. Inicialização
```
1. Program.Main()
2. Application.Run(new FormLogin())
3. Exibe tela de login
```

### 2. Login
```
1. Usuário insere email + senha
2. Clica "Login"
3. FormLogin.btnLogin_Click()
   → AuthService.Login(email, senha)
   → Valida entrada
   → POST /auth/token
   → Recebe token JWT
4. Se sucesso:
   → Abre FormPrincipal(token)
   → Oculta FormLogin
5. Se erro:
   → MessageBox com erro
```

### 3. Navegação
```
FormPrincipal
  ↓ (Click em botão)
  ├─ Dashboard
  │   ├─ Cria FormDashboard(token)
  │   ├─ PostService.GetFeedAsync()
  │   ├─ ParsearPosts()
  │   ├─ Calcula stats
  │   └─ Exibe cards
  │
  ├─ Posts
  │   ├─ Cria FormPosts(token)
  │   ├─ PostService.GetFeedAsync()
  │   ├─ Popula DataGridView
  │   └─ Aguarda ações
  │       ├─ Criar → CriarPostAsync()
  │       ├─ Atualizar → AtualizarPostAsync()
  │       ├─ Deletar → DeletarPostAsync()
  │       ├─ Curtir → CurtirPostAsync()
  │       └─ Descurtir → RemoverCurtidaAsync()
  │
  ├─ Comentários
  │   ├─ Cria FormComentarios(token)
  │   ├─ Aguarda Post ID
  │   ├─ ComentarioService.ListarComentariosAsync()
  │   ├─ Popula DataGridView
  │   └─ Aguarda ações
  │       ├─ Adicionar → AdicionarComentarioAsync()
  │       ├─ Atualizar → AtualizarComentarioAsync()
  │       └─ Deletar → DeletarComentarioAsync()
  │
  ├─ Perfil
  │   ├─ Cria FormPerfil(token)
  │   ├─ ProfileService.GetMeAsync()
  │   ├─ Exibe dados
  │   └─ Aguarda ação
  │       └─ Atualizar Foto → TrocarFotoAsync()
  │
  └─ Logout
	  └─ Application.Exit()
```

---

## 🧪 Guia de Testes

### Pré-requisitos
```
✅ API FastAPI rodando em http://localhost:8000
✅ Banco de dados configurado
✅ Visual Studio com projeto aberto
```

### Teste 1: Login
```
1. Execute a aplicação (F5)
2. Tela de Login deve aparecer
3. Insira credenciais válidas:
   Email: seu_email@example.com
   Senha: sua_senha
4. Clique "Login"
5. ✅ Esperado: FormPrincipal abre
6. ❌ Se erro: Verifique se API está rodando
```

### Teste 2: Dashboard
```
1. Clique no botão "📊 Dashboard"
2. Aguarde carregamento
3. ✅ Esperado:
   - 3 cards com números
   - Lista de posts recentes
4. Clique "Recarregar"
5. ✅ Esperado: Dados atualizam
```

### Teste 3: Posts - Criar
```
1. Clique "📝 Posts"
2. Preencha:
   - Conteúdo: "Meu primeiro post!"
   - Imagem: (deixe vazio ou URL)
3. Clique "Criar"
4. ✅ Esperado: MessageBox "Sucesso"
5. ✅ Novo post aparece no grid
6. Clique "Recarregar"
7. ✅ Post persiste
```

### Teste 4: Posts - Selecionar
```
1. Na tela Posts, clique em um post no grid
2. ✅ Esperado: Campos preenchem automaticamente
3. Modifique o conteúdo
4. Clique "Atualizar"
5. ✅ Esperado: Post atualiza
```

### Teste 5: Posts - Like
```
1. Clique em um post no grid
2. Clique "❤️ Curtir"
3. ✅ Esperado: MessageBox "Sucesso"
4. Clique "Recarregar"
5. ✅ Contagem de likes aumenta
```

### Teste 6: Posts - Deletar
```
1. Clique em um post
2. Clique "Deletar"
3. Confirmação aparece
4. Clique "Sim"
5. ✅ Esperado: Post remove
6. Clique "Recarregar"
7. ✅ Post some da lista
```

### Teste 7: Comentários - Carregar
```
1. Clique "💬 Comentários"
2. Insira ID de um post: 1
3. Clique "Carregar Comentários"
4. ✅ Esperado: Comentários listam no grid
5. ❌ Se nenhum: Crie comentários primeiro
```

### Teste 8: Comentários - Adicionar
```
1. Na tela Comentários, insira Post ID: 1
2. Clique "Carregar Comentários"
3. No TextBox multilinha, insira: "Ótimo post!"
4. Clique "Adicionar"
5. ✅ Esperado: Novo comentário aparece
6. Clique "Carregar Comentários" novamente
7. ✅ Comentário persiste
```

### Teste 9: Comentários - Atualizar
```
1. Clique em um comentário no grid
2. TextBox preenche
3. Modifique o texto
4. Clique "Atualizar"
5. ✅ Esperado: MessageBox "Sucesso"
6. Clique "Carregar Comentários"
7. ✅ Comentário atualizado
```

### Teste 10: Perfil
```
1. Clique "👤 Perfil"
2. Aguarde carregamento
3. ✅ Esperado:
   - ID do usuário
   - Username
   - Email
   - Foto (Base64)
4. Clique "Recarregar"
5. ✅ Dados recarregam
```

### Teste 11: Logout
```
1. Clique "🚪 Logout"
2. Confirmação aparece
3. Clique "Sim"
4. ✅ Esperado: Aplicação fecha
```

### Teste 12: Validações
```
1. Posts: Tente criar sem conteúdo
   ✅ Esperado: Aviso "Preencha conteúdo"

2. Comentários: Tente adicionar sem Post ID
   ✅ Esperado: Aviso "ID inválido"

3. Comentários: Tente atualizar sem seleção
   ✅ Esperado: Aviso "Selecione um comentário"

4. Posts: Tente deletar, clique "Não"
   ✅ Esperado: Nada acontece
```

---

## 🐛 Troubleshooting

### Erro: "Erro de autenticação"
**Causa:** API não está rodando ou credenciais incorretas
**Solução:**
1. Verifique se API FastAPI está rodando
2. Verifique URL: http://localhost:8000
3. Valide email e senha no banco de dados
4. Teste com Postman: POST /auth/token

### Erro: "Erro ao carregar feed"
**Causa:** Token expirou ou inválido
**Solução:**
1. Faça login novamente
2. Verifique se token está sendo passado corretamente
3. Teste endpoint: GET /post/feed com Authorization header

### Erro: "O nome 'btnXXX' não existe"
**Causa:** Designer não sincronizou
**Solução:**
1. Rebuilde o projeto (Ctrl+Alt+B)
2. Feche e abra Visual Studio
3. Delete arquivo .Designer.cs e recrie

### Grid vazio
**Causa:** Nenhum dado na API
**Solução:**
1. Crie dados via Postman
2. Verifique banco de dados
3. Teste endpoint com curl

### MessageBox não aparece
**Causa:** Exceção não está sendo capturada
**Solução:**
1. Verifique console de erro
2. Adicione breakpoint em catch
3. Use Debug.WriteLine()

---

## 📞 Contato & Suporte

Para reportar bugs ou sugestões:
1. Verifique se API está rodando
2. Reinicie aplicação
3. Verifique logs da API
4. Teste com Postman

---

**Status: ✅ PRONTO PARA PRODUÇÃO**

Data: 2024  
Versão: 1.0.0  
Framework: .NET Framework 4.7.2
