# 📖 Guia de Boas Práticas - Windows Forms + API REST

## 🎯 Objetivo
Documentar as melhores práticas utilizadas no projeto para evitar problemas de performance, travamentos e carregamento de recursos.

---

## ❌ ANTI-PATTERNS (O que NÃO fazer)

### 1. ❌ async void (NUNCA use!)
```csharp
// ❌ ERRADO - async void
private async void CarregarDados()
{
	var resultado = await _service.GetDataAsync();
	// Problema: Sem await possível, sem tratamento de exceção
}
```

**Por que é problema:**
- Chamador não pode fazer `await`
- Exceções não são propagadas
- Difícil de testar
- Exceções não tratadas causam crash

**Quando é aceitável:**
- APENAS event handlers (click, Load, etc)
- Mesmo assim, prefira `async Task` quando possível

---

### 2. ❌ .Result e .Wait() (NUNCA use!)
```csharp
// ❌ ERRADO - Bloqueio da UI
private void btnClick(object sender, EventArgs e)
{
	var resultado = _service.GetDataAsync().Result;  // BLOQUEIA UI!
	// ou
	_service.GetDataAsync().Wait();  // BLOQUEIA UI!
}
```

**Por que é problema:**
- Bloqueia UI thread completamente
- Aplicação fica travada
- Possível deadlock
- Performance péssima

---

### 3. ❌ PictureBox.Load() com URL sem autenticação
```csharp
// ❌ ERRADO - Bloqueante e sem Bearer token
picFoto.Load(url);  // Bloqueia, sem autenticação
```

**Por que é problema:**
- Síncrono e bloqueia UI
- URLs protegidas falham (401/403)
- Sem timeout
- Sem tratamento de erro robusto

---

### 4. ❌ Não liberar recursos
```csharp
// ❌ ERRADO - Memory leak
HttpClient client = new HttpClient();
// ... usar
// (nunca liberar) - vazamento de memória!
```

---

## ✅ BOAS PRÁTICAS (O que fazer)

### 1. ✅ async Task (sempre que possível)
```csharp
// ✅ CORRETO
private async Task CarregarDadosAsync()
{
	try
	{
		var resultado = await _service.GetDataAsync();
		AtualizarUI(resultado);
	}
	catch (Exception ex)
	{
		MessageBox.Show($"Erro: {ex.Message}");
	}
}

// Chamada em event handler
private void FormLoad(object sender, EventArgs e)
{
	_ = CarregarDadosAsync();  // Fire-and-forget
}
```

**Benefícios:**
- Chamador pode fazer `await`
- Exceções propagadas corretamente
- Fácil de testar
- Não bloqueia UI

---

### 2. ✅ HttpClient assíncrono com Bearer token
```csharp
// ✅ CORRETO
private HttpClient _httpClient;

public FormPerfil(string token)
{
	_httpClient = new HttpClient();
	_httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {token}");
	_httpClient.Timeout = TimeSpan.FromSeconds(10);
}

private async Task<Image> CarregarImagemAsync(string url)
{
	try
	{
		using (var response = await _httpClient.GetAsync(url, HttpCompletionOption.ResponseContentRead))
		{
			if (response.IsSuccessStatusCode)
			{
				using (var stream = await response.Content.ReadAsStreamAsync())
				{
					var memStream = new MemoryStream();
					await stream.CopyToAsync(memStream);
					memStream.Position = 0;
					return Image.FromStream(memStream);
				}
			}
		}
	}
	catch (Exception ex)
	{
		Debug.WriteLine($"Erro: {ex.Message}");
	}
	return null;
}
```

**Benefícios:**
- Não bloqueia UI
- Suporta autenticação Bearer
- Timeout configurável
- Tratamento de erro robusto

---

### 3. ✅ InvokeRequired para thread-safety
```csharp
// ✅ CORRETO - Atualizar UI de thread diferente
if (InvokeRequired)
{
	Invoke(new Action(() =>
	{
		if (picFoto.Image != null)
			picFoto.Image.Dispose();
		picFoto.Image = img;
	}));
}
else
{
	if (picFoto.Image != null)
		picFoto.Image.Dispose();
	picFoto.Image = img;
}
```

---

### 4. ✅ Liberar recursos com Dispose
```csharp
// ✅ CORRETO
protected override void Dispose(bool disposing)
{
	if (disposing)
	{
		_httpClient?.Dispose();
		if (picFoto?.Image != null)
		{
			picFoto.Image.Dispose();
			picFoto.Image = null;
		}
	}
	base.Dispose(disposing);
}
```

---

