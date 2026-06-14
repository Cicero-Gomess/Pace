# 🚀 FormPerfil - Referência Rápida

## 📝 Arquivo Principal

**Localização:** `sistemaadmin/FormPerfil.cs`

## 🎯 O que é

Formulário Windows Forms profissional para exibir e editar perfil do usuário com:
- Interface moderna e organizada
- Consumo de API FastAPI
- Layout responsivo com Panels
- Suporte a fotos (URL e Base64)

## 🔧 Inicializar

```csharp
// Criar instância
FormPerfil form = new FormPerfil(token);

// Em painel container
form.TopLevel = false;
form.Dock = DockStyle.Fill;
pnlContainer.Controls.Add(form);
form.Show();
```

## 📐 Layout

```
Topo: Azul com título "Perfil do Usuário"
	  ↓
Card: Panel cinzento com:
  - Foto centralizada (250x250)
  - Username e Email
  - TextBox para nova foto URL
  - Botões lado a lado
```

## 🎨 Cores Principais

- **Topo:** RGB(41, 128, 185) - Azul
- **Card:** RGB(236, 240, 241) - Cinza claro
- **Atualizar:** RGB(46, 204, 113) - Verde
- **Recarregar:** RGB(52, 152, 219) - Azul claro

## 🔌 Endpoints Usados

### GET /profile/me
```
Headers: Authorization: Bearer {token}
Resposta: { id, username, email, foto_perfil }
```

### POST /profile/trocar_foto
```
Headers: Authorization: Bearer {token}
Body: { "foto_perfil": "url" }
Resposta: Perfil atualizado
```

## 💡 Funcionalidades

| Funcionalidade | Como Fazer | Endpoint |
|---|---|---|
| Ver perfil | Abrir formulário | GET /profile/me |
| Atualizar foto | Inserir URL e clicar botão | POST /profile/trocar_foto |
| Recarregar dados | Clicar botão Recarregar | GET /profile/me |

## 🔑 Métodos Principais

```csharp
CarregarPerfil()              // GET /profile/me
BtnAtualizarFoto_Click()      // POST /profile/trocar_foto
BtnRecarregarPerfil_Click()   // Recarregar dados
ExibirImagemPadrao()          // Mostrar imagem padrão
```

## 📊 Dimensões Principais

| Elemento | Tamanho |
|----------|---------|
| Janela | 700 x 800 px |
| Foto | 250 x 250 px |
| Card | 600 x 580 px |
| Botões | 260 x 45 px |

## ✅ Validações

- URL vazia não é aceita
- Suporta URL e Base64 para foto
- Imagem padrão se não houver foto
- Try-catch em todas operações

## 🎯 Fluxo Completo

```
1. Abrir FormPerfil(token)
   ↓
2. FormPerfil_Load()
   ├─ CriarInterface()    (Cria visual)
   └─ CarregarPerfil()    (GET /profile/me)
   ↓
3. Dados carregados
   ├─ username
   ├─ email
   └─ foto
   ↓
4. Usuário interage
   ├─ Clica "Atualizar Foto"
   │  └─ POST /profile/trocar_foto
   │     └─ Recarregar dados
   │
   └─ Clica "Recarregar"
	  └─ GET /profile/me
		 └─ Atualizar interface
```

## 🔒 Segurança

- ✅ Token Bearer automático
- ✅ Validação de entrada
- ✅ Tratamento de erros
- ✅ Sem exposição de dados

## 📚 Documentação Disponível

| Arquivo | Conteúdo |
|---------|----------|
| FORMPERFIL_RESUMO.md | Este arquivo (referência rápida) |
| FORMPERFIL_DOCUMENTACAO.md | Documentação completa e detalhada |
| EXEMPLOS_FORMPERFIL.md | 10 exemplos práticos de uso |

## 🧪 Teste Rápido

```csharp
// 1. No FormPrincipal, adicionar ao menu
Button btnPerfil = new Button();
btnPerfil.Text = "👤 Perfil";
btnPerfil.Click += (s, e) => AbrirFormPerfil();
pnlMenu.Controls.Add(btnPerfil);

// 2. Implementar método
private void AbrirFormPerfil()
{
	FormPerfil form = new FormPerfil(_token);
	form.TopLevel = false;
	form.Dock = DockStyle.Fill;
	pnlContainer.Controls.Clear();
	pnlContainer.Controls.Add(form);
	form.Show();
}

// 3. Testar!
// - Abrir formulário
// - Carregar dados
// - Tentar atualizar foto
```

## 🐛 Troubleshooting

| Problema | Solução |
|----------|---------|
| Token não é reconhecido | Verificar se ProfileService recebe token |
| Foto não carrega | URL pode estar inválida |
| Erro 401 | Token expirado, fazer login novamente |
| Erro 404 | Endpoint pode estar incorreto |
| Layout quebrado | Verificar dimensões dos Panels |

## 📋 Checklist de Uso

- [ ] Token válido foi passado
- [ ] ProfileService está configurado
- [ ] API está rodando em localhost:8000
- [ ] Endpoints /profile/me e /profile/trocar_foto existem
- [ ] FormPerfil compilou sem erros
- [ ] FormPerfil abri sem erros
- [ ] Dados foram carregados
- [ ] Botões funcionam

## 🎓 Próximas Etapas

1. Adicionar ao menu do FormPrincipal
2. Testar todos os endpoints
3. Personalizar cores se necessário
4. Testar atualização de foto
5. Testar validações
6. Incluir em produção

## 📞 Informações

- **Status:** ✅ Completo e Funcional
- **Plataforma:** .NET Framework 4.7.2
- **Tipo:** Windows Forms
- **Modo:** Programático (sem Designer visual)
- **Versão:** 1.0

---

**Para documentação completa, veja: FORMPERFIL_DOCUMENTACAO.md**  
**Para exemplos práticos, veja: EXEMPLOS_FORMPERFIL.md**
