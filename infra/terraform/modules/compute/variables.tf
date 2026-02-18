variable "subnet_id" {
  description = "ID de la Subnet donde se creará el servidor"
  type        = string
}

variable "security_group_id" {
  description = "ID del Security Group (Firewall) a asignar"
  type        = string
}

# CAMBIO AQUÍ: Eliminamos public_key y agregamos key_name
variable "key_name" {
  description = "Nombre de la llave SSH ya existente en AWS"
  type        = string
}

variable "instance_name" {
  description = "Nombre (Tag Name) que tendrá el servidor en AWS"
  type        = string
}

variable "user_data_script" {
  description = "Script Bash de inicio para configurar Docker"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.medium"
}