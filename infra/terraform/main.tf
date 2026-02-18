provider "aws" {
  region = "us-east-1"
}

# =========================================================================
#  LLAVE SSH (Incrustada directamente)
# =========================================================================
resource "aws_key_pair" "taskmaster_key" {
  key_name   = "taskmaster_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDkTTC3g1VKkXnrNDjXbHMl6AeNlfKurCHLWF06sIbPtIojfnyGdUq56Ci7Gie1KS5Rskhs8CbzwkXSwxUNu4UYlKxJAC5aoXfUdswEk5zdjUruS1u1cfC0FIz3n55s85fw3KoU54kxpli5vk+VbKfGbs3CpJetgv7Smbw3GtS6Nf1Qv/w/siSiV2DMNXnh6OwRboK6gvvAUk2VpWgKRI6hLwTCNm/mUdxIe9WpKP6myV/jg3Ycbns/jNylky+WT+xlI+YHYrZULv0H0VhF2NOgLlK8OlMg1do/uS7RXyYCPC0GltvcpUiZ5i57yWCDztXAbPmkqgSH8wcQ/5YAi2sMhl6AHKziMqnRER6BBFqP6IA/8O1d505d8M2UGAyN1somhlS9T/8XIwAZZsppRgZRUFcrgNG4tjRnSaQEbRpIwCvyik340Jgi56QAeI0GWku0Bq28toDXZfbvPsed0gLradbXzGUf4sqi5lVgHQmdvQE/1WXZ3kfB5XJjTqCCA+EHuiA9ZlKUKutHq03r9v784Z5WcgNZUc0fOFOPQv99GcjkUGQEa6wPDMYeWgxccSrFZGKbbCKIxeGUJbOfZEYWW6865gXqKZqXzGDWzy80rLKoHsU3lWXokCEx/Zdo7TzAReD1stgUGtNsD/bqGJzpL9ocq9+wHfx52KPnYEXpWQ== admin@DESKTOP-G2UPF9K"
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
    # CORRECCIÓN: Variables vacías para satisfacer la plantilla
    VITE_AUTH_URL      = ""
    VITE_CORE_URL      = ""
    VITE_DASHBOARD_URL = ""
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
    # CORRECCIÓN: Variables vacías
    VITE_AUTH_URL      = ""
    VITE_CORE_URL      = ""
    VITE_DASHBOARD_URL = ""
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
    # CORRECCIÓN: Variables vacías
    VITE_AUTH_URL      = ""
    VITE_CORE_URL      = ""
    VITE_DASHBOARD_URL = ""
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
    env_file_content = "" # El frontend no necesita variables secretas de backend
    
    # CORRECCIÓN: Aquí sí pasamos las variables REALES para el build de Vite
    VITE_AUTH_URL      = "http://${module.server_auth.public_ip}:3001"
    VITE_CORE_URL      = "http://${module.server_core.public_ip}:3002"
    VITE_DASHBOARD_URL = "http://${module.server_dashboard.public_ip}:3003"
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