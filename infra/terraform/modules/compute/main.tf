# 1. Buscar la última imagen de Ubuntu (AMI) automáticamente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Dueño oficial de Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 2. Configurar la Llave SSH
# Usamos el nombre de la instancia en el key_name para evitar conflictos si despliegas varios módulos
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${var.instance_name}"
  public_key = var.public_key
}

# 3. Crear la Instancia EC2 (El Servidor)
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro" # Capa Gratuita
  subnet_id     = var.subnet_id
  
  # Seguridad
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.deployer.key_name

  # --- LA PARTE MÁGICA ---
  # Aquí inyectamos el script que definimos en el archivo principal.
  # Si no le pasamos nada, no hace nada. Si le pasamos el script de Auth, instala Auth.
  user_data = var.user_data_script

  # Esto asegura que si cambias el script, Terraform recree el servidor para aplicar los cambios
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

# 5. Exportar la IP para que los otros módulos la puedan leer
output "public_ip" {
  value = aws_eip.web_ip.public_ip
}