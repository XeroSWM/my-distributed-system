data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "deployer" {
  # Usamos el nombre para que la llave sea única por módulo si es necesario, 
  # o simplemente usamos un prefijo. Aquí reutilizamos la llave pero el nombre del recurso en AWS cambia.
  key_name   = "deployer-key-${var.instance_name}" 
  public_key = var.public_key
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro" # Capa gratuita
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.deployer.key_name

  # Script de inicio: Instala Docker automáticamente
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
    Name = var.instance_name  # <--- AQUÍ SE APLICA EL NOMBRE DINÁMICO
  }
}

resource "aws_eip" "web_ip" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name = "${var.instance_name}-IP"
  }
}

output "public_ip" {
  value = aws_eip.web_ip.public_ip
}