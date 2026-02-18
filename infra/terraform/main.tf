provider "aws" {
  region = "us-east-1"
}

# =========================================================================
#  MÓDULOS DE INFRAESTRUCTURA
# =========================================================================

module "networking" { source = "./modules/networking" }

module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
}

module "database" {
  source            = "./modules/database"
  subnet_ids        = module.networking.public_subnets
  security_group_id = module.security.db_sg_id
  db_username       = var.db_username
  db_password       = var.db_password
}

# =========================================================================
#  ARCHIVOS CORREGIDOS (Aquí definimos el contenido correcto)
# =========================================================================

locals {
  # 1. El Docker Compose con los puertos YA abiertos (3001, 3002, 3003, 3000)
  correct_docker_compose = <<-EOT
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

  gateway:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./infra/docker/nginx/nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - frontend
      - service-auth
      - service-core
    networks:
      - app-network

volumes:
  pg_data:

networks:
  app-network:
    driver: bridge
EOT

  # 2. La configuración de Vite para que acepte IPs externas
  correct_vite_config = <<-EOT
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
EOT

  # 3. Script Maestro: Instala Docker, Clona Y REEMPLAZA LOS ARCHIVOS MALOS
  install_docker_and_fix = <<-EOF
    #!/bin/bash
    # --- Instalar Docker ---
    apt-get update
    apt-get install -y ca-certificates curl gnupg git
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu

    # --- Clonar Repo ---
    cd /home/ubuntu
    git clone https://github.com/XeroSWM/my-distributed-system.git
    cd my-distributed-system
    chown -R ubuntu:ubuntu /home/ubuntu/my-distributed-system

    # --- MAGIA: Sobrescribir archivos rotos con los buenos ---
    # 1. Reemplazar docker-compose.yml en TODOS los servidores
    cat <<'YAML_CONTENT' > docker-compose.yml
    ${local.correct_docker_compose}
    YAML_CONTENT

    # 2. Reemplazar vite.config.js (Solo afectará si existe la carpeta, o sea en el frontend)
    if [ -d "apps/frontend" ]; then
      cat <<'JS_CONTENT' > apps/frontend/vite.config.js
    ${local.correct_vite_config}
      JS_CONTENT
    fi
    
    # Asegurar permisos de nuevo por si acaso
    chown -R ubuntu:ubuntu /home/ubuntu/my-distributed-system
  EOF
}

# =========================================================================
#  SERVIDORES
# =========================================================================

module "server_auth" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Auth-Service"

  user_data_script = <<-EOF
    ${local.install_docker_and_fix}
    
    cat <<EOT >> .env
    PORT=3001
    DATABASE_URL=postgresql://${var.db_username}:${var.db_password}@${module.database.db_endpoint}:5432/taskmaster_db
    JWT_SECRET=secreto_automatico
    EOT

    docker compose up -d --build service-auth
  EOF
}

module "server_core" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Core-Service"

  user_data_script = <<-EOF
    ${local.install_docker_and_fix}
    
    cat <<EOT >> .env
    PORT=3002
    DATABASE_URL=postgresql://${var.db_username}:${var.db_password}@${module.database.db_endpoint}:5432/taskmaster_db
    AUTH_SERVICE_URL=http://${module.server_auth.public_ip}:3001
    EOT

    docker compose up -d --build service-core
  EOF
}

module "server_dashboard" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Dashboard-Service"

  user_data_script = <<-EOF
    ${local.install_docker_and_fix}
    
    cat <<EOT >> .env
    PORT=3003
    DATABASE_URL=postgresql://${var.db_username}:${var.db_password}@${module.database.db_endpoint}:5432/taskmaster_db
    EOT

    docker compose up -d --build service-dashboard
  EOF
}

module "server_frontend" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Frontend"

  user_data_script = <<-EOF
    ${local.install_docker_and_fix}
    
    cat <<EOT >> .env
    VITE_AUTH_URL=http://${module.server_auth.public_ip}:3001
    VITE_CORE_URL=http://${module.server_core.public_ip}:3002
    VITE_DASHBOARD_URL=http://${module.server_dashboard.public_ip}:3003
    EOT

    # Nota: install_docker_and_fix YA arregló el vite.config.js y el docker-compose
    docker compose up -d --build frontend
  EOF
}

# =========================================================================
#  OUTPUTS
# =========================================================================

output "DB_HOST" { value = module.database.db_endpoint }
output "IP_AUTH" { value = module.server_auth.public_ip }
output "IP_CORE" { value = module.server_core.public_ip }
output "IP_DASHBOARD" { value = module.server_dashboard.public_ip }
output "IP_FRONTEND" { value = module.server_frontend.public_ip }
output "URL_APP" { value = "http://${module.server_frontend.public_dns}:3000" }