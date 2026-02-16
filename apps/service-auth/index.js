const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    try {
        const result = await pool.query('SELECT * FROM auth.users WHERE username = $1 AND password = $2', [username, password]);
        if (result.rows.length > 0) res.json({ token: 'mock-jwt-123', user: result.rows[0] });
        else res.status(401).json({ error: 'Credenciales incorrectas' });
    } catch (e) { res.status(500).json({ error: e.message }); }
});

app.listen(3001, () => console.log('Auth Service running on 3001'));