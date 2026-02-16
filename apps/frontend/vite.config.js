import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true, // Esto es CRÍTICO para Docker
    port: 5173,
    watch: {
      usePolling: true // Necesario para que el hot-reload funcione en Windows/Docker
    }
  }
})