#!/bin/bash
set -e

# ---------------------------------------------------------
# 0. TRUCO DE MAGIA: AUMENTAR MEMORIA (SWAP)
# ---------------------------------------------------------
# Esto evita que el servidor se muera compilando el Frontend
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

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
# 3. CREAR ARCHIVO .ENV (Con las IPs reales)
# ---------------------------------------------------------
cat <<EOF > .env
${env_file_content}
EOF

# ---------------------------------------------------------
# 4. CONFIGURAR DOCKER FILES
# ---------------------------------------------------------

# A) Docker Compose
# Usamos $${VAR} para decirle a Terraform que NO toque esas variables,
# Docker las leerá del archivo .env que acabamos de crear arriba.
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
    build:
      context: ./apps/frontend
      args:
        - VITE_AUTH_URL=$${VITE_AUTH_URL}
        - VITE_CORE_URL=$${VITE_CORE_URL}
        - VITE_DASHBOARD_URL=$${VITE_DASHBOARD_URL}
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

# B) Vite Config
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

# C) Dockerfile del Frontend
# Este Dockerfile recibe los ARGS y los convierte en ENV para el build
cat <<'EOF' > apps/frontend/Dockerfile
FROM node:18-alpine
WORKDIR /app

# 1. Definimos que esperamos estos argumentos desde docker-compose
ARG VITE_AUTH_URL
ARG VITE_CORE_URL
ARG VITE_DASHBOARD_URL

# 2. Los convertimos en variables de entorno fijas
ENV VITE_AUTH_URL=$VITE_AUTH_URL
ENV VITE_CORE_URL=$VITE_CORE_URL
ENV VITE_DASHBOARD_URL=$VITE_DASHBOARD_URL

COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "3000"]
EOF
fi

# ---------------------------------------------------------
# 5. ARRANCAR EL SERVICIO
# ---------------------------------------------------------
docker compose up -d --build ${service_name}