output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_eip.web_ip.public_ip
}

output "public_dns" {
  value = aws_eip.web_ip.public_dns
}

# --- AGREGA ESTO ---
output "private_ip" {
  description = "IP Privada para comunicación interna entre servidores"
  value       = aws_instance.web.private_ip
}