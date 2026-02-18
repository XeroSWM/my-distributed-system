# Archivo: infra/terraform/modules/compute/outputs.tf

# Esto permite que el main.tf principal pueda leer la IP
output "public_ip" {
  value = aws_eip.web_ip.public_ip
}

# Esto permite que el main.tf principal pueda leer el DNS
output "public_dns" {
  value = aws_eip.web_ip.public_dns
}

# Esto permite que el main.tf sepa el ID de la máquina
output "instance_id" {
  value = aws_instance.web.id
}