### 5. ✅ Usar Task.Run para operações CPU-intensivas
```csharp
// ✅ CORRETO
private async Task CarregarImagemBase64Async(string base64String)
{
	try
	{
		// Decodificar em thread separada
		byte[] imageBytes = await Task.Run(() => Convert.FromBase64String(base64String));

		using (MemoryStream ms = new MemoryStream(imageBytes))
		{
			Image img = Image.FromStream(ms);
			AtualizarUI(img);
		}
	}
	catch (Exception ex)
	{
		Debug.WriteLine($"Erro: {ex.Message}");
	}
}
```

---

### 6. ✅ Tratamento robusto de erro com fallback
```csharp
// ✅ CORRETO
try
{
	await CarregarImagemAsync(url);
}
catch (Exception ex)
{
	Debug.WriteLine($"Erro ao carregar imagem: {ex.Message}");
	ExibirImagemPadrao();  // Fallback
}
```

---

## 🏗️ Arquitetura Recomendada

### Service Layer Pattern
```
Forms (UI) 
	↓ await
Services (Lógica)
	↓ await
API (HttpClient)
	↓ await
Servidor
```

### BaseService com HttpClient Singleton
```csharp
public class BaseService
{
	private static HttpClient _sharedHttpClient;

	protected HttpClient HttpClient
	{
		get { return GetOrCreateHttpClient(); }
	}

	private static HttpClient GetOrCreateHttpClient()
	{
		if (_sharedHttpClient == null)
		{
			lock (_lockObject)
			{
				if (_sharedHttpClient == null)
				{
					_sharedHttpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(30) };
				}
			}
		}
		return _sharedHttpClient;
	}
}
```

**Benefícios:**
- Evita socket exhaustion
- Reutiliza conexões
- Thread-safe
- Melhor performance

---

## 🔍 Checklist de Código

Antes de fazer commit, verifique:

- [ ] Nenhum `async void` (exceto event handlers)
- [ ] Nenhum `.Result` ou `.Wait()`
- [ ] Todo `await` está em método `async`
- [ ] Recursos liberados no `Dispose()`
- [ ] HttpClient usa Bearer token quando necessário
- [ ] Timeout configurado
- [ ] Exceções tratadas
- [ ] UI atualizada com `InvokeRequired`
- [ ] Testes incluídos (ou plano de teste)

---

## 📊 Comparação: Antes vs Depois

| Aspecto | ANTES | DEPOIS |
|--------|-------|--------|
| **Pattern** | async void | async Task |
| **Bloqueio UI** | Sim (travamentos) | Não (não-bloqueante) |
| **Autenticação** | Não (falha em URL protegida) | Sim (Bearer token) |
| **Timeout** | Indefinido | 10-30 segundos |
| **Tratamento erro** | Falha silenciosa | Fallback automático |
| **Carregamento imagem** | picFoto.Load() | await HttpClient |
| **Thread-safety** | Arriscado | InvokeRequired |
| **Gerenciamento recurso** | Memory leak | Dispose correto |

---

## 🚀 Performance Esperada

Após as melhorias:

1. **Tempo de carregamento do Form**: < 200ms (sem bloqueio)
2. **Carregamento de imagem**: 1-2 segundos (paralelo)
3. **Responsividade**: UI sempre responsiva durante carregamento
4. **Taxa de erro**: Fallback automático (sem crash)

---

## 🔗 Referências

- [Async/Await Best Practices](https://docs.microsoft.com/en-us/archive/msdn-magazine/2013/march/async-await-best-practices-in-asynchronous-programming)
- [HttpClient Usage Guidelines](https://docs.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient)
- [Windows Forms Threading](https://docs.microsoft.com/en-us/dotnet/desktop/winforms/controls/how-to-make-thread-safe-calls-to-windows-forms-controls)
- [Resource Management in .NET](https://docs.microsoft.com/en-us/dotnet/standard/garbage-collection/implementing-dispose)

---

## 📋 Arquivos Modificados

1. **FormPerfil.cs**
   - Refatoração completa de async/await
   - Suporte a Bearer token
   - Carregamento assíncrono de imagem

2. **FormPosts.cs**
   - CarregarPosts() → CarregarPostsAsync()
   - Todas as chamadas com await

3. **FormDashboard.cs**
   - CarregarDados() → CarregarDadosAsync()
   - Todas as chamadas com await

4. **BaseService.cs**
   - Novo método BaixarImagemAsync()
   - Suporte a Bearer token

5. **FormPerfil.Designer.cs**
   - Dispose() melhorado

---

**Versão**: 1.0  
**Data**: 2024  
**Status**: ✅ IMPLEMENTADO
