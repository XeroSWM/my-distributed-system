variable "subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "db_name" { default = "taskmaster_db" }
variable "db_username" {
  description = "Usuario maestro de la base de datos"
  type        = string
  default     = "dbadmin"  # <--- ANTES DECÍA "admin"
}
variable "db_password" { sensitive = true }