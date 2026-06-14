# 📋 FormPerfil - Documentação Completa

## 🎯 Visão Geral

FormPerfil é um formulário Windows Forms profissional e moderno para exibir e editar o perfil do usuário consumindo uma API FastAPI.

## 📐 Arquitetura

### Estrutura de Arquivos
```
sistemaadmin/
├── FormPerfil.cs              # Código principal do formulário
├── FormPerfil.Designer.cs     # Configuração do Designer
└── Services/
	└── ProfileService.cs      # Serviço de consumo da API
```

## 🎨 Layout Visual

O formulário possui 3 seções principais:

### 1. **Painel Topo** (Azul)
- Título: "Perfil do Usuário"
- Fonte: Segoe UI, 24pt, Bold
- Cor de Fundo: RGB(41, 128, 185)
- Altura: 70px
- Alinhamento: Centralizado

### 2. **Card Central** (Cinza claro)
Painel centralizado com:
- **Foto de Perfil** (PictureBox)
  - Tamanho: 250x250 px
  - Posição: Centralizado, topo do card
  - Modo: StretchImage (adapta ao tamanho)
  - Fundo: Branco

- **Informações do Usuário**
  - Username: Campo de Label com valor
  - Email: Campo de Label com valor
  - Espaçamento entre labels: 40px

- **Campo de Entrada**
  - Label: "Nova Foto (URL):"
  - TextBox multiline para entrada de URL
  - Tamanho: 540x35 px

- **Botões**
  - Botão Verde "✓ Atualizar Foto" (RGB 46, 204, 113)
  - Botão Azul "🔄 Recarregar Perfil" (RGB 52, 152, 219)
  - Largura: 260px cada um
  - Organizados lado a lado

## 🔧 Funcionalidades

### 1. Carregamento Inicial
```
FormPerfil_Load()
  ├─ CriarInterface()      // Cria layout visual
  └─ CarregarPerfil()      // GET /profile/me
```

### 2. Obter Dados do Usuário
**Método:** `CarregarPerfil()`
- Chama: `ProfileService.GetMeAsync()`
- Endpoint: `GET /profile/me`
- Header: `Authorization: Bearer {token}`
- Processa:
  - Username
  - Email
  - Foto (URL ou Base64)

### 3. Atualizar Foto
**Método:** `BtnAtualizarFoto_Click()`
- Valida URL não vazia
- Chama: `ProfileService.TrocarFotoAsync(url)`
- Endpoint: `POST /profile/trocar_foto`
- Payload: `{"foto_perfil": "url"}`
- Atualiza PictureBox após sucesso
- Limpa TextBox de entrada

### 4. Recarregar Dados
**Método:** `BtnRecarregarPerfil_Click()`
- Recarrega dados do perfil
- Atualiza interface com dados mais recentes

## 💻 Código Principal

### Inicialização
```csharp
public FormPerfil(string token)
{
	InitializeComponent();
	_token = token;
	_profileService = new ProfileService(token);
}
```

### Estrutura de UI
```csharp
private void CriarInterface()
{
	// Painel Topo com Título
	Panel pnlTopo = new Panel();
	// ... configuração

	// Painel Card Central
	Panel pnlCard = new Panel();
	// ... configuração com PictureBox, Labels, TextBox, Botões
}
```

### Carregamento de Dados
```csharp
private async void CarregarPerfil()
{
	try
	{
		var json = await _profileService.GetMeAsync();

		var username = ExtrairValor(json, "username");
		var email = ExtrairValor(json, "email");
		var fotoPerfil = ExtrairValor(json, "foto_perfil");

		// Atualizar interface
		lblUsernameValor.Text = username;
		lblEmailValor.Text = email;

		// Carregar foto (URL ou Base64)
		CarregarFoto(fotoPerfil);
	}
	catch (Exception ex)
	{
		MessageBox.Show($"Erro: {ex.Message}");
	}
}
```

### Atualização de Foto
```csharp
private async void BtnAtualizarFoto_Click(object sender, EventArgs e)
{
	try
	{
		string url = txtNovaFotoUrl.Text.Trim();

		if (string.IsNullOrEmpty(url))
		{
			MessageBox.Show("URL inválida");
			return;
		}

		await _profileService.TrocarFotoAsync(url);

		MessageBox.Show("Foto atualizada!");
		CarregarPerfil();
	}
	catch (Exception ex)
	{
		MessageBox.Show($"Erro: {ex.Message}");
	}
}
```

