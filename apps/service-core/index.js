const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

app.get('/tasks', async (req, res) => {
    const result = await pool.query('SELECT * FROM core.tasks');
    res.json(result.rows);
});

app.post('/tasks', async (req, res) => {
    const { title, project_id } = req.body;
    const result = await pool.query('INSERT INTO core.tasks (title, project_id) VALUES ($1, $2) RETURNING *', [title, project_id]);
    res.json(result.rows[0]);
});

app.listen(3002, () => console.log('Core Service running on 3002'));