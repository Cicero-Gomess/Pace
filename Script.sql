USE cl204219;

-- =========================================================
-- PADRONIZAÇÃO DOS NOMES
-- =========================================================

RENAME TABLE Usuarios TO usuarios;
RENAME TABLE Posts TO posts;
RENAME TABLE Metas TO metas;
RENAME TABLE Sessoes TO sessoes;


-- =========================================================
-- PADRONIZAÇÃO DAS COLUNAS
-- =========================================================

ALTER TABLE usuarios
CHANGE COLUMN username nome_usuario VARCHAR(50) NOT NULL;

ALTER TABLE metas
CHANGE COLUMN id_usuario usuario_id INT NOT NULL;

ALTER TABLE sessoes
CHANGE COLUMN id_meta meta_id INT NOT NULL;

ALTER TABLE seguidores
CHANGE COLUMN data_follow data_seguimento DATETIME
DEFAULT CURRENT_TIMESTAMP;


-- =========================================================
-- AJUSTE DAS FOREIGN KEYS DE COMENTÁRIOS
-- =========================================================

-- A FK original criada automaticamente pelo MySQL
-- era comentarios_ibfk_2.

ALTER TABLE comentarios
DROP FOREIGN KEY comentarios_ibfk_2;

ALTER TABLE comentarios
ADD CONSTRAINT fk_comentarios_post
FOREIGN KEY (post_id)
REFERENCES posts(id)
ON DELETE CASCADE;


-- =========================================================
-- AJUSTE DAS FOREIGN KEYS DE CURTIDAS
-- =========================================================

-- A FK original criada automaticamente pelo MySQL
-- era curtidas_ibfk_2.

ALTER TABLE curtidas
DROP FOREIGN KEY curtidas_ibfk_2;

ALTER TABLE curtidas
ADD CONSTRAINT fk_curtidas_post
FOREIGN KEY (post_id)
REFERENCES posts(id)
ON DELETE CASCADE;


-- =========================================================
-- COMUNIDADES
-- =========================================================

CREATE TABLE comunidades (
    id INT PRIMARY KEY AUTO_INCREMENT,

    criador_id INT NOT NULL,

    nome VARCHAR(100) NOT NULL,

    descricao VARCHAR(500),

    imagem VARCHAR(500),

    data_criacao DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    ativa BOOLEAN NOT NULL
        DEFAULT TRUE,

    CONSTRAINT uq_comunidades_nome
        UNIQUE (nome),

    CONSTRAINT fk_comunidades_criador
        FOREIGN KEY (criador_id)
        REFERENCES usuarios(id)
        ON DELETE CASCADE
);


-- =========================================================
-- MEMBROS DAS COMUNIDADES
-- =========================================================

CREATE TABLE membros_comunidade (
    comunidade_id INT NOT NULL,

    usuario_id INT NOT NULL,

    cargo ENUM(
        'membro',
        'moderador',
        'admin'
    ) NOT NULL DEFAULT 'membro',

    data_entrada DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (
        comunidade_id,
        usuario_id
    ),

    CONSTRAINT fk_membros_comunidade
        FOREIGN KEY (comunidade_id)
        REFERENCES comunidades(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_membros_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(id)
        ON DELETE CASCADE
);


-- =========================================================
-- POSTS EM COMUNIDADES
-- =========================================================

ALTER TABLE posts
ADD COLUMN comunidade_id INT NULL;

ALTER TABLE posts
ADD CONSTRAINT fk_posts_comunidade
FOREIGN KEY (comunidade_id)
REFERENCES comunidades(id)
ON DELETE CASCADE;


-- comunidade_id NULL
--     -> publicação no Feed Geral
--
-- comunidade_id preenchido
--     -> publicação dentro de uma comunidade


-- =========================================================
-- ÍNDICES
-- =========================================================

CREATE INDEX idx_posts_usuario
ON posts(usuario_id);

CREATE INDEX idx_posts_comunidade
ON posts(comunidade_id);

CREATE INDEX idx_comunidades_criador
ON comunidades(criador_id);

CREATE INDEX idx_membros_usuario
ON membros_comunidade(usuario_id);


-- Não criamos novamente:
--
-- idx_comentarios_post
-- idx_curtidas_post
--
-- porque o MySQL já possuía índices equivalentes
-- para essas foreign keys.


-- =========================================================
-- ESTRUTURA RESULTANTE PRINCIPAL
-- =========================================================

-- usuarios
-- posts
-- comentarios
-- curtidas
-- seguidores
-- metas
-- sessoes
-- comunidades
-- membros_comunidade