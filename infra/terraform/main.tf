provider "aws" {
  region = "us-east-1"
}

# --- VARIABLES ---
variable "db_password" {
  description = "Contraseña maestra para RDS"
  type        = string
  sensitive   = true
}

variable "my_public_ssh_key" {
  description = "Tu clave pública SSH"
  type        = string
}

# --- RED Y SEGURIDAD ---
module "networking" {
  source = "./modules/networking"
}

module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
}

# --- BASE DE DATOS (Se mantiene igual) ---
module "database" {
  source            = "./modules/database"
  subnet_ids        = module.networking.public_subnets
  security_group_id = module.security.db_sg_id
  db_password       = var.db_password
}

# --- SERVIDOR 1: FRONTEND (React) ---
module "server_frontend" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Frontend"
}

# --- SERVIDOR 2: AUTH SERVICE (Node.js) ---
module "server_auth" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Auth-Service"
}

# --- SERVIDOR 3: CORE SERVICE (Node.js) ---
module "server_core" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[1] # Usamos otra subnet para variar
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Core-Service"
}

# --- SERVIDOR 4: DASHBOARD SERVICE (Node.js) ---
module "server_dashboard" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[1]
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
  instance_name     = "TM-Dashboard-Service"
}

# --- OUTPUTS (Información Final) ---
output "DB_ENDPOINT" {
  value = module.database.db_endpoint
  description = "Host de la Base de Datos"
}

output "IP_FRONTEND" {
  value = module.server_frontend.public_ip
  description = "IP del Frontend (Configurar Nginx aquí)"
}

output "IP_AUTH" {
  value = module.server_auth.public_ip
  description = "IP del Servicio de Auth (Puerto 3001)"
}

output "IP_CORE" {
  value = module.server_core.public_ip
  description = "IP del Servicio Core (Puerto 3002)"
}

output "IP_DASHBOARD" {
  value = module.server_dashboard.public_ip
  description = "IP del Servicio Dashboard (Puerto 3003)"
}