## 🔐 Segurança

- ✅ Token Bearer automaticamente incluído em requisições
- ✅ Validação de URLs vazias
- ✅ Try-catch em todas operações
- ✅ Sem exposição de dados sensíveis

## 📡 Integração com API

### Endpoints Utilizados

#### GET /profile/me
```bash
Headers:
  Authorization: Bearer {token}

Response:
{
  "id": 1,
  "username": "usuario",
  "email": "usuario@example.com",
  "foto_perfil": "url_ou_base64"
}
```

#### POST /profile/trocar_foto
```bash
Headers:
  Authorization: Bearer {token}
  Content-Type: application/json

Body:
{
  "foto_perfil": "url_ou_base64"
}

Response:
{
  "id": 1,
  "username": "usuario",
  "email": "usuario@example.com",
  "foto_perfil": "url_atualizada"
}
```

## 🎯 Casos de Uso

### 1. Visualizar Perfil
1. Abrir FormPerfil
2. Sistema carrega dados do /profile/me
3. Exibe username, email e foto

### 2. Atualizar Foto
1. Inserir URL da nova foto em "Nova Foto (URL):"
2. Clicar "✓ Atualizar Foto"
3. Sistema envia POST /profile/trocar_foto
4. Foto é atualizada e recarregada

### 3. Recarregar Dados
1. Clicar "🔄 Recarregar Perfil"
2. Sistema obtém dados mais recentes
3. Interface atualizada

## 🛡️ Tratamento de Erros

- ✅ URL vazia: Aviso de validação
- ✅ Imagem inválida: Usa imagem padrão "Sem Foto"
- ✅ Erro de API: MessageBox com mensagem de erro
- ✅ Falha de conexão: Trata como exceção geral

## 🎨 Paleta de Cores

| Elemento | RGB | Uso |
|----------|-----|-----|
| Topo | (41, 128, 185) | Fundo do título |
| Card | (236, 240, 241) | Fundo do painel central |
| Texto Bold | (52, 73, 94) | Labels principais |
| Botão Atualizar | (46, 204, 113) | Cor verde |
| Botão Recarregar | (52, 152, 219) | Cor azul |

## 📊 Tamanhos e Espaçamento

| Elemento | Tamanho | Posição |
|----------|--------|--------|
| Foto | 250x250 px | Centro, topo (Y:20) |
| Username | 420x25 px | X:140, Y:290 |
| Email | 420x25 px | X:140, Y:330 |
| TextBox Foto | 540x35 px | X:30, Y:415 |
| Botão | 260x45 px | Y:470 |

## 🚀 Como Usar

### Abrir FormPerfil
```csharp
// Em FormPrincipal
FormPerfil formPerfil = new FormPerfil(_token);
formPerfil.TopLevel = false;
formPerfil.Dock = DockStyle.Fill;
pnlContainer.Controls.Add(formPerfil);
formPerfil.Show();
```

### Integração com Token
```csharp
// O token é passado ao construtor
public FormPerfil(string token)
{
	_token = token;  // Armazenado para uso posterior
	_profileService = new ProfileService(token);
}
```

## ✅ Checklist de Funcionalidades

- ✅ Layout profissional com Panels
- ✅ PictureBox centralizado para foto
- ✅ Labels para username e email
- ✅ TextBox para entrada de URL de foto
- ✅ Botões lado a lado (verde e azul)
- ✅ Consumo de GET /profile/me
- ✅ Consumo de POST /profile/trocar_foto
- ✅ Async/await em todas operações
- ✅ HttpClient com Bearer token
- ✅ Try-catch para tratamento de erros
- ✅ MessageBox para feedback ao usuário
- ✅ Validação de URL vazia
- ✅ Imagem padrão quando ausente
- ✅ Atualização automática após alterações
- ✅ Recarregar dados manual

## 📝 Notas

- O formulário foi criado com programação dinâmica (sem Designer visual)
- Todos os controles são criados em tempo de execução
- Suporta URLs e Base64 para fotos
- Layout responsivo e centrado
- Compatível com .NET Framework 4.7.2

## 🔗 Dependências

- `sistemaadmin.Services.ProfileService` - Serviço de consumo da API
- `System.Drawing` - Para cores e fontes
- `System.Windows.Forms` - Para UI
- `System.Text.RegularExpressions` - Para parsing de JSON

---

**Status:** ✅ Completo e Funcional
**Última Atualização:** 2024
**Versão:** 1.0
