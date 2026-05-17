# Pace - Ecossistema de Evolução Pessoal

O **Pace** é uma solução multiplataforma composta por uma API robusta, um aplicativo móvel e uma interface web, projetada para ajudar usuários a cultivarem disciplina, foco e organização através de uma comunidade engajada.

## 🏗️ Arquitetura do Projeto

O projeto segue um modelo de arquitetura cliente-servidor, onde múltiplos clientes (Mobile e Web) consomem uma única API REST centralizada.

- **[Backend](./backend/):** API desenvolvida com FastAPI (Python), utilizando SQLAlchemy para persistência em MySQL e JWT para autenticação.
- **[Mobile](./Flutter/):** Aplicativo desenvolvido em Flutter (Dart) para Android e iOS, focado em mobilidade e interatividade.
- **[Web Frontend](./Front-End/):** Interface web responsiva construída com HTML5, CSS3 e JavaScript puro, focada em simplicidade e performance.

## 🚀 Como Iniciar

### Pré-requisitos
- **Python 3.10+** (para o Backend)
- **Flutter SDK** (para o App Mobile)
- **MySQL** (para o banco de dados)
- **Navegador moderno** (para a Web)

### Guia Rápido
1. **Banco de Dados:** Execute o script `Script.sql` no seu servidor MySQL para criar a estrutura das tabelas.
2. **Backend:** Siga as instruções no [README do Backend](./backend/README.md) para configurar o `.env` e rodar a API.
3. **Frontend Web:** Abra o arquivo `Front-End/Html/index.html` ou use um servidor estático.
4. **App Mobile:** Siga o [README do Flutter](./Flutter/README.md) para instalar dependências e rodar no emulador.

## 📊 Análise Técnica

Como parte da governança do projeto, foram gerados relatórios detalhados sobre a qualidade do código e arquitetura:

- 📝 **[ANALISE.md](./ANALISE.md):** Uma visão crítica sobre segurança, escalabilidade e manutenibilidade.
- 🏆 **[NOTA.md](./NOTA.md):** Avaliação quantitativa de cada módulo do sistema.

## 🛠️ Tecnologias Principais

- **Linguagens:** Python, Dart, JavaScript, SQL.
- **Frameworks:** FastAPI, Flutter.
- **Segurança:** Argon2, JWT, Bearer Auth.
- **Estilização:** CSS3 Moderno, Material Design.

---
*Este projeto foi analisado e documentado com foco em padrões de arquitetura de software de alto nível.*
