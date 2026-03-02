use cl204219;


create table Usuario (
id int primary key auto_increment,
username varchar(50) unique not null,
senha_hash varchar(255) not null,
email varchar(100) unique not null,
status_conta boolean default true,
foto_perfil varchar(500)
);


CREATE TABLE comentarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT,
    post_id INT,
    comentario TEXT,
    data_comentario DATETIME,
    FOREIGN KEY (Usuario_id) REFERENCES Usuario(id),
    FOREIGN KEY (Post_id) REFERENCES Posts(id)
);


CREATE TABLE curtidas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT,
    post_id INT,
    data_curtida DATETIME,
    FOREIGN KEY (Usuario_id) REFERENCES Usuario(id),
    FOREIGN KEY (Post_id) REFERENCES Posts(id)
);


CREATE TABLE Posts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT,
    conteudo TEXT,
    imagem VARCHAR(255),
    data_postagem DATETIME,
    FOREIGN KEY (Usuario_id) REFERENCES Usuario(id)
);

CREATE TABLE seguidores (
    id INT PRIMARY KEY AUTO_INCREMENT,
    seguidor_id INT,
    seguindo_id INT,
    data_follow DATETIME,
    FOREIGN KEY (seguidor_id) REFERENCES Usuario(id),
    FOREIGN KEY (seguindo_id) REFERENCES Usuario(id)
);	

