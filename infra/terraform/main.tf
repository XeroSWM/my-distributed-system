provider "aws" {
  region = "us-east-1" # Asegúrate que coincida con tu configuración CLI
}

# Llamamos al Módulo de Red
module "networking" {
  source = "./modules/networking"
}

# Llamamos al Módulo de Seguridad
module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id # Le pasamos la VPC creada arriba
}