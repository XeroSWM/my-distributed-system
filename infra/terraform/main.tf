provider "aws" {
  region = var.region
}

module "networking" {
  source = "./modules/networking"
  vpc_cidr = var.vpc_cidr
}

module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
}

module "database" {
  source = "./modules/database"
  vpc_id = module.networking.vpc_id
  subnets = module.networking.private_subnets
  db_password = var.db_password
}

module "compute" {
  source = "./modules/compute"
  vpc_id = module.networking.vpc_id
  public_subnets = module.networking.public_subnets
  security_group_id = module.security.web_sg_id
  # Pasamos datos de conexión a la app
  db_endpoint = module.database.endpoint 
}