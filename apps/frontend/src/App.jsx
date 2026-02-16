import { useState, useEffect, useCallback } from 'react'
import './App.css'

function App() {
  // 1. ESTADOS
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState(null);
  const [newTask, setNewTask] = useState('');

  // 2. FUNCIONES SEGURAS (Usando useCallback para evitar errores del Linter)
  
  // A. Obtener tareas
  const fetchTasks = useCallback(async () => {
    try {
      const res = await fetch('/api/core/tasks');
      const data = await res.json();
      setTasks(data);
    } catch (err) { console.error("Error Core:", err); }
  }, []);

  // B. Obtener estadísticas
  const fetchStats = useCallback(async () => {
    try {
      const res = await fetch('/api/stats/summary');
      const data = await res.json();
      setStats(data);
    } catch (err) { console.error("Error Stats:", err); }
  }, []);

  // 3. EFECTO DE CARGA INICIAL
  // Ahora incluimos las funciones en el array [ ] y React será feliz
  useEffect(() => {
    fetchTasks();
    fetchStats();
  }, [fetchTasks, fetchStats]);

  // 4. HANDLERS (Eventos del usuario)
  const handleCreate = async () => {
    if (!newTask) return;
    try {
      await fetch('/api/core/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: newTask, project_id: 1 })
      });
      setNewTask(''); 
      // Recargamos los datos
      fetchTasks();
      fetchStats();
    } catch (err) { console.error("Error creating task:", err); }
  };

  const handleLogin = async () => {
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: 'admin', password: 'admin123' })
      });
      const data = await res.json();
      alert(data.token ? "Login Exitoso: " + data.token : "Error Login");
    } catch (err) { console.error("Error Login:", err); }
  };

  // 5. RENDERIZADO
  return (
    <div style={{ padding: '20px' }}>
      <h1>🏰 TaskMaster Enterprise</h1>
      
      {/* TARJETAS DE MÉTRICAS */}
      <div style={{ display: 'flex', gap: '20px', marginBottom: '20px' }}>
        <div className="card" style={{border: '1px solid #ccc', padding: '10px'}}>
          <h3>Usuarios</h3>
          <p>{stats?.total_users || 0}</p>
        </div>
        <div className="card" style={{border: '1px solid #ccc', padding: '10px'}}>
          <h3>Tareas</h3>
          <p>{stats?.total_tasks || 0}</p>
        </div>
      </div>

      <hr />

      {/* GESTIÓN DE TAREAS */}
      <div>
        <h2>Mis Tareas</h2>
        <div style={{ marginBottom: '10px' }}>
          <input 
            value={newTask} 
            onChange={e => setNewTask(e.target.value)} 
            placeholder="Nueva tarea..." 
          />
          <button onClick={handleCreate}>Agregar</button>
        </div>
        <ul>
          {tasks.map(t => (
            <li key={t.id}>{t.title} - <strong>{t.status}</strong></li>
          ))}
        </ul>
      </div>

      <hr />
      
      <button onClick={handleLogin} style={{background: '#333', color: 'white', marginTop: '20px'}}>
        Test Login
      </button>
    </div>
  )
}

export default App