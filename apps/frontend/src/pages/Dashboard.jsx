import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';

function Dashboard() {
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState({ total_users: 0, total_tasks: 0 }); // Inicializamos con 0 para evitar errores
  const [newTask, setNewTask] = useState('');
  const navigate = useNavigate();

  // 1. Función para cargar datos (Memoizada con useCallback para evitar warnings)
  const loadData = useCallback(async () => {
    const token = localStorage.getItem('token');
    if (!token) return;

    // Headers con el Token (Vital para seguridad)
    const authHeaders = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    };

    try {
      // --- CARGAR TAREAS (Desde Servicio Core) ---
      // Usamos la variable de entorno que Terraform inyectó
      // Nota: VITE_CORE_URL ya incluye "http://IP/api/core"
      const resTasks = await fetch(`${import.meta.env.VITE_CORE_URL}/tasks`, { 
        headers: authHeaders 
      });
      
      if (resTasks.ok) {
        const dataTasks = await resTasks.json();
        setTasks(dataTasks);
      } else if (resTasks.status === 401) {
        // Si el token venció, cerrar sesión
        handleLogout();
        return;
      }

      // --- CARGAR ESTADÍSTICAS (Desde Servicio Dashboard) ---
      // Nota: VITE_DASHBOARD_URL ya incluye "http://IP/api/dashboard"
      const resStats = await fetch(`${import.meta.env.VITE_DASHBOARD_URL}/summary`, { 
        headers: authHeaders 
      });

      if (resStats.ok) {
        const dataStats = await resStats.json();
        setStats(dataStats);
      }
    } catch (err) { 
      console.error("Error cargando dashboard:", err); 
    }
  }, []); // Dependencias vacías porque usamos funciones estables

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
  }, [navigate, loadData]); 

  // 3. Crear Tarea
  const handleCreate = async () => {
    if (!newTask) return;
    const token = localStorage.getItem('token');

    try {
      const res = await fetch(`${import.meta.env.VITE_CORE_URL}/tasks`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}` // ¡No olvides el token aquí también!
        },
        body: JSON.stringify({ title: newTask, project_id: 1 })
      });

      if (res.ok) {
        setNewTask('');
        loadData(); // Recargar datos para ver la nueva tarea
      } else {
        alert('Error al crear tarea');
      }
    } catch (error) { console.error(error); }
  };

  // 4. Cerrar Sesión
  const handleLogout = () => {
    localStorage.removeItem('token'); // Borrar token
    navigate('/'); // Ir al login
  };

  return (
    <div style={{ padding: '20px', maxWidth: '800px', margin: '0 auto', color: '#e0e0e0', fontFamily: 'sans-serif' }}>
      {/* Encabezado */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' }}>
        <h1 style={{ color: 'white' }}>🏰 Dashboard Principal</h1>
        <button 
          onClick={handleLogout} 
          style={{ background: '#dc3545', color: 'white', border: 'none', padding: '10px 20px', cursor: 'pointer', borderRadius: '5px', fontWeight: 'bold' }}
        >
          Cerrar Sesión
        </button>
      </div>
      
      {/* Tarjetas de Resumen */}
      <div style={{ display: 'flex', gap: '20px', marginBottom: '30px', flexWrap: 'wrap' }}>
        <div className="card" style={{ padding: '20px', background: '#1e1e1e', border: '1px solid #333', borderRadius: '12px', minWidth: '150px', flex: 1, boxShadow: '0 4px 6px rgba(0,0,0,0.3)' }}>
          <h3 style={{ margin: '0 0 10px 0', color: '#aaa' }}>Usuarios</h3>
          <p style={{ fontSize: '32px', margin: '0', fontWeight: 'bold', color: '#60a5fa' }}>{stats?.total_users || 0}</p>
        </div>
        <div className="card" style={{ padding: '20px', background: '#1e1e1e', border: '1px solid #333', borderRadius: '12px', minWidth: '150px', flex: 1, boxShadow: '0 4px 6px rgba(0,0,0,0.3)' }}>
          <h3 style={{ margin: '0 0 10px 0', color: '#aaa' }}>Tareas</h3>
          <p style={{ fontSize: '32px', margin: '0', fontWeight: 'bold', color: '#34d399' }}>{stats?.total_tasks || 0}</p>
        </div>
      </div>

      <hr style={{ borderColor: '#333', margin: '30px 0' }} />

      {/* Lista de Tareas */}
      <div style={{ marginTop: '20px' }}>
        <h2 style={{ color: 'white' }}>Mis Tareas</h2>
        <div style={{ display: 'flex', gap: '10px', marginBottom: '20px' }}>
          <input 
            value={newTask} 
            onChange={e => setNewTask(e.target.value)} 
            placeholder="Escribe una nueva tarea..." 
            style={{ padding: '14px', flex: 1, borderRadius: '8px', border: '1px solid #444', background: '#2c2c2c', color: 'white', outline: 'none' }}
          />
          <button 
            onClick={handleCreate} 
            style={{ padding: '14px 24px', cursor: 'pointer', background: '#3b82f6', color: 'white', border: 'none', borderRadius: '8px', fontWeight: 'bold' }}
          >
            Agregar
          </button>
        </div>
        
        <ul style={{ padding: 0 }}>
          {tasks.length === 0 && <p style={{ color: '#666', fontStyle: 'italic' }}>No hay tareas pendientes.</p>}
          {tasks.map(t => (
            <li key={t.id} style={{ listStyle: 'none', background: '#1e1e1e', padding: '15px 20px', margin: '10px 0', borderRadius: '8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', border: '1px solid #333' }}>
              <span style={{ fontSize: '16px' }}>{t.title}</span>
              <span style={{ 
                color: t.status === 'DONE' ? '#34d399' : '#fbbf24', 
                background: t.status === 'DONE' ? 'rgba(52, 211, 153, 0.1)' : 'rgba(251, 191, 36, 0.1)',
                padding: '4px 12px',
                borderRadius: '20px',
                fontSize: '12px',
                fontWeight: 'bold'
              }}>
                {t.status || 'PENDING'}
              </span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

export default Dashboard;