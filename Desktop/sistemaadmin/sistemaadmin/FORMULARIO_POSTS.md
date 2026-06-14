# 📝 FORMULÁRIO DE GERENCIAMENTO DE POSTS

## ✅ Implementado

Um formulário moderno e funcional para gerenciar posts consumindo a API FastAPI.

---

## 🎨 LAYOUT

```
┌─────────────────────────────────────────────────────┐
│         TOPO (Azul - #2980B9)                       │
│  📄 Gerenciamento de Posts                          │
└─────────────────────────────────────────────────────┘

┌──────────────────────────────────┬──────────────────┐
│                                  │                  │
│  CENTRO (DataGridView)           │ LADO DIREITO     │
│                                  │ (Panel Cinza)    │
│  [ID | Conteúdo | Imagem]        │                  │
│  ┌─────────────────────────────┐ │ Conteúdo:        │
│  │                             │ │ [TextBox         │
│  │                             │ │  Multilinha]     │
│  │                             │ │                  │
│  │                             │ │ URL da Imagem:   │
│  │                             │ │ [TextBox]        │
│  └─────────────────────────────┘ │                  │
│                                  │                  │
└──────────────────────────────────┴──────────────────┘

┌──────────────────────────────────────────────────────┐
│ RODAPÉ (Branco)                                      │
│ [Criar] [Atualizar] [Deletar] [Recarregar]          │
│  Verde   Amarelo    Vermelho  Cinza                  │
└──────────────────────────────────────────────────────┘
```

---

## 🎯 FUNCIONALIDADES

### ✅ Carregar Posts
```
FormPosts_Load()
  ├─> Cria PostService(token)
  └─> Chama CarregarPosts()
	  ├─> GetFeedAsync()
	  ├─> Parseia JSON
	  └─> Popula DataGridView
```

### ✅ Selecionar Post
```
dgvPosts_SelectionChanged()
  └─> Preenche TextBoxes com dados do post
```

### ✅ Criar Post
```
btnCriar_Click()
  ├─> Valida conteúdo
  ├─> Chama CriarPostAsync()
  ├─> Mostra sucesso/erro
  └─> Recarrega lista
```

### ✅ Atualizar Post
```
btnAtualizar_Click()
  ├─> Verifica seleção
  ├─> Valida conteúdo
  ├─> Chama AtualizarPostAsync()
  ├─> Mostra sucesso/erro
  └─> Recarrega lista
```

### ✅ Deletar Post
```
btnDeletar_Click()
  ├─> Verifica seleção
  ├─> Pede confirmação
  ├─> Chama DeletarPostAsync()
  ├─> Mostra sucesso/erro
  └─> Recarrega lista
```

### ✅ Recarregar
```
btnRecarregar_Click()
  ├─> Limpa campos
  └─> Chama CarregarPosts()
```

---

## 🎨 CORES

```
TOPO:              Azul (#2980B9)
PAINEL EDIÇÃO:     Cinza claro (#ECF0F1)
RODAPÉ:            Branco
FUNDO:             Branco

BOTÕES:
  Criar:      Verde (#2ECC71)
  Atualizar:  Amarelo (#F1C40F)
  Deletar:    Vermelho (#E74C3C)
  Recarregar: Cinza escuro (#344B5E)
```

---

## 📊 DATOSOURCE

### PostItem (Classe Interna)
```csharp
public class PostItem
{
	public int id { get; set; }
	public string conteudo { get; set; }
	public string imagem { get; set; }
}
```

### Parsing JSON
```
JSON resposta: [{"id": 1, "conteudo": "...", "imagem": "..."}, ...]
	   ↓
Regex extraction (id, conteudo, imagem)
	   ↓
List<PostItem>
	   ↓
dgvPosts.DataSource = posts
```

---

## 🔌 Integração com PostService

### PostService.cs
```csharp
public class PostService : BaseService
{
	public async Task<string> GetFeedAsync()
	public async Task<string> CriarPostAsync(string conteudo, string imagem)
	public async Task<string> AtualizarPostAsync(int id, string conteudo, string imagem)
	public async Task<bool> DeletarPostAsync(int id)
}
```

### Utilizado em FormPosts
```csharp
_postService = new PostService(_token);
var json = await _postService.GetFeedAsync();
var posts = ParsearPosts(json);
```

---

## 🎮 UX/Responsividade

### Anchoring
```
DataGridView:      Fill
TextBoxes:         Left/Top/Right/Bottom
Botões:            Left/Bottom
Panels:            Dock
```

### AutoSizeColumns
```csharp
dgvPosts.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
```

### Seleção
```csharp
SelectionMode = FullRowSelect
MultiSelect = false
ReadOnly = true
```

---

## 🛡️ Validações

