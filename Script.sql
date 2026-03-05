	create table Usuarios (
	id int primary key auto_increment,
	username varchar(50) unique not null,
	senha_hash varchar(255) not null,
	email varchar(100) unique not null,
	status_conta boolean default true,
	foto_perfil varchar(500)
	);
	
	CREATE TABLE Posts (
	    id INT PRIMARY KEY AUTO_INCREMENT,
	    usuario_id INT NOT NULL,
	    conteudo TEXT NOT NULL,
	    imagem VARCHAR(255),
	    data_postagem DATETIME DEFAULT CURRENT_TIMESTAMP,
	    FOREIGN KEY (Usuario_id) REFERENCES Usuarios(id) ON DELETE CASCADE
	);
	
	
	CREATE TABLE comentarios (
	    id INT PRIMARY KEY AUTO_INCREMENT,
	    usuario_id INT NOT NULL,
	    post_id INT NOT NULL,
	    comentario TEXT NOT NULL,
	    data_comentario DATETIME DEFAULT CURRENT_TIMESTAMP,
	    FOREIGN KEY (Usuario_id) REFERENCES Usuarios(id) ON DELETE CASCADE,
	    FOREIGN KEY (Post_id) REFERENCES Posts(id)
	);
	
	
	CREATE TABLE curtidas (
	    usuario_id INT NOT NULL,
	    post_id INT NOT NULL,
	    PRIMARY KEY(usuario_id, post_id),
	    data_curtida DATETIME DEFAULT CURRENT_TIMESTAMP ,
	    FOREIGN KEY (Usuario_id) REFERENCES Usuarios(id) ON DELETE CASCADE,
	    FOREIGN KEY (Post_id) REFERENCES Posts(id)
	);
	
	
	
	
	CREATE TABLE seguidores (
	    seguidor_id INT NOT NULL,
	    seguindo_id INT NOT NULL,
	    PRIMARY KEY(seguidor_id, seguindo_id),
	    CHECK (seguidor_id <> seguindo_id),
	    data_follow DATETIME DEFAULT CURRENT_TIMESTAMP,
	    FOREIGN KEY (seguidor_id) REFERENCES Usuarios(id) ON DELETE CASCADE,
	    FOREIGN KEY (seguindo_id) REFERENCES Usuarios(id) ON DELETE CASCADE
	);	
	
