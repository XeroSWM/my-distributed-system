# 1. La VPC (Tu Nube Privada)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "taskmaster-vpc"
  }
}

# 2. Subnet Pública 1 (Para EC2 y Load Balancer)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" # Cambia si tu región es otra
  map_public_ip_on_launch = true

  tags = { Name = "taskmaster-public-1" }
}

# 3. Subnet Pública 2 (Requerida por RDS para alta disponibilidad)
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = { Name = "taskmaster-public-2" }
}

# 4. Internet Gateway (La puerta a internet)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# 5. Tabla de Enrutamiento (El mapa para salir a internet)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# 6. Asociar Subnets a la Ruta Pública
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# OUTPUTS (Para que otros módulos usen estos datos)
output "vpc_id" { value = aws_vpc.main.id }
output "public_subnets" { value = [aws_subnet.public_1.id, aws_subnet.public_2.id] }