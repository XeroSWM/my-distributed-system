provider "aws" {
  region = "us-east-1"
}

# =========================================================================
#  LLAVE SSH (Usando variable desde terraform.tfvars)
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

module "database" {
  source            = "./modules/database"
  subnet_ids        = module.networking.public_subnets
  security_group_id = module.security.db_sg_id
  db_username       = var.db_username
  db_password       = var.db_password
}

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
      DATABASE_URL=postgresql://${var.db_username}:${var.db_password}@${module.database.db_endpoint}:5432/taskmaster_db
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
      DATABASE_URL=postgresql://${var.db_username}:${var.db_password}@${module.database.db_endpoint}:5432/taskmaster_db
      # USAMOS IP PRIVADA PARA COMUNICACIÓN INTERNA (Más rápido)
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
      DATABASE_URL=postgresql://${var.db_username}:${var.db_password}@${module.database.db_endpoint}:5432/taskmaster_db
    EOT
  })
}

# =========================================================================
#  API GATEWAY (EL NUEVO CEREBRO)
# =========================================================================

# --- 4. API Gateway (Node.js Service) ---
# Este servicio recibe las peticiones del frontend y las reparte a los backends
module "gateway" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  instance_name     = "TM-API-Gateway"
  key_name          = aws_key_pair.taskmaster_key.key_name

  user_data_script = templatefile("${path.module}/templates/install.sh.tpl", {
    service_name     = "api-gateway"
    
    # Pasamos las IPs PRIVADAS para que el Gateway hable internamente con los servicios
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
    
    # EL CAMBIO FINAL: El frontend solo conoce al Gateway (Puerto 80/HTTP estándar)
    # Esto elimina los problemas de CORS y oculta la infraestructura real.
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

output "DB_HOST" { value = module.database.db_endpoint }
output "IP_GATEWAY" { value = module.gateway.public_ip }
output "IP_FRONTEND" { value = module.server_frontend.public_ip }
output "URL_APP" { 
  value = "http://${module.server_frontend.public_ip}" 
}