variable "vpc_id" {} # Recibe la ID de la VPC

# 1. Security Group para Servidores Web (EC2)
resource "aws_security_group" "web_sg" {
  name        = "taskmaster-web-sg"
  description = "Permitir HTTP, SSH y trafico interno"
  vpc_id      = var.vpc_id

  # Entrada: HTTP (Cualquiera)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Entrada: SSH (Cualquiera - En prod deberia ser tu IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Entrada: API Gateway (Puerto 8080 si lo usamos)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Salida: Todo permitido
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Security Group para Base de Datos (RDS)
resource "aws_security_group" "db_sg" {
  name        = "taskmaster-db-sg"
  description = "Permitir acceso solo desde los servidores Web"
  vpc_id      = var.vpc_id

  # Entrada: Solo desde el Grupo de Seguridad Web (Más seguro)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
}

# OUTPUTS
output "web_sg_id" { value = aws_security_group.web_sg.id }
output "db_sg_id" { value = aws_security_group.db_sg.id }