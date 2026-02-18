import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    host: true, // Esto es vital para Docker
    strictPort: true,
  },
  // Agrega esto para forzar que use las variables del proceso de Docker
  define: {
    'process.env': {}
  }
})