```
✅ Verificar seleção antes de atualizar/deletar
✅ Validar conteúdo não vazio
✅ Pedir confirmação antes de deletar
✅ Mostrar erro em MessageBox
✅ Limpar campos após operação
```

---

## ⚙️ Tratamento de Erros

```
try/catch em:
  ├─> CarregarPosts()        (GetFeedAsync)
  ├─> btnCriar_Click()       (CriarPostAsync)
  ├─> btnAtualizar_Click()   (AtualizarPostAsync)
  └─> btnDeletar_Click()     (DeletarPostAsync)

Todos exibem MessageBox com erro
```

---

## 📋 Métodos Principais

### CarregarPosts()
```csharp
private async void CarregarPosts()
{
	// Obtém JSON via API
	var json = await _postService.GetFeedAsync();

	// Parseia para List<PostItem>
	_posts = ParsearPosts(json);

	// Popula DataGridView
	dgvPosts.DataSource = null;
	dgvPosts.DataSource = _posts;
}
```

### ParsearPosts(string json)
```csharp
private List<PostItem> ParsearPosts(string json)
{
	// Usa Regex para extrair dados
	// Desescapa JSON (\n, \r, \t, \", \\)
	// Retorna List<PostItem>
}
```

### dgvPosts_SelectionChanged()
```csharp
private void dgvPosts_SelectionChanged(object sender, EventArgs e)
{
	if (dgvPosts.SelectedRows.Count > 0)
	{
		PostItem post = (PostItem)dgvPosts.SelectedRows[0].DataBoundItem;
		txtConteudo.Text = post.conteudo;
		txtImagem.Text = post.imagem;
	}
}
```

---

## 🔄 Fluxo de Operação

### Criar Post
```
1. Usuário insere conteúdo e imagem
2. Clica "Criar"
3. Valida conteúdo
4. Chama PostService.CriarPostAsync()
5. API retorna sucesso/erro
6. Mostra MessageBox
7. Limpa campos
8. Recarrega lista
```

### Atualizar Post
```
1. Usuário seleciona linha no DataGridView
2. TextBoxes preenchem com dados
3. Usuário edita conteúdo/imagem
4. Clica "Atualizar"
5. Valida conteúdo
6. Chama PostService.AtualizarPostAsync(id, ...)
7. API retorna sucesso/erro
8. Mostra MessageBox
9. Limpa campos
10. Recarrega lista
```

### Deletar Post
```
1. Usuário seleciona linha no DataGridView
2. Clica "Deletar"
3. Pede confirmação
4. Se sim, chama PostService.DeletarPostAsync(id)
5. API retorna sucesso/erro
6. Mostra MessageBox
7. Limpa campos
8. Recarrega lista
```

---

## 📊 Propriedades do DataGridView

```
AutoSizeColumnsMode = Fill
SelectionMode = FullRowSelect
MultiSelect = false
AllowUserToAddRows = false
AllowUserToDeleteRows = false
AllowUserToResizeColumns = true
ReadOnly = true
BackgroundColor = White
```

---

## 🎯 Como Usar

### 1. Executar Aplicação
```
FormLogin → Login → FormPrincipal → FormPosts (abre automaticamente)
```

### 2. Criar Post
```
- Digite conteúdo em "Conteúdo"
- Digite URL em "URL da Imagem" (opcional)
- Clique "Criar"
- Confirme sucesso
```

### 3. Atualizar Post
```
- Clique em linha no DataGridView
- Edite campos
- Clique "Atualizar"
- Confirme sucesso
```

### 4. Deletar Post
```
- Clique em linha no DataGridView
- Clique "Deletar"
- Confirme ação
- Confirme sucesso
```

### 5. Recarregar
```
- Clique "Recarregar"
- Lista é atualizada
```

---

## ✨ Recursos

```
✅ Interface moderna
✅ Cores profissionais
✅ DataGridView funcional
✅ Edição de posts
✅ Criação de posts
✅ Deleção com confirmação
✅ Async/Await
✅ Try/Catch
✅ Validação de dados
✅ MessageBox feedback
✅ Limpar campos
✅ Responsivo
```

---

## 📁 Arquivos

```
✅ FormPosts.cs           - Lógica
✅ FormPosts.Designer.cs  - Layout
✅ PostService.cs         - Serviço de Posts
```

---

## 🔧 Próximas Melhorias (Opcionais)

```
[ ] Adicionar coluna de data
[ ] Formatação de URL na coluna imagem
[ ] Preview de imagem
[ ] Busca/filtro
[ ] Paginação
[ ] Exportar para Excel
[ ] Ordenação de colunas
```

---

**Status**: ✅ Completo e testado  
**Data**: 2024  
**Versão**: 1.0.0
