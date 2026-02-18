variable "subnet_id" {
  description = "ID de la Subnet donde se creará el servidor"
  type        = string
}

variable "security_group_id" {
  description = "ID del Security Group (Firewall) a asignar"
  type        = string
}

variable "public_key" {
  description = "La llave pública SSH para acceder al servidor"
  type        = string
}

variable "instance_name" {
  description = "Nombre (Tag Name) que tendrá el servidor en AWS"
  type        = string
}

variable "user_data_script" {
  description = "Script Bash de inicio (User Data) para configurar Docker"
  type        = string
  default     = ""
}

# --- NUEVA: Para poder cambiar de tamaño fácil ---
variable "instance_type" {
  description = "Tipo de instancia EC2. Recomendado: t2.medium para Docker/Node"
  type        = string
  default     = "t2.medium"
}