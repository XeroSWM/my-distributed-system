variable "subnet_id" {
  description = "La Subnet donde vivirá el servidor"
  type        = string
}

variable "security_group_id" {
  description = "El firewall (Security Group) a usar"
  type        = string
}

variable "public_key" {
  description = "Tu llave pública SSH"
  type        = string
}

# --- NUEVA VARIABLE ---
variable "instance_name" {
  description = "Nombre que tendrá el servidor en AWS"
  type        = string
}