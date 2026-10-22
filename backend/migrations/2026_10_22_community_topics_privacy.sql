-- Run once for databases where comunidades and membros_comunidade already exist.
ALTER TABLE comunidades
    ADD COLUMN topicos JSON NULL,
    ADD COLUMN privacidade VARCHAR(10) NOT NULL DEFAULT 'publica';

UPDATE comunidades
SET topicos = JSON_ARRAY()
WHERE topicos IS NULL;

ALTER TABLE comunidades
    MODIFY COLUMN topicos JSON NOT NULL,
    ADD CONSTRAINT check_comunidade_privacidade
        CHECK (privacidade IN ('publica', 'privada'));

INSERT IGNORE INTO membros_comunidade (comunidade_id, usuario_id, cargo)
SELECT id, criador_id, 'admin'
FROM comunidades;
