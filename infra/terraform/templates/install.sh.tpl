#!/bin/bash
set -e

# ---------------------------------------------------------
# 1. INSTALAR DOCKER
# ---------------------------------------------------------
apt-get update
apt-get install -y ca-certificates curl gnupg git
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker ubuntu

# ---------------------------------------------------------
# 2. CLONAR EL REPOSITORIO
# ---------------------------------------------------------
cd /home/ubuntu
rm -rf my-distributed-system
git clone https://github.com/XeroSWM/my-distributed-system.git
cd my-distributed-system
chown -R ubuntu:ubuntu /home/ubuntu/my-distributed-system

# ---------------------------------------------------------
# 3. CONFIGURAR VARIABLES DE ENTORNO
# ---------------------------------------------------------

# A) Crear el archivo .env global (para los backends)
cat <<EOF > .env
${env_file_content}
EOF

# B) ESTRATEGIA SEGURA PARA EL FRONTEND:
# Escribimos el .env directamente dentro de la carpeta del frontend.
# Vite leerá este archivo automáticamente al hacer el build.
if [ -d "apps/frontend" ]; then
  echo "Configurando .env del Frontend..."
  cp .env apps/frontend/.env
  
  # IMPORTANTE: Borramos .dockerignore si existe para asegurar 
  # que Docker COPIE el archivo .env dentro de la imagen.
  rm -f apps/frontend/.dockerignore
fi

# ---------------------------------------------------------
# 4. CONFIGURAR DOCKER FILES (Sobrescribir para garantizar éxito)
# ---------------------------------------------------------

# A) Docker Compose (Simplificado: Sin ARGS)
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  database:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: password123
      POSTGRES_DB: taskmaster_db
    ports:
      - "5432:5432"
    volumes:
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql
      - pg_data:/var/lib/postgresql/data
    networks:
      - app-network

  service-auth:
    build: ./apps/service-auth
    ports:
      - "3001:3001"
    environment:
      DATABASE_URL: postgres://admin:password123@database:5432/taskmaster_db
      JWT_SECRET: secreto_super_seguro
      PORT: 3001
    networks:
      - app-network
    depends_on:
      - database

  service-core:
    build: ./apps/service-core
    ports:
      - "3002:3002"
    environment:
      DATABASE_URL: postgres://admin:password123@database:5432/taskmaster_db
      AUTH_SERVICE_URL: http://service-auth:3001
      PORT: 3002
    networks:
      - app-network
    depends_on:
      - database

  service-dashboard:
    build: ./apps/service-dashboard
    ports:
      - "3003:3003"
    environment:
      DATABASE_URL: postgres://admin:password123@database:5432/taskmaster_db
      PORT: 3003
    networks:
      - app-network
    depends_on:
      - database

  frontend:
    build: ./apps/frontend
    ports:
      - "80:3000"
    networks:
      - app-network

volumes:
  pg_data:

networks:
  app-network:
    driver: bridge
EOF

# B) Vite Config (Asegurar acceso externo)
if [ -d "apps/frontend" ]; then
cat <<'EOF' > apps/frontend/vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 3000,
    strictPort: true,
    allowedHosts: true, 
    watch: {
      usePolling: true
    }
  }
})
EOF

# C) Dockerfile del Frontend (Simplificado)
# Ya no usa ARGS, confía en que el .env está en la carpeta y se copia.
cat <<'EOF' > apps/frontend/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
# Al copiar todo, se copia también el .env que creamos arriba
COPY . .
# Vite leerá el .env aquí durante el build
RUN npm run build
EXPOSE 3000
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "3000"]
EOF
fi

# ---------------------------------------------------------
# 5. ARRANCAR EL SERVICIO
# ---------------------------------------------------------
# --build fuerza a que se vuelva a crear la imagen con el nuevo .env
docker compose up -d --build ${service_name}