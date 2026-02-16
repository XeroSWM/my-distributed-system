import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

function Dashboard() {
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState(null);
  const [newTask, setNewTask] = useState('');
  const navigate = useNavigate();

  // 1. Función para cargar datos (Reutilizable)
  const loadData = async () => {
    try {
      // Cargar Tareas
      const resTasks = await fetch('/api/core/tasks');
      if (resTasks.ok) {
        const dataTasks = await resTasks.json();
        setTasks(dataTasks);
      }

      // Cargar Estadísticas
      const resStats = await fetch('/api/stats/summary');
      if (resStats.ok) {
        const dataStats = await resStats.json();
        setStats(dataStats);
      }
    } catch (err) { console.error(err); }
  };

  // 2. EFECTO PRINCIPAL (Protección y Carga)
  useEffect(() => {
    const token = localStorage.getItem('token');
    
    // Si no hay token, lo mandamos al Login inmediatamente
    if (!token) {
      navigate('/');
      return;
    }

    // Si hay token, cargamos los datos
    loadData();
    
    // La siguiente línea desactiva la advertencia roja del editor:
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [navigate]); 

  // 3. Crear Tarea
  const handleCreate = async () => {
    if (!newTask) return;
    try {
      await fetch('/api/core/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: newTask, project_id: 1 })
      });
      setNewTask('');
      loadData(); // Recargar datos
    } catch (error) { console.error(error); }
  };

  // 4. Cerrar Sesión
  const handleLogout = () => {
    localStorage.removeItem('token'); // Borrar token
    navigate('/'); // Ir al login
  };

  return (
    <div style={{ padding: '20px', maxWidth: '800px', margin: '0 auto' }}>
      {/* Encabezado */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' }}>
        <h1>🏰 Dashboard Principal</h1>
        <button 
          onClick={handleLogout} 
          style={{ background: '#dc3545', color: 'white', border: 'none', padding: '10px 20px', cursor: 'pointer', borderRadius: '5px' }}
        >
          Cerrar Sesión
        </button>
      </div>
      
      {/* Tarjetas de Resumen */}
      <div style={{ display: 'flex', gap: '20px', marginBottom: '30px' }}>
        <div className="card" style={{ padding: '20px', border: '1px solid #444', borderRadius: '8px', minWidth: '150px' }}>
          <h3>Usuarios</h3>
          <p style={{ fontSize: '24px', margin: '10px 0' }}>{stats?.total_users || 0}</p>
        </div>
        <div className="card" style={{ padding: '20px', border: '1px solid #444', borderRadius: '8px', minWidth: '150px' }}>
          <h3>Tareas</h3>
          <p style={{ fontSize: '24px', margin: '10px 0' }}>{stats?.total_tasks || 0}</p>
        </div>
      </div>

      <hr style={{ borderColor: '#444' }} />

      {/* Lista de Tareas */}
      <div style={{ marginTop: '20px' }}>
        <h2>Mis Tareas</h2>
        <div style={{ display: 'flex', gap: '10px', marginBottom: '20px' }}>
          <input 
            value={newTask} 
            onChange={e => setNewTask(e.target.value)} 
            placeholder="Nueva tarea..." 
            style={{ padding: '10px', flex: 1, borderRadius: '5px', border: '1px solid #666' }}
          />
          <button onClick={handleCreate} style={{ padding: '10px 20px', cursor: 'pointer' }}>Agregar</button>
        </div>
        <ul style={{ padding: 0 }}>
          {tasks.map(t => (
            <li key={t.id} style={{ listStyle: 'none', background: '#2a2a2a', padding: '15px', margin: '10px 0', borderRadius: '5px', display: 'flex', justifyContent: 'space-between' }}>
              <span>{t.title}</span>
              <strong style={{ color: '#4caf50' }}>{t.status}</strong>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

export default Dashboard;