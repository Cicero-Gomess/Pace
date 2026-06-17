# 📊 Diagrama Visual - Tratamento de Imagem de Perfil

## Fluxo Completo de Carregamento

```
╔═══════════════════════════════════════════════════════════════╗
║              FormPerfil_Load (evento de abertura)             ║
╚═══════════════════════════════════════════════════════════════╝
							  │
							  ▼
					┌──────────────────────┐
					│ ExibirImagemPadrao() │
					│  (cinza/padrão)      │
					└──────────────────────┘
							  │
							  ▼
					┌──────────────────────┐
					│ CarregarPerfilAsync()│
					│ • Chamar API         │
					│ • Obter JSON         │
					│ • Extrair campos     │
					└──────────────────────┘
							  │
							  ▼
		   ┌──────────────────────────────────────┐
		   │ JSON recebido da API:                │
		   │ {                                    │
		   │   "username": "usuario",             │
		   │   "email": "user@example.com",       │
		   │   "foto_perfil": "???"  ← Detectar  │
		   │ }                                    │
		   └──────────────────────────────────────┘
							  │
							  ▼
		 ┌────────────────────────────────────────────┐
		 │ CarregarImagemAsync(fotoPerfil)           │
		 │ Detectar formato e rotear para método     │
		 └────────────────────────────────────────────┘
							  │
			┌─────────────────┼─────────────────┬──────────────┐
			│                 │                 │              │
			▼                 ▼                 ▼              ▼
	  ┌──────────┐      ┌──────────┐      ┌──────────┐   ┌──────────┐
	  │ URL      │      │ Caminho  │      │ Data URI │   │ Base64   │
	  │ absoluta │      │ relativo │      │ puro     │   │ puro     │
	  │          │      │          │      │          │   │          │
	  │ https:// │      │ /api/    │      │ data:    │   │ iVBOR... │
	  │ http://  │      │          │      │ image/   │   │ (outro)  │
	  └──────────┘      └──────────┘      └──────────┘   └──────────┘
			│                 │                 │              │
			▼                 ▼                 ▼              ▼
   ┌─────────────────┐ ┌─────────────────┐ ┌──────────────┐ ┌────────┐
   │ HttpClient      │ │ Converte para   │ │ Extrai       │ │ Valida │
   │ GetAsync()      │ │ URL completa:   │ │ Base64       │ │ e      │
   │ + Bearer        │ │ http://localhost│ │ string       │ │ decodif│
   │ token           │ │ :8000 + /api/.. │ │ (após ,)     │ │         │
   │                 │ │                 │ │              │ │         │
   │ ↓               │ │ ↓               │ │ ↓            │ │ ↓      │
   │ MemoryStream    │ │ HttpClient      │ │ Base64Array  │ │ Image  │
   │                 │ │ GetAsync()      │ │              │ │ .From  │
   └─────────────────┘ └─────────────────┘ └──────────────┘ │Stream()│
			│                 │                 │              └────────┘
			│                 │                 │                   │
			└─────────────────┴─────────────────┴───────────────────┘
							  │
							  ▼
				 ┌─────────────────────────┐
				 │ InvokeRequired?         │
				 └─────────────────────────┘
					│                 │
				   SIM               NÃO
					│                 │
					▼                 ▼
			  ┌──────────┐       ┌──────────┐
			  │ Invoke() │       │ Direto   │
			  │ (thread  │       │ na UI    │
			  │ principal)       │ thread   │
			  └──────────┘       └──────────┘
					│                 │
					└─────────┬───────┘
							  │
							  ▼
					┌──────────────────┐
					│ picFoto.Image =  │
					│ img              │
					│ (exibir imagem)  │
					└──────────────────┘
							  │
							  ▼
					   ┌─────────────┐
					   │   ✅ SUCESSO   │
					   │ Imagem visível│
					   └─────────────┘
```

---

## Tratamento de Erros

```
╔════════════════════════════════════════════════════════════╗
║        Erro em qualquer ponto do processo                 ║
╚════════════════════════════════════════════════════════════╝
						  │
						  ▼
		┌─────────────────────────────────────┐
		│ catch (Exception ex)                │
		│ {                                   │
		│   Log: [FormPerfil] Erro: {msg}     │
		│ }                                   │
		└─────────────────────────────────────┘
						  │
						  ▼
		┌─────────────────────────────────────┐
		│ ExibirImagemPadrao()                │
		│                                     │
		│ • Bitmap 250x250 cinza             │
		│ • Texto: "Sem Foto"                │
		│ • Sem exceção lançada              │
		└─────────────────────────────────────┘
						  │
						  ▼
				 ┌───────────────────┐
				 │ UI continua OK    │
				 │ Sem crash         │
				 │ Sem deadlock      │
				 └───────────────────┘
```

---

## Detecção de Tipo

```
┌──────────────────────────────────────────────┐
│  fotoPerfil = valor recebido da API         │
└──────────────────────────────────────────────┘
						│
		┌───────────────┼───────────────┐
		│               │               │
		▼               ▼               ▼
   ┌─────────┐  ┌──────────────┐ ┌────────────┐
   │ Começa  │  │ Começa       │ │ Começa com │
   │ com     │  │ com "/"?     │ │ "data:"?   │
   │ "http"? │  │              │ │            │
   └─────────┘  └──────────────┘ └────────────┘
		│              │                │
	  SIM            SIM              SIM
		│              │                │
		▼              ▼                ▼
   ┌─────────────┐ ┌─────────────┐ ┌──────────┐
   │ URL absoluta│ │ Path relativo│ │ Data URI │
   │             │ │              │ │          │
   │ Usar HTTP   │ │ Converter:   │ │ Extrair: │
   │ Client      │ │ http://...   │ │ str[pos:]│
   │             │ │ +valor       │ │ após ,   │
   └─────────────┘ └─────────────┘ └──────────┘
		│              │                │
		└──────────────┴────────────────┘
					  │
					  ▼
		┌──────────────────────────────┐
		│ Se nenhum match anterior...  │
		│ Assume: Base64 puro          │
		└──────────────────────────────┘
					  │
					  ▼
			┌─────────────────────┐
			│ Descodificar Base64 │
			│ com validações      │
			└─────────────────────┘
```

