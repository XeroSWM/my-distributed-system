import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

function Login() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });
      const data = await res.json();
      if (res.ok && data.token) {
        localStorage.setItem('token', data.token);
        navigate('/dashboard');
      } else {
        alert('Error: ' + (data.error || 'Credenciales incorrectas'));
      }
    } catch (err) { console.error(err); alert('Error de conexión'); }
  };

  // --- ESTILOS MEJORADOS ---
  const styles = {
    container: {
      minHeight: '100vh',
      width: '100vw',
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: '#121212', // Negro profundo
      color: '#e0e0e0',
      fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif"
    },
    card: {
      backgroundColor: '#1e1e1e', // Gris oscuro elegante
      padding: '40px',
      borderRadius: '16px',
      boxShadow: '0 8px 32px rgba(0, 0, 0, 0.6)',
      width: '100%',
      maxWidth: '420px', // Un poco más ancho para que no se rompa el texto
      textAlign: 'center',
      border: '1px solid #333'
    },
    title: {
      marginBottom: '30px',
      fontSize: '28px',
      fontWeight: '600',
      color: '#ffffff',
      letterSpacing: '1px'
    },
    form: {
      display: 'flex',
      flexDirection: 'column',
      gap: '20px'
    },
    input: {
      width: '100%',
      padding: '14px',
      borderRadius: '8px',
      border: '1px solid #444',
      backgroundColor: '#2c2c2c',
      color: 'white',
      fontSize: '16px',
      outline: 'none',
      boxSizing: 'border-box' // Importante para que el padding no rompa el ancho
    },
    button: {
      width: '100%',
      padding: '14px',
      backgroundColor: '#3b82f6', // Azul moderno
      color: 'white',
      border: 'none',
      borderRadius: '8px',
      fontSize: '16px',
      fontWeight: 'bold',
      cursor: 'pointer',
      marginTop: '10px',
      transition: 'background 0.2s'
    },
    footer: {
      marginTop: '25px',
      fontSize: '14px',
      color: '#aaa'
    },
    link: {
      background: 'none',
      border: 'none',
      color: '#60a5fa',
      cursor: 'pointer',
      textDecoration: 'underline',
      fontSize: '14px',
      marginLeft: '5px'
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>🔐 Iniciar Sesión</h1>
        
        <form onSubmit={handleLogin} style={styles.form}>
          <input 
            type="text" 
            placeholder="Usuario" 
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            style={styles.input}
          />
          <input 
            type="password" 
            placeholder="Contraseña" 
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            style={styles.input}
          />
          
          <button 
            type="submit" 
            style={styles.button}
            onMouseOver={(e) => e.target.style.backgroundColor = '#2563eb'}
            onMouseOut={(e) => e.target.style.backgroundColor = '#3b82f6'}
          >
            INGRESAR
          </button>
        </form>

        <div style={styles.footer}>
          <span>¿No tienes cuenta?</span>
          <button onClick={() => navigate('/register')} style={styles.link}>
            Regístrate aquí
          </button>
        </div>
      </div>
    </div>
  );
}

export default Login;