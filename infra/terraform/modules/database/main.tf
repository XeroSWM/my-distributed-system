# 1. Grupo de Subnets (Le dice a RDS en qué red vivir)
resource "aws_db_subnet_group" "default" {
  name       = "taskmaster-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "taskmaster-db-subnet-group"
  }
}

# 2. La Instancia de Base de Datos (PostgreSQL)
resource "aws_db_instance" "default" {
  identifier        = "taskmaster-db"
  allocated_storage = 20            # 20 GB (Mínimo para Free Tier)
  storage_type      = "gp2"
  engine            = "postgres"
  engine_version    = "12.22"        # Versión compatible
  instance_class    = "db.t3.micro" # Elegible para Free Tier
  
  # Credenciales (Vendrán de variables)
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Red y Seguridad
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false    # Por seguridad, solo accesible desde la VPC (EC2)
  skip_final_snapshot    = true     # IMPORTANTE: Permite borrar la DB sin hacer backup final (para pruebas)

  tags = {
    Name = "taskmaster-rds"
  }
}

# OUTPUT: El enlace para conectar la app (Host)
output "db_endpoint" {
  value = aws_db_instance.default.address
}