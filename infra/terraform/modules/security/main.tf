variable "vpc_id" {
  description = "ID de la VPC donde se crearán los grupos de seguridad"
  type        = string
}

# =================================================================
# 1. SECURITY GROUP PARA APLICACIONES WEB (Frontend y Backends)
# =================================================================
resource "aws_security_group" "web_sg" {
  name        = "taskmaster-web-sg"
  description = "Permite HTTP, SSH y Puertos de Microservicios"
  vpc_id      = var.vpc_id

  # --- ACCESO ESTÁNDAR ---
  
  # 1. SSH (Para que puedas entrar a administrar)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 2. HTTP (Para ver el Frontend en el puerto 80)
  ingress {
    description = "HTTP Frontend"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # --- ACCESO A MICROSERVICIOS (LO QUE FALTABA) ---

  # 3. Auth Service (Puerto 3001)
  ingress {
    description = "API Auth"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 4. Core Service (Puerto 3002)
  ingress {
    description = "API Core"
    from_port   = 3002
    to_port     = 3002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 5. Dashboard Service (Puerto 3003)
  ingress {
    description = "API Dashboard"
    from_port   = 3003
    to_port     = 3003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # --- SALIDA (Egress) ---
  # Permitir que el servidor descargue cosas de internet (Docker, Updates, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "taskmaster-web-sg"
  }
}

# =================================================================
# 2. SECURITY GROUP PARA LA BASE DE DATOS
# =================================================================
resource "aws_security_group" "db_sg" {
  name        = "taskmaster-db-sg"
  description = "Permite acceso a PostgreSQL solo desde los servidores web"
  vpc_id      = var.vpc_id

  # Solo permitimos tráfico que venga del Security Group "web_sg"
  # Esto es seguridad de alto nivel: Nadie de internet puede tocar tu BD.
  ingress {
    description     = "PostgreSQL from Web Servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  
  # (Opcional) Si quieres conectarte desde TU casa con DBeaver/PgAdmin, 
  # descomenta esto, pero es inseguro dejarlo abierto al mundo (0.0.0.0/0).
  # ingress {
  #   description = "PostgreSQL Public Access"
  #   from_port   = 5432
  #   to_port     = 5432
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "taskmaster-db-sg"
  }
}