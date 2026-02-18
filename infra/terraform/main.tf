provider "aws" {
  region = "us-east-1"
}

# =========================================================================
#  LLAVE SSH
# =========================================================================
resource "aws_key_pair" "taskmaster_key" {
  key_name   = "taskmaster_key"
  public_key = var.my_public_ssh_key
}

# =========================================================================
#  MÓDULOS DE INFRAESTRUCTURA
# =========================================================================

module "networking" { source = "./modules/networking" }

module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
}

# -------------------------------------------------------------------------
# 🚨 NOTA: Módulo Database ELIMINADO para evitar error de permisos AWS.
# Ahora la base de datos corre dentro de cada servidor usando Docker.
# -------------------------------------------------------------------------

# =========================================================================
#  MICROSERVICIOS (BACKEND)
# =========================================================================

# --- 1. Servicio Auth ---
module "server_auth" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  instance_name     = "TM-Auth-Service"
  key_name          = aws_key_pair.taskmaster_key.key_name

  user_data_script = templatefile("${path.module}/templates/install.sh.tpl", {
    service_name     = "service-auth"
    env_file_content = <<-EOT
      PORT=3001
      # CONEXIÓN INTERNA A DOCKER (Ya no usa RDS)
      DATABASE_URL=postgres://admin:password123@database:5432/taskmaster_db
      JWT_SECRET=secreto_automatico
    EOT
  })
}

# --- 2. Servicio Core ---
module "server_core" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  instance_name     = "TM-Core-Service"
  key_name          = aws_key_pair.taskmaster_key.key_name

  user_data_script = templatefile("${path.module}/templates/install.sh.tpl", {
    service_name     = "service-core"
    env_file_content = <<-EOT
      PORT=3002
      # CONEXIÓN INTERNA A DOCKER
      DATABASE_URL=postgres://admin:password123@database:5432/taskmaster_db
      # USAMOS IP PRIVADA PARA COMUNICACIÓN ENTRE SERVIDORES
      AUTH_SERVICE_URL=http://${module.server_auth.private_ip}:3001
    EOT
  })
}

# --- 3. Servicio Dashboard ---
module "server_dashboard" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  instance_name     = "TM-Dashboard-Service"
  key_name          = aws_key_pair.taskmaster_key.key_name

  user_data_script = templatefile("${path.module}/templates/install.sh.tpl", {
    service_name     = "service-dashboard"
    env_file_content = <<-EOT
      PORT=3003
      # CONEXIÓN INTERNA A DOCKER
      DATABASE_URL=postgres://admin:password123@database:5432/taskmaster_db
    EOT
  })
}

# =========================================================================
#  API GATEWAY (EL CEREBRO)
# =========================================================================

# --- 4. API Gateway (Node.js Service) ---
module "gateway" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  instance_name     = "TM-API-Gateway"
  key_name          = aws_key_pair.taskmaster_key.key_name

  user_data_script = templatefile("${path.module}/templates/install.sh.tpl", {
    service_name     = "api-gateway"
    
    # El Gateway usa las IPs privadas para redirigir el tráfico internamente
    env_file_content = <<-EOT
      PORT=8000
      AUTH_SERVICE_URL=http://${module.server_auth.private_ip}:3001
      CORE_SERVICE_URL=http://${module.server_core.private_ip}:3002
      DASHBOARD_SERVICE_URL=http://${module.server_dashboard.private_ip}:3003
    EOT
  })
}

# =========================================================================
#  FRONTEND
# =========================================================================

# --- 5. Frontend ---
module "server_frontend" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  instance_name     = "TM-Frontend"
  key_name          = aws_key_pair.taskmaster_key.key_name

  user_data_script = templatefile("${path.module}/templates/install.sh.tpl", {
    service_name     = "frontend"
    
    # El Frontend apunta a la IP PÚBLICA del Gateway
    env_file_content = <<-EOT
      VITE_AUTH_URL=http://${module.gateway.public_ip}/api/auth
      VITE_CORE_URL=http://${module.gateway.public_ip}/api/core
      VITE_DASHBOARD_URL=http://${module.gateway.public_ip}/api/dashboard
    EOT
  })
}

# =========================================================================
#  OUTPUTS
# =========================================================================

output "IP_GATEWAY" { value = module.gateway.public_ip }
output "IP_FRONTEND" { value = module.server_frontend.public_ip }
output "URL_APP" { 
  value = "http://${module.server_frontend.public_ip}" 
}