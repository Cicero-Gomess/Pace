# Pace Web - Frontend Estático

Interface web para o projeto Pace, desenvolvida com tecnologias web fundamentais para máxima performance e compatibilidade.

## 🛠️ Tecnologias
- **HTML5**: Estruturação semântica das páginas.
- **CSS3**: Estilização moderna com variáveis e layouts flexíveis.
- **JavaScript (Vanilla)**: Lógica de frontend e integração com a API usando `fetch`.
- **Lucide Icons**: Conjunto de ícones leves e elegantes.

## 📁 Estrutura
- `Html/`: Contém as páginas do sistema (index, feed, perfil, etc).
- `Css/`: Estilos específicos para cada página e folha de base.
- `JavaScript/`: Lógica para autenticação, manipulação do DOM e chamadas de API.
- `Images/`: Assets visuais do projeto.

## 🚀 Como Rodar
Como o frontend é composto por arquivos estáticos, basta abrir qualquer arquivo `.html` em um navegador. Para evitar problemas de CORS e caminhos, recomenda-se usar a extensão "Live Server" no VS Code ou qualquer servidor HTTP simples.

## 🔗 Integração
A comunicação é feita diretamente com a API FastAPI através de requisições assíncronas (AJAX) para o endpoint `http://localhost:8000`.
