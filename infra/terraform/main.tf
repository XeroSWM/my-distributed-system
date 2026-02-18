provider "aws" {
  region = "us-east-1"
}

# =========================================================================
#  LLAVE SSH (Usando variable desde terraform.tfvars)
# =========================================================================
resource "aws_key_pair" "taskmaster_key" {
  key_name   = "taskmaster_key"
  # AQUI EL CAMBIO: Leemos la llave de tu archivo de variables
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
  # Estas variables vienen de tu terraform.tfvars
  db_username       = var.db_username
  db_password       = var.db_password
}

# =========================================================================
#  SERVIDORES
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
      AUTH_SERVICE_URL=http://${module.server_auth.public_ip}:3001
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

# --- 4. Frontend ---
module "server_frontend" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  instance_name     = "TM-Frontend"
  key_name          = aws_key_pair.taskmaster_key.key_name

  user_data_script = templatefile("${path.module}/templates/install.sh.tpl", {
    service_name     = "frontend"
    # ESTO EVITA EL ERROR DE ARGUMENTOS:
    # Metemos las variables VITE dentro del contenido del .env directamente
    env_file_content = <<-EOT
      VITE_AUTH_URL=http://${module.server_auth.public_ip}:3001
      VITE_CORE_URL=http://${module.server_core.public_ip}:3002
      VITE_DASHBOARD_URL=http://${module.server_dashboard.public_ip}:3003
    EOT
  })
}

# --- 5. API GATEWAY (El Director de Orquesta) ---
module "gateway" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  instance_name     = "TM-API-Gateway"
  key_name          = aws_key_pair.taskmaster_key.key_name

  # Usamos un script diferente para el Gateway
  user_data_script = templatefile("${path.module}/templates/install_gateway.sh.tpl", {
    # Pasamos las IPs privadas o públicas de los otros servidores
    auth_ip      = module.server_auth.private_ip # Mejor usar IP privada si están en la misma VPC
    core_ip      = module.server_core.private_ip
    dashboard_ip = module.server_dashboard.private_ip
  })
}

# =========================================================================
#  OUTPUTS
# =========================================================================

output "DB_HOST" { value = module.database.db_endpoint }
output "IP_AUTH" { value = module.server_auth.public_ip }
output "IP_CORE" { value = module.server_core.public_ip }
output "IP_DASHBOARD" { value = module.server_dashboard.public_ip }
output "IP_FRONTEND" { value = module.server_frontend.public_ip }
output "URL_APP" { 
  value = "http://${module.server_frontend.public_ip}" 
}