const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Conexión a Base de Datos (Usa la variable de entorno de Docker Compose)
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// --- ENDPOINT 1: LOGIN ---
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    try {
        // Buscamos usuario en el esquema 'auth'
        const result = await pool.query(
            'SELECT * FROM auth.users WHERE username = $1 AND password = $2', 
            [username, password]
        );
        
        if (result.rows.length > 0) {
            // Login Exitoso: Devolvemos un token falso (mock) y datos del usuario
            res.json({ 
                token: 'mock-jwt-' + Date.now(), 
                user: result.rows[0] 
            });
        } else {
            // Login Fallido
            res.status(401).json({ error: 'Credenciales incorrectas' });
        }
    } catch (e) { 
        console.error(e);
        res.status(500).json({ error: e.message }); 
    }
});

// --- ENDPOINT 2: REGISTRO (NUEVO) ---
app.post('/register', async (req, res) => {
    const { username, password } = req.body;
    try {
        // Insertamos el nuevo usuario en la tabla
        // 'RETURNING *' hace que Postgres nos devuelva el dato recién creado
        const result = await pool.query(
            'INSERT INTO auth.users (username, password, role) VALUES ($1, $2, $3) RETURNING *',
            [username, password, 'user'] // Rol por defecto 'user'
        );
        
        res.json({ 
            message: 'Usuario registrado exitosamente', 
            user: result.rows[0] 
        });
    } catch (e) {
        console.error(e);
        // Si el error es por duplicado (código 23505 en Postgres), avisamos
        res.status(400).json({ error: 'El usuario ya existe o hubo un error en la base de datos' });
    }
});

// Iniciar Servidor
const PORT = 3001;
app.listen(PORT, () => console.log(`Auth Service running on port ${PORT}`));