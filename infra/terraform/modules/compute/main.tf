# =================================================================
#  DEFINICIÓN DE VARIABLES DEL MÓDULO
# =================================================================
variable "instance_name" {
  description = "Nombre de la etiqueta Name para el servidor"
  type        = string
}

variable "public_key" {
  description = "Llave pública SSH para entrar al servidor"
  type        = string
}

variable "subnet_id" {
  description = "ID de la subred donde vivirá el servidor"
  type        = string
}

variable "security_group_id" {
  description = "ID del grupo de seguridad (Firewall)"
  type        = string
}

variable "user_data_script" {
  description = "Script de inicio (Bash) para instalar Docker y configurar la app"
  type        = string
}

# =================================================================
#  LÓGICA DEL MÓDULO (RECURSOS)
# =================================================================

# 1. Buscar la última imagen de Ubuntu (AMI) automáticamente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Dueño oficial de Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. Configurar la Llave SSH
# Usamos el nombre de la instancia en el key_name para evitar conflictos
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${var.instance_name}"
  public_key = var.public_key
}

# 3. Crear la Instancia EC2 (El Servidor)
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  
  # CAMBIO IMPORTANTE: t2.medium (2 vCPU, 4GB RAM)
  # t2.micro se congela con Docker + Node.js build.
  instance_type = "t2.medium" 
  
  subnet_id     = var.subnet_id
  
  # Seguridad
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.deployer.key_name

  # Script de inicio (Instalar Docker, Clonar Repo, etc.)
  user_data = var.user_data_script

  # Esto asegura que si cambias el script, Terraform recree el servidor
  user_data_replace_on_change = true

  tags = {
    Name = var.instance_name
  }
}

# 4. Asignar IP Pública Estática (Elastic IP)
# Esto garantiza que la IP no cambie nunca, aunque apagues el servidor
resource "aws_eip" "web_ip" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name = "${var.instance_name}-IP"
  }
}

# =================================================================
#  OUTPUTS (LO QUE DEVUELVE ESTE MÓDULO)
# =================================================================

output "public_ip" {
  description = "La IP Elástica fija del servidor"
  value       = aws_eip.web_ip.public_ip
}

output "public_dns" {
  description = "El DNS público asociado a la IP Elástica"
  value       = aws_eip.web_ip.public_dns
}

output "instance_id" {
  value = aws_instance.web.id
}