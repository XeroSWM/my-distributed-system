# infra/terraform/modules/compute/outputs.tf

output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_eip.web_ip.public_ip
}

output "public_dns" {
  value = aws_eip.web_ip.public_dns
}

# --- ESTA ES LA LÍNEA MÁGICA QUE TE FALTA ---
# Sin esto, Terraform no puede pasarle la IP al .env
output "private_ip" {
  value = aws_instance.web.private_ip
}