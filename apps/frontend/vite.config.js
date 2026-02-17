import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true,      // <--- ¡ESTA ES LA LÍNEA MÁGICA!
    port: 3000,      // Asegúrate que sea el 3000
    strictPort: true,
    watch: {
      usePolling: true // A veces necesario en Docker
    }
  }
})