# 🧪 GUIA DE TESTE - Sistema Administrativo

## ✅ Testes Manuais Recomendados

### 1. **Teste de Compilação**
- [x] Build sem erros
- [x] Build sem avisos críticos
- [x] Todos os namespaces resolvidos

### 2. **Teste de Inicialização**
```
1. Executar aplicação
   ✓ FormLogin deve aparecer
   ✓ Deve ter campos Email e Senha
   ✓ Deve ter botão Login
```

### 3. **Teste de Validação de Campos**
```
1. Clicar "Login" com campos vazios
   ✓ Deve aparecer mensagem: "Por favor, insira seu email"

2. Preencher email, deixar senha vazia
   ✓ Deve aparecer mensagem: "Por favor, insira sua senha"

3. Preencher email, clicar Tab para senha
   ✓ Senha deve aparecer mascarada com asteriscos
```

### 4. **Teste de Login Bem-sucedido**
```
Pré-requisitos:
- API FastAPI rodando em http://localhost:8000
- Usuário válido cadastrado (ex: usuario@email.com / senha)

Passos:
1. Preencher email válido
2. Preencher senha válida
3. Clicar "Login"
4. Botão deve mudar para "Conectando..."
5. Aguardar resposta da API
6. FormPrincipal deve abrir
7. Deve exibir: "Sistema administrativo conectado à API ✓"
```

### 5. **Teste de Login Falhado**
```
Passos:
1. Preencher email inválido
2. Preencher senha incorreta
3. Clicar "Login"
4. Deve aparecer MessageBox com erro descritivo
5. FormLogin deve permanecer aberta
6. Campos devem ser mantidos para retry
```

### 6. **Teste de Conexão com API**
```
Cenário 1: API desligada
- Esperado: "Erro ao conectar com a API: ..."
- Tipo: Mensagem de erro

Cenário 2: API respondendo com 401
- Esperado: "Falha na autenticação. Verifique suas credenciais."
- Tipo: Mensagem de erro

Cenário 3: API respondendo com 200 + token válido
- Esperado: FormPrincipal abre com token
- Tipo: Sucesso
```

### 7. **Teste de Saída da Aplicação**
```
1. De FormLogin
   ✓ Clicar X da janela: aplicação fecha

2. De FormPrincipal
   ✓ Clicar botão "Sair": aplicação fecha
   ✓ Clicar X da janela: aplicação fecha
```

### 8. **Teste de Interface**
```
FormLogin:
✓ Centralizada na tela
✓ Tamanho adequado (400x300)
✓ Labels visíveis
✓ TextBoxes com tamanho apropriado
✓ Botão Login com tamanho clicável

FormPrincipal:
✓ Centralizada na tela
✓ Tamanho adequado (500x300)
✓ Mensagem de status visível
✓ Botão Sair funcional
```

## 🔍 Verificações de Código

### AuthService
```csharp
✓ Envia POST para /auth/token
✓ Usa FormUrlEncodedContent
✓ Extrai "access_token" da resposta
✓ Trata HttpRequestException
✓ Retorna token como string
✓ Lança Exception descritiva em caso de erro
```

### BaseService
```csharp
✓ Herda para novos serviços
✓ Configura BaseAddress
✓ Adiciona Authorization Bearer header
✓ HttpClient protegido
```

### FormLogin
```csharp
✓ Valida campo Email
✓ Valida campo Senha
✓ Chama AuthService.LoginAsync
✓ Passa token para FormPrincipal
✓ Trata exceptions com MessageBox
✓ Atualiza UI durante operação
```

### FormPrincipal
```csharp
✓ Recebe token no construtor
✓ Exibe mensagem de status
✓ Botão Sair funciona
✓ Centralizado na tela
```

## 📊 Checklist de Testes

```
[ ] Compilação bem-sucedida
[ ] FormLogin abre ao iniciar
[ ] Validação de email funciona
[ ] Validação de senha funciona
[ ] Botão Login desabilita durante conexão
[ ] Login bem-sucedido abre FormPrincipal
[ ] Login falha com mensagem de erro
[ ] FormPrincipal exibe status correto
[ ] Botão Sair encerra aplicação
[ ] Fechar janela encerra aplicação
[ ] Interface responsiva e centrada
[ ] Sem erros durante execução
[ ] Headers de autenticação corretos
```

## 🐛 Possíveis Problemas e Soluções

### Problema: "API não encontrada"
**Solução**: Verificar se FastAPI está rodando em http://localhost:8000

### Problema: Token não extraído
**Solução**: Verificar se resposta da API tem formato `{"access_token": "valor"}`

### Problema: Botão fica preso em "Conectando..."
**Solução**: Aumentar timeout ou verificar conexão com API

### Problema: FormLogin não abre
**Solução**: Verificar se Program.cs está rodando `new FormLogin()`

### Problema: FormPrincipal não recebe token
**Solução**: Verificar se token é passado corretamente no construtor

## 📈 Métricas de Sucesso

✅ 100% de compilação bem-sucedida  
✅ 0 erros durante execução  
✅ Autenticação funcional em < 2 segundos  
✅ Interface responsiva  
✅ Mensagens de erro claras  
✅ Pronto para extensão  

## 🚀 Teste de Carga (Opcional)

```
1. Múltiplos logins sucessivos
2. Múltiplas tentativas de login falho
3. Conectar/desconectar rede durante login
4. Deixar aplicação aberta por 1+ hora
```

---

**Status**: ✅ Pronto para testes  
**Última Atualização**: 2024
