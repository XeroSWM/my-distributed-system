provider "aws" {
  region = "us-east-1"
}

# 1. Variables Globales (Las definiremos al ejecutar)
variable "db_password" {
  description = "Contraseña maestra para RDS"
  type        = string
  sensitive   = true
}

variable "my_public_ssh_key" {
  description = "Tu clave pública SSH para entrar a la EC2"
  type        = string
}

# 2. Módulos Base
module "networking" {
  source = "./modules/networking"
}

module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
}

# 3. Módulo Base de Datos (RDS)
module "database" {
  source            = "./modules/database"
  subnet_ids        = module.networking.public_subnets # RDS necesita 2 subnets
  security_group_id = module.security.db_sg_id
  db_password       = var.db_password
}

# 4. Módulo Compute (EC2)
module "compute" {
  source            = "./modules/compute"
  subnet_id         = module.networking.public_subnets[0] # EC2 va en una subnet
  security_group_id = module.security.web_sg_id
  public_key        = var.my_public_ssh_key
}

# 5. Outputs Finales (Lo que verás en la consola al terminar)
output "APP_SERVER_IP" {
  value = module.compute.public_ip
  description = "Conéctate aquí: ssh ubuntu@<IP>"
}

output "DB_ENDPOINT" {
  value = module.database.db_endpoint
  description = "Host de la base de datos RDS"
}