import { useState, useEffect } from 'react'
import './App.css'

function App() {
  // 1. ESTADOS (Aquí se guardan los datos)
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState(null);
  const [newTask, setNewTask] = useState('');

  // 2. FUNCIONES PARA LLAMAR AL BACKEND

  // A. Obtener tareas (Core Service)
  const fetchTasks = async () => {
    try {
      const res = await fetch('/api/core/tasks');
      const data = await res.json();
      setTasks(data);
    } catch (err) { console.error("Error Core:", err); }
  };

  // B. Obtener estadísticas (Dashboard Service)
  const fetchStats = async () => {
    try {
      const res = await fetch('/api/stats/summary');
      const data = await res.json();
      setStats(data);
    } catch (err) { console.error("Error Stats:", err); }
  };

  // 3. EFECTO (Se ejecuta al cargar la página)
  useEffect(() => {
    fetchTasks();
    fetchStats();
  }, []);

  // 4. MANEJADORES DE EVENTOS

  // Crear Tarea
  const handleCreate = async () => {
    if (!newTask) return;
    try {
      await fetch('/api/core/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: newTask, project_id: 1 })
      });
      setNewTask(''); // Limpiar input
      fetchTasks();   // Recargar lista
      fetchStats();   // Recargar contadores
    } catch (err) { console.error("Error creating task:", err); }
  };

  // Login Simulado
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

  // 5. RENDERIZADO (Lo que se ve en pantalla)
  return (
    <div style={{ padding: '20px', maxWidth: '800px', margin: '0 auto' }}>
      <h1>🏰 TaskMaster Enterprise</h1>
      
      {/* Tarjetas de Estadísticas */}
      <div style={{ display: 'flex', gap: '20px', marginBottom: '30px', justifyContent: 'center' }}>
        <div className="card" style={{ border: '1px solid #ccc', padding: '15px', borderRadius: '8px', minWidth: '150px' }}>
          <h3>Usuarios</h3>
          <p style={{ fontSize: '2em', margin: 0 }}>{stats?.total_users || 0}</p>
          <small>(Auth Service)</small>
        </div>
        <div className="card" style={{ border: '1px solid #ccc', padding: '15px', borderRadius: '8px', minWidth: '150px' }}>
          <h3>Tareas</h3>
          <p style={{ fontSize: '2em', margin: 0 }}>{stats?.total_tasks || 0}</p>
          <small>(Dashboard Service)</small>
        </div>
      </div>

      <hr />

      {/* Sección Crear Tarea */}
      <div style={{ margin: '20px 0' }}>
        <h2>Mis Tareas (Core Service)</h2>
        <div style={{ display: 'flex', gap: '10px', justifyContent: 'center' }}>
          <input 
            value={newTask} 
            onChange={e => setNewTask(e.target.value)} 
            placeholder="Nueva tarea..." 
            style={{ padding: '10px', width: '300px' }}
          />
          <button onClick={handleCreate} style={{ padding: '10px 20px' }}>Agregar</button>
        </div>

        {/* Lista de Tareas */}
        <ul style={{ listStyle: 'none', padding: 0, marginTop: '20px' }}>
          {tasks.map(t => (
            <li key={t.id} style={{ background: '#f5f5f5', color: '#333', margin: '5px 0', padding: '10px', borderRadius: '4px', textAlign: 'left' }}>
              {t.title} - <strong>{t.status}</strong>
            </li>
          ))}
        </ul>
      </div>

      <hr />
      
      <button onClick={handleLogin} style={{ background: '#444', marginTop: '20px' }}>
        Test Login (Auth Service)
      </button>
    </div>
  )
}

export default App