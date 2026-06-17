# 🔍 Troubleshooting - Erro de Base64 na Imagem de Perfil

## 📋 Checklist de Diagnóstico

### 1️⃣ O Erro Persiste?

Se ainda houver erro ao abrir o formulário de perfil:

**Passo 1:** Verificar Debug Output
```
Press: Ctrl+Alt+O (Debug Output window)
Run: Sistema → FormPerfil
Look for logs starting with [FormPerfil]
```

**Possível output:**
```
[FormPerfil] Tentando carregar imagem: https://...
[FormPerfil] Detectado: URL absoluta
[FormPerfil] Imagem carregada com sucesso
```

---

### 2️⃣ Se Ver Erro no Debug Output

#### ❌ Erro: "Data URI inválido: vírgula não encontrada"
```
Causa: Formato Data URI está corrompido
Solução: Verificar como a API retorna foto_perfil
```

#### ❌ Erro: "Base64 inválido: comprimento não é múltiplo de 4"
```
Causa: Base64 incompleto ou corrupto
Solução: Remover caracteres extras no final
```

#### ❌ Erro: "Erro ao decodificar Base64"
```
Causa: String contém caracteres inválidos
Solução: Verificar se há caracteres especiais não esperados
```

---

### 3️⃣ Imagem Não Aparece?

Se vir "Sem Foto" cinza:

**Passo 1:** Verificar se API está rodando
```
Abrir navegador: http://localhost:8000/profile/me
Esperado: Resposta JSON com "foto_perfil"
```

**Passo 2:** Verificar formato retornado
```json
{
  "id": 1,
  "username": "usuario",
  "email": "email@example.com",
  "foto_perfil": "https://..." ou "/api/..." ou "data:image/..." ou "iVBORw0KGgo..."
}
```

**Passo 3:** Testar cada formato manualmente

---

## 🧪 Testes Manuais

### Teste 1: URL Absoluta
```csharp
// Simular chamada
string fotoPerfil = "https://via.placeholder.com/250";
await CarregarImagemAsync(fotoPerfil);

// Esperado: ✅ Imagem exibida
```

### Teste 2: Caminho Relativo
```csharp
// Simular chamada
string fotoPerfil = "/api/upload/imagem/123";
await CarregarImagemAsync(fotoPerfil);

// Esperado: 
// → Converte para: http://localhost:8000/api/upload/imagem/123
// → ✅ Imagem exibida
```

### Teste 3: Data URI
```csharp
// Simular chamada
string fotoPerfil = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg...";
await CarregarImagemAsync(fotoPerfil);

// Esperado: ✅ Imagem exibida
```

### Teste 4: Base64 Puro
```csharp
// Simular chamada
string fotoPerfil = "iVBORw0KGgoAAAANSUhEUg...";
await CarregarImagemAsync(fotoPerfil);

// Esperado: ✅ Imagem exibida
```

### Teste 5: Base64 Inválido
```csharp
// Simular chamada
string fotoPerfil = "XYZ123ABC!!!";
await CarregarImagemAsync(fotoPerfil);

// Esperado: ✅ Exibe imagem padrão (sem erro)
```

---

## 🔧 Como Executar Testes

### Opção 1: Adicionar Debug Temporário

Em `FormPerfil.cs`, adicionar no método `CarregarPerfilAsync()`:

```csharp
private async Task CarregarPerfilAsync()
{
	try
	{
		// ... código existente ...

		var fotoPerfil = ExtrairValor(json, "foto_perfil");

		// ✅ DEBUG TEMPORÁRIO
		System.Diagnostics.Debug.WriteLine($"[DEBUG] foto_perfil recebido: {fotoPerfil}");
		System.Diagnostics.Debug.WriteLine($"[DEBUG] Tipo: {DetectarTipo(fotoPerfil)}");

		if (!string.IsNullOrEmpty(fotoPerfil) && fotoPerfil != "null")
		{
			await CarregarImagemAsync(fotoPerfil);
		}
	}
	catch (Exception ex)
	{
		MessageBox.Show($"Erro: {ex.Message}", "Erro", MessageBoxButtons.OK, MessageBoxIcon.Error);
	}
}

// Método auxiliar para debug
private string DetectarTipo(string valor)
{
	if (valor.StartsWith("http://") || valor.StartsWith("https://")) return "URL absoluta";
	if (valor.StartsWith("/")) return "Caminho relativo";
	if (valor.StartsWith("data:")) return "Data URI";
	return "Base64 (ou outro)";
}
```

