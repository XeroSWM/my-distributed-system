import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Register from './pages/Register'; // <--- IMPORTANTE: Importar el archivo

import './App.css';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Ruta para el Login */}
        <Route path="/" element={<Login />} />
        
        {/* Ruta para el Registro (ESTA ES LA QUE TE FALTA) */}
        <Route path="/register" element={<Register />} />
        
        {/* Ruta para el Dashboard */}
        <Route path="/dashboard" element={<Dashboard />} />
        
        {/* Si la ruta no existe, mandar al Login */}
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;