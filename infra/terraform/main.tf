provider "aws" {
  region = "us-east-1"
}

# --- VARIABLES ---
variable "db_password" { sensitive = true }
variable "my_public_ssh_key" {}

# --- RED Y SEGURIDAD ---
module "networking" { source = "./modules/networking" }
module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
}

# --- BASE DE DATOS ---
module "database" {
  source            = "./modules/database"
  subnet_ids        = module.networking.public_subnets
  security_group_id = module.security.db_sg_id
  db_password       = var.db_password
}

# =========================================================================
#  SCRIPTS DE INICIO (USER DATA)
#  Aquí definimos qué hará cada servidor al nacer
# =========================================================================

# 1. Script Común (Instalar Docker) - Se reutiliza en todos
locals {
  install_docker = <<-EOF
    #!/bin/bash
    # Instalar Docker
    apt-get update
    apt-get install -y ca-certificates curl gnupg git
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu
    
    # Clonar Repositorio
    cd /home/ubuntu
    git clone https://github.com/XeroSWM/my-distributed-system.git
    cd my-distributed-system
    chown -R ubuntu:ubuntu /home/ubuntu/my-distributed-system
  EOF
}

# =========================================================================
#  DEFINICIÓN DE SERVIDORES
# =========================================================================

# --- SERVIDOR 1: AUTH (El primero en nacer) ---
module "server_auth" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Auth-Service"

  # Script Específico de Auth
  user_data_script = <<-EOF
    ${local.install_docker}
    
    # Crear .env para Auth
    cat <<EOT >> .env
    PORT=3001
    DATABASE_URL=postgresql://dbadmin:${var.db_password}@${module.database.db_endpoint}:5432/taskmaster_db
    JWT_SECRET=secreto_automatico
    EOT

    # Levantar servicio
    docker compose up -d --build service-auth
  EOF
}

# --- SERVIDOR 2: CORE (Depende de Auth y DB) ---
module "server_core" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Core-Service"

  # OJO: Aquí inyectamos la IP del módulo Auth automáticamente
  user_data_script = <<-EOF
    ${local.install_docker}
    
    # Crear .env para Core
    cat <<EOT >> .env
    PORT=3002
    DATABASE_URL=postgresql://dbadmin:${var.db_password}@${module.database.db_endpoint}:5432/taskmaster_db
    AUTH_SERVICE_URL=http://${module.server_auth.public_ip}:3001
    EOT

    # Levantar servicio
    docker compose up -d --build service-core
  EOF
}

# --- SERVIDOR 3: DASHBOARD (Depende de DB) ---
module "server_dashboard" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Dashboard-Service"

  user_data_script = <<-EOF
    ${local.install_docker}
    
    # Crear .env para Dashboard
    cat <<EOT >> .env
    PORT=3003
    DATABASE_URL=postgresql://dbadmin:${var.db_password}@${module.database.db_endpoint}:5432/taskmaster_db
    EOT

    # Levantar servicio
    docker compose up -d --build service-dashboard
  EOF
}

# --- SERVIDOR 4: FRONTEND (Depende de TODOS) ---
module "server_frontend" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Frontend"

  # Aquí inyectamos las 3 IPs de los servicios anteriores
  user_data_script = <<-EOF
    ${local.install_docker}
    
    # Crear .env para Frontend
    cat <<EOT >> .env
    VITE_AUTH_URL=http://${module.server_auth.public_ip}:3001
    VITE_CORE_URL=http://${module.server_core.public_ip}:3002
    VITE_DASHBOARD_URL=http://${module.server_dashboard.public_ip}:3003
    EOT

    # Levantar servicio
    docker compose up -d --build frontend
  EOF
}

# --- OUTPUTS FINALES ---
output "URL_APP" { value = "http://${module.server_frontend.public_ip}" }
output "DB_HOST" { value = module.database.db_endpoint }
output "IP_AUTH" { value = module.server_auth.public_ip }
output "IP_CORE" { value = module.server_core.public_ip }
output "IP_DASHBOARD" { value = module.server_dashboard.public_ip }
output "IP_FRONTEND" { value = module.server_frontend.public_ip }
output "URL_APP_DNS" { 
  value = "http://${module.server_frontend.public_dns}:3000" 
  description = "Prueba entrar aquí (nota el :3000 al final)"
}