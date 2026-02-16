const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

app.get('/summary', async (req, res) => {
    const tasks = await pool.query('SELECT COUNT(*) FROM core.tasks');
    const users = await pool.query('SELECT COUNT(*) FROM auth.users');
    res.json({ total_tasks: tasks.rows[0].count, total_users: users.rows[0].count });
});

app.listen(3003, () => console.log('Dashboard Service running on 3003'));