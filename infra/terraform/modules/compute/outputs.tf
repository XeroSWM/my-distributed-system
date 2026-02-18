output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "IP Pública para acceso desde internet"
  value       = aws_eip.web_ip.public_ip
}

output "public_dns" {
  description = "DNS Público de la instancia"
  value       = aws_eip.web_ip.public_dns
}

# --- ESTE ES EL QUE TE FALTA ---
output "private_ip" {
  description = "IP Privada para comunicación interna entre servidores"
  value       = aws_instance.web.private_ip
}