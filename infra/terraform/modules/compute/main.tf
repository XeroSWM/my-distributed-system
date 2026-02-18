# =================================================================
#  LÓGICA DEL MÓDULO (RECURSOS)
#  (Nota: Las variables ahora las lee de variables.tf)
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

# 2. Configurar la Llave SSH
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${var.instance_name}"
  public_key = var.public_key
}

# 3. Crear la Instancia EC2 (El Servidor)
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type # Usa la variable que definimos (t2.medium)
  
  subnet_id     = var.subnet_id
  
  # Seguridad
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.deployer.key_name

  # Script de inicio
  user_data = var.user_data_script
  user_data_replace_on_change = true

  tags = {
    Name = var.instance_name
  }
}

# 4. Asignar IP Pública Estática (Elastic IP)
resource "aws_eip" "web_ip" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name = "${var.instance_name}-IP"
  }
}

