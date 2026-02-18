# infra/terraform/variables.tf

variable "db_username" {
  description = "Usuario maestro de la base de datos"
  type        = string
  default     = "dbadmin"
}

# (Asegúrate de que db_password y my_public_ssh_key también estén aquí)
variable "db_password" {
  description = "Contraseña de la BD"
  type        = string
  sensitive   = true
}

variable "my_public_ssh_key" {
  description = "Llave pública SSH"
  type        = string
}