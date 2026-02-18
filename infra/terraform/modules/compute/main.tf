# =================================================================
#  LÓGICA DEL MÓDULO (RECURSOS)
# =================================================================

# 1. Buscar la última imagen de Ubuntu (AMI) automáticamente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# (ELIMINADO: resource "aws_key_pair" "deployer")
# Ya no creamos la llave aquí, usamos la que viene del root.

# 2. Crear la Instancia EC2 (El Servidor)
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  subnet_id     = var.subnet_id
  
  # Seguridad
  vpc_security_group_ids = [var.security_group_id]
  
  # AQUI EL CAMBIO: Usamos la variable key_name en lugar de crearla
  key_name               = var.key_name

  # Script de inicio
  user_data                   = var.user_data_script
  user_data_replace_on_change = true

  tags = {
    Name = var.instance_name
  }
}

# 3. Asignar IP Pública Estática (Elastic IP)
resource "aws_eip" "web_ip" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name = "${var.instance_name}-IP"
  }
}