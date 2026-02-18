import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

function Register() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate();

  const handleRegister = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch(`${import.meta.env.VITE_AUTH_URL}/api/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });
      const data = await res.json();
      if (res.ok) {
        alert('¡Cuenta creada! Inicia sesión.');
        navigate('/');
      } else {
        alert('Error: ' + (data.error || 'Error al registrar'));
      }
    } catch (err) { console.error(err); alert('Error de conexión'); }
  };

  // Reutilizamos los estilos del Login para consistencia
  const styles = {
    container: {
      minHeight: '100vh',
      width: '100vw',
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: '#121212',
      color: '#e0e0e0',
      fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif"
    },
    card: {
      backgroundColor: '#1e1e1e',
      padding: '40px',
      borderRadius: '16px',
      boxShadow: '0 8px 32px rgba(0, 0, 0, 0.6)',
      width: '100%',
      maxWidth: '420px',
      textAlign: 'center',
      border: '1px solid #333'
    },
    title: { marginBottom: '30px', fontSize: '28px', color: '#ffffff', fontWeight: '600' },
    form: { display: 'flex', flexDirection: 'column', gap: '20px' },
    input: {
      width: '100%', padding: '14px', borderRadius: '8px', border: '1px solid #444',
      backgroundColor: '#2c2c2c', color: 'white', fontSize: '16px', outline: 'none', boxSizing: 'border-box'
    },
    button: {
      width: '100%', padding: '14px', backgroundColor: '#10b981', // Verde esmeralda para registro
      color: 'white', border: 'none', borderRadius: '8px', fontSize: '16px',
      fontWeight: 'bold', cursor: 'pointer', marginTop: '10px'
    },
    footer: { marginTop: '25px', fontSize: '14px', color: '#aaa' },
    link: { background: 'none', border: 'none', color: '#60a5fa', cursor: 'pointer', textDecoration: 'underline', marginLeft: '5px' }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>📝 Nueva Cuenta</h1>
        
        <form onSubmit={handleRegister} style={styles.form}>
          <input 
            type="text" 
            placeholder="Elige tu Usuario" 
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            style={styles.input}
          />
          <input 
            type="password" 
            placeholder="Elige tu Contraseña" 
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            style={styles.input}
          />
          
          <button type="submit" style={styles.button}>
            CREAR CUENTA
          </button>
        </form>

        <div style={styles.footer}>
          <span>¿Ya tienes cuenta?</span>
          <button onClick={() => navigate('/')} style={styles.link}>
            Inicia Sesión
          </button>
        </div>
      </div>
    </div>
  );
}

export default Register;