---

## Validação de Base64

```
┌────────────────────────────────────┐
│ string base64String = valor        │
└────────────────────────────────────┘
			│
			▼
	┌─────────────────┐
	│ 1. Vazio?       │
	└─────────────────┘
	   SIM → ❌ Retorna null
	   NÃO → Continua
			│
			▼
	┌─────────────────────────────┐
	│ 2. Remove espaços           │
	│    Regex.Replace(val, @"\s")│
	└─────────────────────────────┘
			│
			▼
	┌──────────────────────────────────┐
	│ 3. Verifica comprimento          │
	│    length % 4 == 0?              │
	└──────────────────────────────────┘
	   NÃO (inválido) → ❌ Retorna null
	   SIM → Continua
			│
			▼
	┌──────────────────────────────────┐
	│ 4. Try-Catch                     │
	│    Convert.FromBase64String()    │
	└──────────────────────────────────┘
	   Sucesso → ✅ Retorna byte[]
	   Erro → ❌ Retorna null
			│
			▼
	┌──────────────────────────────────┐
	│ 5. Verificar resultado           │
	│    if (bytes == null) → Padrão   │
	│    else → Criar imagem           │
	└──────────────────────────────────┘
```

---

## Thread Safety

```
┌────────────────────────────────────┐
│ Depois de await ou Task.Run()      │
│ (pode estar em thread diferente)   │
└────────────────────────────────────┘
			│
			▼
	┌────────────────────┐
	│ if (InvokeRequired)│
	│ {                  │
	│   Thread diferente │
	│   da UI            │
	└────────────────────┘
	   SIM → Usar Invoke()
	   NÃO → Direto na thread UI
			│
			▼
	┌────────────────────┐
	│ Invoke(new Action()│
	│ {                  │
	│   picFoto.Image =  │
	│   img;             │
	│ });                │
	└────────────────────┘
			│
			▼
	┌────────────────────┐
	│ ✅ Thread-safe     │
	│ UI marshaled       │
	│ Sem crash         │
	└────────────────────┘
```

---

## Estados Finais

```
┌────────────────────────────────────┐
│          INÍCIO (Load)             │
│     ExibirImagemPadrao()           │
│     (cinza com "Sem Foto")         │
└────────────────────────────────────┘
				 │
		 Sucesso │ Erro
				 │
	 ┌───────────┴────────────┐
	 ▼                        ▼
┌──────────────┐      ┌──────────────┐
│ ✅ SUCESSO     │      │ ⚠️ FALLBACK    │
│              │      │              │
│ Imagem real  │      │ Imagem padrão│
│ carregada    │      │ Sem exceção  │
│              │      │              │
│ Log:         │      │ Log:         │
│ Imagem OK    │      │ Erro: {msg}  │
└──────────────┘      └──────────────┘
	 │                        │
	 │  Ambos resultam em:    │
	 └────────────┬───────────┘
				  ▼
		 ┌─────────────────┐
		 │  UI Funcional   │
		 │  Sem Crashes    │
		 │  Sem Deadlock   │
		 │  Sem Exception  │
		 └─────────────────┘
```

---

## Casos de Sucesso Possíveis

```
ENTRADA               DETECÇÃO          PROCESSAMENTO     RESULTADO
─────────────────────────────────────────────────────────────────

https://site.       → URL absoluta  → HttpClient        ✅ Imagem
com/foto.png           HttpClient                       carregada

/api/imagem/123     → Caminho relativo → Converte URL   ✅ Imagem
					   + HttpClient    → HttpClient     carregada

data:image/png;base → Data URI      → Extrai Base64    ✅ Imagem
64,iVBORw0KGgo...     + Base64       → Decodifica       carregada

iVBORw0KGgoAAAA...  → Base64 puro   → Valida + Decode  ✅ Imagem
														carregada

(vazio ou "null")   → Não aplica    → ExibirPadrao()    ⚠️ Padrão
					   qualquer
```

---

## Resumo Técnico

```
┌─────────────────────────────────────────────────────────┐
│                   DIAGRAMA TÉCNICO                      │
├─────────────────────────────────────────────────────────┤
│ ENTRADA                                                 │
│ ├─ URL (http/https) → HttpClient.GetAsync()             │
│ ├─ Caminho (/)      → Converte URL → HttpClient         │
│ ├─ Data URI (data:) → Extrai Base64 → Decodifica       │
│ └─ Base64 puro      → Valida → Decodifica              │
│                                                         │
│ VALIDAÇÃO (Multicamada)                                │
│ ├─ Verificar não vazio                                  │
│ ├─ Remover espaços em branco                            │
│ ├─ Validar comprimento (múltiplo de 4)                  │
│ └─ Try-catch FormatException                            │
│                                                         │
│ RESULTADO                                               │
│ ├─ ✅ Image.FromStream(bytes)                           │
│ ├─ InvokeRequired/Invoke()                              │
│ ├─ picFoto.Image = img                                  │
│ └─ ⚠️ ExibirImagemPadrao() em erro                      │
└─────────────────────────────────────────────────────────┘
```

