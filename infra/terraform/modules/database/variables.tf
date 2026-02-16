variable "subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "db_name" { default = "taskmaster_db" }
variable "db_username" { default = "admin" }
variable "db_password" { sensitive = true }