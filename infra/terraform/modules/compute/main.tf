# 1. Buscar la última imagen de Ubuntu (AMI) automáticamente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Dueño oficial de Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 2. Crear una llave SSH para entrar al servidor
resource "aws_key_pair" "deployer" {
  key_name   = "taskmaster-key"
  public_key = var.public_key
}

# 3. La Instancia EC2 (El Servidor)
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro" # Free Tier
  subnet_id     = var.subnet_id
  
  # Seguridad
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.deployer.key_name

  # Script de inicio (Instala Docker automáticamente al encender)
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y ca-certificates curl gnupg
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg
              echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "TaskMaster-App-Server"
  }
}

# 4. IP Elástica (IP Pública Fija)
resource "aws_eip" "web_ip" {
  instance = aws_instance.web.id
  domain   = "vpc"
}

# OUTPUT: La IP pública para entrar
output "public_ip" {
  value = aws_eip.web_ip.public_ip
}