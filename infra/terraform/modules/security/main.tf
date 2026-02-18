variable "vpc_id" {} # Recibe la ID de la VPC

# 1. Security Group para Servidores Web (EC2: Frontend, Auth, Core, Dashboard)
resource "aws_security_group" "web_sg" {
  name        = "taskmaster-web-sg"
  description = "Permitir HTTP, SSH y trafico de microservicios"
  vpc_id      = var.vpc_id

  # Puerto 80: Para entrar sin escribir puerto en la URL (Redirección a Docker)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto 22: Para que puedas entrar por SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto 3000 al 3003: Acceso directo a Frontend y Microservicios
  ingress {
    from_port   = 3000
    to_port     = 3003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto 8080: Gateway / Nginx
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto 5173: Por si acaso usas el modo dev de Vite
  ingress {
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Salida: Permitir que el servidor descargue cosas de internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Security Group para Base de Datos (RDS / Postgres Docker)
resource "aws_security_group" "db_sg" {
  name        = "taskmaster-db-sg"
  description = "Permitir acceso solo desde los servidores Web"
  vpc_id      = var.vpc_id

  # Entrada: Solo permite el puerto 5432 si viene de una de nuestras EC2
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # Salida: Todo permitido
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# OUTPUTS
output "web_sg_id" { value = aws_security_group.web_sg.id }
output "db_sg_id" { value = aws_security_group.db_sg.id }