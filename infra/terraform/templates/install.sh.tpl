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
# Si ya existe, lo borramos para asegurar una instalación limpia
rm -rf my-distributed-system
git clone https://github.com/XeroSWM/my-distributed-system.git
cd my-distributed-system
chown -R ubuntu:ubuntu /home/ubuntu/my-distributed-system

# ---------------------------------------------------------
# 3. CORREGIR ARCHIVOS (SOBRESCRIBIR CON VERSIONES BUENAS)
# ---------------------------------------------------------

# A) Docker Compose (Ahora con ARGS dinámicos para el Frontend)
cat <<'EOF' > docker-compose.yml
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
    build:
      context: ./apps/frontend
      # ESTO ES LO IMPORTANTE: Pasamos las variables del .env al build
      args:
        - VITE_AUTH_URL=${VITE_AUTH_URL}
        - VITE_CORE_URL=${VITE_CORE_URL}
        - VITE_DASHBOARD_URL=${VITE_DASHBOARD_URL}
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

# C) Dockerfile del Frontend (Sobrescribir para aceptar ARGumentos)
# Esto asegura que funcione aunque el repo tenga un Dockerfile viejo
cat <<'EOF' > apps/frontend/Dockerfile
FROM node:18-alpine
WORKDIR /app

# Definimos los argumentos de construcción
ARG VITE_AUTH_URL
ARG VITE_CORE_URL
ARG VITE_DASHBOARD_URL

# Los convertimos en variables de entorno fijas para el build
ENV VITE_AUTH_URL=$VITE_AUTH_URL
ENV VITE_CORE_URL=$VITE_CORE_URL
ENV VITE_DASHBOARD_URL=$VITE_DASHBOARD_URL

COPY package*.json ./
RUN npm install
COPY . .

# Al hacer build, Vite leerá las variables ENV de arriba
RUN npm run build

# Servidor de desarrollo/preview expuesto
EXPOSE 3000
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "3000"]
EOF
fi

# ---------------------------------------------------------
# 4. CREAR ARCHIVO .ENV CON LAS IPs DE TERRAFORM
# ---------------------------------------------------------
# Terraform sustituye ${env_file_content} con las IPs reales
cat <<EOF > .env
${env_file_content}
EOF

# Copiamos el .env también a la carpeta del frontend por si acaso
if [ -d "apps/frontend" ]; then
  cp .env apps/frontend/.env
fi

# ---------------------------------------------------------
# 5. ARRANCAR EL SERVICIO
# ---------------------------------------------------------
# Forzamos el build para que tome los cambios
docker compose up -d --build ${service_name}