# IP pública (Elastic IP)
output "public_ip" {
  value = aws_eip.web_ip.public_ip
}

# DNS público
output "public_dns" {
  value = aws_eip.web_ip.public_dns
}

# ID de la instancia
output "instance_id" {
  value = aws_instance.web.id
}

# 🔥 NUEVO: IP privada (para comunicación interna en la VPC)
output "private_ip" {
  value = aws_instance.web.private_ip
}
