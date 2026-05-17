# Pace Backend - FastAPI API

Este é o servidor backend do projeto Pace, construído com FastAPI. Ele fornece serviços de autenticação, gerenciamento de posts, comentários e perfis de usuários.

## 🛠️ Tecnologias
- **FastAPI**: Framework web moderno e rápido.
- **SQLAlchemy**: ORM para comunicação com o banco de dados.
- **PyMySQL**: Driver para MySQL.
- **JWT (JSON Web Tokens)**: Autenticação segura.
- **Argon2 (via pwdlib)**: Hashing de senhas de última geração.

## 📁 Estrutura do Projeto
- `main.py`: Ponto de entrada da aplicação e configuração de CORS.
- `auth.py`: Rotas de autenticação (cadastro, login, troca de senha).
- `models.py`: Definições das tabelas do banco de dados.
- `schemas.py`: Modelos Pydantic para validação de dados.
- `database.py`: Configuração da conexão com o banco de dados.
- `dependencies.py`: Injeção de dependência para sessões de DB e usuário atual.

## 🚀 Como Rodar
1. Instale as dependências: `pip install -r requirements.txt`
2. Configure o arquivo `.env` com sua `DATABASE_URL` e `SECRET_KEY`.
3. Inicie o servidor: `uvicorn main:app --reload`

## 🔒 Segurança
- Autenticação baseada em Bearer Tokens (JWT).
- Hashing de senhas com Argon2.
- Validação rigorosa de dados com Pydantic.
