# Pace

O Pace é uma rede social integrada a ferramentas de autodesenvolvimento. A plataforma permite que pessoas compartilhem ideias e conquistas, acompanhem outros usuários e participem de comunidades, enquanto organizam metas pessoais e registram sessões de foco.

## Funcionalidades

- Feed de publicações, com comentários e curtidas.
- Perfis de usuário e recurso para seguir outras pessoas.
- Exploração de usuários e comunidades.
- Criação e acompanhamento de metas.
- Temporizador e registro de sessões de foco.
- Área de evolução para acompanhar o progresso pessoal.
- Publicação e compartilhamento de conquistas.

## Tecnologias

### Aplicativo
- Flutter e Dart.
- Material Design 3.
- `http` para comunicação com a API.
- `shared_preferences` para preferências e dados locais.
- `image_picker` e `file_picker` para seleção de imagens e arquivos.

### Backend
- Python.
- FastAPI e Uvicorn.
- SQLAlchemy e Pydantic.
- MySQL, com o driver PyMySQL.
- JWT para autenticação e Argon2 para proteção de senhas.

### Painel administrativo
O repositório também inclui um aplicativo administrativo independente para Windows, desenvolvido em C# com Windows Forms e .NET Framework 4.7.2.

## Pré-requisitos

- Flutter SDK compatível com Dart 3.11.4 ou superior.
- Python 3.10 ou superior.
- MySQL disponível e acessível.
- Docker e Docker Compose (para execução do backend em container).
- Para executar em dispositivo físico, computador e celular conectados à mesma rede local.
- Para o painel administrativo, Windows e Visual Studio com suporte a .NET Framework 4.7.2.

## Como executar

### 1. Preparar o banco de dados

Crie um banco de dados MySQL e prepare as tabelas esperadas pelo backend antes de iniciar a API. Configure as credenciais de acesso na variável `DATABASE_URL`, conforme o exemplo abaixo.

O backend não cria automaticamente todas as tabelas ao iniciar. Certifique-se de que o esquema do banco esteja preparado.

### 2. Configurar e iniciar o backend

Na raiz do repositório, entre na pasta do backend:

```bash
cd backend
```

Crie e ative um ambiente virtual.

Linux ou macOS:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Windows PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Instale as dependências:

```bash
pip install -r requirements.txt
```

Crie um arquivo `.env` dentro da pasta `backend` com as configurações do ambiente. Exemplo:

```env
DATABASE_URL=mysql+pymysql://USUARIO:SENHA@localhost:3306/pace
SECRET_KEY=defina-uma-chave-secreta
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
COOKIE_SECURE=false
COOKIE_SAMESITE=lax
```

Substitua `USUARIO`, `SENHA` e o nome do banco pelos valores do seu ambiente. Não compartilhe nem publique a chave secreta ou as credenciais.

Inicie a API:

```bash
uvicorn main:app --reload
```

A documentação interativa da API fica disponível em:

[http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

### 3. Executar o backend com Docker

O backend também pode ser executado utilizando Docker e Docker Compose, sem precisar instalar as dependências Python diretamente na máquina.

Certifique-se de que o Docker e o Docker Compose estejam instalados e em execução.

Na pasta `backend`, crie o arquivo `.env` com as configurações necessárias, conforme o exemplo apresentado na seção anterior.

Certifique-se de que o endereço configurado em `DATABASE_URL` seja acessível pelo container. Caso o MySQL esteja em outro servidor, utilize o endereço IP ou hostname desse servidor em vez de `localhost`.

Na raiz do repositório, execute:

```bash
docker compose up --build
```

Esse comando constrói a imagem do backend a partir do `Dockerfile` e inicia o container utilizando as configurações do `docker-compose.yml`.

A documentação interativa da API fica disponível em:

[http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

Para acompanhar os logs do backend:

```bash
docker compose logs -f backend
```

Para parar e remover o container:

```bash
docker compose down
```

Para iniciar novamente sem reconstruir a imagem:

```bash
docker compose up -d
```

O Docker containeriza somente o backend. O banco de dados MySQL continua sendo executado externamente, no servidor configurado em `DATABASE_URL`.

### 4. Configurar e iniciar o aplicativo Flutter

Em outro terminal, entre na pasta do aplicativo:

```bash
cd Flutter
```

Baixe as dependências:

```bash
flutter pub get
```

Confira os dispositivos disponíveis:

```bash
flutter devices
```

Inicie o aplicativo selecionando o dispositivo desejado:

```bash
flutter run -d ID_DO_DISPOSITIVO
```

Para executar em um dispositivo Android físico, o backend deve estar ativo e acessível pela rede local. Configure no aplicativo o endereço IP do computador que executa a API. O endereço Android padrão está definido como `192.168.1.8`; se o IP do computador for diferente, atualize-o na configuração da API do aplicativo. Libere também a porta 8000 no firewall, se necessário.

Em navegador e em plataformas desktop, o endereço padrão da API é `127.0.0.1:8000`.

## Executar testes e análise

Na pasta `Flutter`, os comandos abaixo verificam o código e executam os testes Flutter disponíveis:

```bash
flutter analyze
flutter test
```

## Observações

- O aplicativo e a API precisam estar em execução para que as funcionalidades conectadas ao backend funcionem.
- O uso em dispositivo físico requer que o celular e o computador estejam na mesma rede local.
- Os comandos de execução do painel administrativo dependem da configuração local do Visual Studio e do .NET Framework.
