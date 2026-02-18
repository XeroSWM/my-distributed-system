#!/bin/bash
set -e # Si algo falla, el script se detiene (para debugging)

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
git clone https://github.com/XeroSWM/my-distributed-system.git
cd my-distributed-system
chown -R ubuntu:ubuntu /home/ubuntu/my-distributed-system

# ---------------------------------------------------------
# 3. CORREGIR ARCHIVOS (SOBRESCRIBIR CON VERSIONES BUENAS)
# ---------------------------------------------------------

# A) Docker Compose (Con puertos abiertos 3001, 3002, etc.)
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

# B) Vite Config (Solo si existe carpeta frontend)
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
    watch: {
      usePolling: true
    }
  }
})
EOF
fi

# ---------------------------------------------------------
# 4. CREAR ARCHIVO .ENV PERSONALIZADO
# ---------------------------------------------------------
# Terraform inyectará aquí el contenido específico de cada servidor
cat <<EOF > .env
${env_file_content}
EOF

# ---------------------------------------------------------
# 5. ARRANCAR EL SERVICIO
# ---------------------------------------------------------
# Terraform inyectará aquí qué servicio arrancar (frontend, service-auth, etc)
docker compose up -d --build ${service_name}