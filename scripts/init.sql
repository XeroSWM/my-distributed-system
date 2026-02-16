-- scripts/init.sql

-- 1. Esquema de Autenticación
CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE auth.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- En producción usar bcrypt
    role VARCHAR(20) DEFAULT 'user'
);

INSERT INTO auth.users (username, password, role) VALUES ('admin', 'admin123', 'admin');
INSERT INTO auth.users (username, password, role) VALUES ('dev', 'dev123', 'developer');

-- 2. Esquema Core (Proyectos y Tareas)
CREATE SCHEMA IF NOT EXISTS core;

CREATE TABLE core.projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE core.tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, in_progress, done
    project_id INT REFERENCES core.projects(id),
    assigned_to INT -- Referencia lógica a auth.users
);

-- Datos de prueba
INSERT INTO core.projects (name, description) VALUES ('Migración Cloud', 'Pasar todo a AWS');
INSERT INTO core.tasks (title, project_id, assigned_to) VALUES ('Configurar VPC', 1, 1);
INSERT INTO core.tasks (title, project_id, assigned_to) VALUES ('Crear Dockerfile', 1, 2);