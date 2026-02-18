# infra/terraform/modules/security/outputs.tf

output "web_sg_id" {
  description = "ID del Security Group para los servidores web"
  value       = aws_security_group.web_sg.id
}

output "db_sg_id" {
  description = "ID del Security Group para la base de datos"
  value       = aws_security_group.db_sg.id
}