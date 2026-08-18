-- =========================================
-- USUÁRIOS
-- =========================================

CREATE TABLE Usuarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    status_conta BOOLEAN DEFAULT TRUE,
    foto_perfil VARCHAR(500),
    admin BOOLEAN NOT NULL DEFAULT FALSE
);


-- =========================================
-- POSTS
-- =========================================

CREATE TABLE Posts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT NOT NULL,
    conteudo TEXT NOT NULL,
    imagem TEXT,
    data_postagem DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_posts_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES Usuarios(id)
        ON DELETE CASCADE
);


-- =========================================
-- COMENTÁRIOS
-- =========================================

CREATE TABLE comentarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT NOT NULL,
    post_id INT NOT NULL,
    comentario TEXT NOT NULL,
    data_comentario DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_comentarios_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES Usuarios(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_comentarios_post
        FOREIGN KEY (post_id)
        REFERENCES Posts(id)
);


-- =========================================
-- CURTIDAS
-- =========================================

CREATE TABLE curtidas (
    usuario_id INT NOT NULL,
    post_id INT NOT NULL,
    data_curtida DATETIME DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (usuario_id, post_id),

    CONSTRAINT fk_curtidas_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES Usuarios(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_curtidas_post
        FOREIGN KEY (post_id)
        REFERENCES Posts(id)
);


-- =========================================
-- SEGUIDORES
-- =========================================

CREATE TABLE seguidores (
    seguidor_id INT NOT NULL,
    seguindo_id INT NOT NULL,
    data_follow DATETIME DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (seguidor_id, seguindo_id),

    CONSTRAINT fk_seguidores_seguidor
        FOREIGN KEY (seguidor_id)
        REFERENCES Usuarios(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_seguidores_seguindo
        FOREIGN KEY (seguindo_id)
        REFERENCES Usuarios(id)
        ON DELETE CASCADE,

    CONSTRAINT check_self_follow
        CHECK (seguidor_id <> seguindo_id)
);


-- =========================================
-- METAS
-- =========================================

CREATE TABLE Metas (
    id INT PRIMARY KEY AUTO_INCREMENT,

    id_usuario INT NOT NULL,

    titulo VARCHAR(100) NOT NULL,

    prazo DATE,

    categoria ENUM(
        'Pessoal',
        'Estudos',
        'Trabalho',
        'Saúde',
        'Projeto',
        'Outro'
    ) NOT NULL,

    descricao VARCHAR(200),

    status ENUM(
        'concluida',
        'em andamento'
    ) NOT NULL DEFAULT 'em andamento',

    CONSTRAINT fk_metas_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES Usuarios(id)
        ON DELETE CASCADE
);


-- =========================================
-- SESSÕES
-- =========================================

CREATE TABLE Sessoes (
    id INT PRIMARY KEY AUTO_INCREMENT,

    id_meta INT NOT NULL,

    inicio DATETIME NOT NULL,

    -- Duração armazenada em segundos
    duracao INT NOT NULL,

    CONSTRAINT fk_sessoes_meta
        FOREIGN KEY (id_meta)
        REFERENCES Metas(id)
        ON DELETE CASCADE,

    CONSTRAINT check_duracao_positiva
        CHECK (duracao > 0)
);