### Opção 2: Usar Conditional Breakpoint

1. Clicar na linha 49 (onde foto_perfil é extraído)
2. Direita → Filtro → Adicionar Condição:
   ```
   !string.IsNullOrEmpty(fotoPerfil)
   ```
3. Executar e inspecionar valor de `fotoPerfil`

---

## 📊 Fluxograma de Diagnóstico

```
┌─────────────────────────────────────┐
│ Erro ao abrir FormPerfil?           │
└─────────────────────────────────────┘
		│                    │
	   SIM                  NÃO
		↓                    ↓
┌──────────────┐    ┌──────────────────────┐
│ Qual erro?   │    │ Imagem aparece?      │
└──────────────┘    └──────────────────────┘
		│                    │
	┌───┴────┬──────┐       SIM
	↓        ↓      ↓        ↓
FormatEx... HTTP... Data...  ✅ OK!
	↓        ↓      ↓
	│        │      └──→ Exibir padrão
	│        │            ↓
	│        └──────→ Verificar Bearer
	│                    ↓
	└────→ Verificar formato da API
		   ↓
	  Ver Debug Output
		   ↓
	  Ajustar se necessário
```

---

## 🆘 Problemas Comuns

### Problema 1: "Base64 inválido"
**Possíveis causas:**
- API retorna Base64 com espaços
- API retorna Base64 incompleto
- API retorna strings vazias

**Solução:**
- Ver resposta bruta da API
- Copiar valor completo
- Testar manualmente em Debug Output

---

### Problema 2: "HTTP 401 ou 403"
**Possível causa:**
- Bearer token inválido ou expirado

**Solução:**
- Verificar se está autenticado
- Fazer login novamente
- Verificar Bearer token em Authorization header

---

### Problema 3: "HTTP 404"
**Possível causa:**
- URL ou caminho relativo inválido

**Solução:**
- Verificar endpoint da API
- Testar URL no navegador
- Ver se arquivo realmente existe no servidor

---

### Problema 4: Imagem Sempre Padrão
**Possível causa:**
- foto_perfil vindo como string vazia ou "null"

**Solução:**
```csharp
// Adicionar debug em CarregarPerfilAsync
System.Diagnostics.Debug.WriteLine($"[DEBUG] fotoPerfil: '{fotoPerfil}'");
System.Diagnostics.Debug.WriteLine($"[DEBUG] É vazio? {string.IsNullOrEmpty(fotoPerfil)}");
System.Diagnostics.Debug.WriteLine($"[DEBUG] É 'null'? {fotoPerfil == "null"}");
```

---

## 📝 Checklist Final

- [ ] Compilação bem-sucedida (sem erros CS)
- [ ] API respondendo (http://localhost:8000/profile/me)
- [ ] Bearer token válido
- [ ] Debug Output mostrando logs [FormPerfil]
- [ ] Imagem exibida OU imagem padrão (sem exceção)
- [ ] Botão "Recarregar Perfil" funciona
- [ ] Sem travamento de UI

---

## 🎯 Resultado Esperado

✅ FormPerfil abre sem erro  
✅ Imagem de perfil exibe (ou padrão se falhar)  
✅ Debug Output mostra tipo detectado  
✅ Botões funcionam  
✅ Sem FormatException  

---

## 🆘 Se Ainda Não Funcionar

1. Verificar se arquivo foi salvo corretamente
2. Fazer Clean Build (Rebuild Solution)
3. Limpar bin/obj
4. Reabrir Visual Studio
5. Testar novamente

Se problema persistir, fornecer:
- Screenshot do Debug Output
- Valor exato de foto_perfil recebido
- Resposta bruta de http://localhost:8000/profile/me

