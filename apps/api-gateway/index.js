const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8000;

// 1. Configuración CORS Global (Permite que el Frontend hable con el Gateway)
app.use(cors());

// 2. Health Check (Para ver si el Gateway vive)
app.get('/health', (req, res) => res.send('API Gateway is running'));

// 3. Definir Rutas y Proxies
// Redirige /api/auth/* -> Servicio Auth
app.use('/api/auth', createProxyMiddleware({
    target: process.env.AUTH_SERVICE_URL, // Ej: http://10.0.1.50:3001
    changeOrigin: true,
    pathRewrite: {
        '^/api/auth': '', // Quita /api/auth antes de enviar
    },
}));

// Redirige /api/core/* -> Servicio Core
app.use('/api/core', createProxyMiddleware({
    target: process.env.CORE_SERVICE_URL,
    changeOrigin: true,
    pathRewrite: {
        '^/api/core': '',
    },
}));

// Redirige /api/dashboard/* -> Servicio Dashboard
app.use('/api/dashboard', createProxyMiddleware({
    target: process.env.DASHBOARD_SERVICE_URL,
    changeOrigin: true,
    pathRewrite: {
        '^/api/dashboard': '',
    },
}));

app.listen(PORT, () => {
    console.log(`API Gateway running on port ${PORT}`);
});