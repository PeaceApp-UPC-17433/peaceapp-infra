variable "server_name" {
  description = "Nombre del Azure Database for PostgreSQL Flexible Server."
  type        = string
}

variable "location" {
  description = "Region de Azure."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group donde se crea el servidor."
  type        = string
}

variable "administrator_login" {
  description = "Usuario administrador del servidor."
  type        = string
}

variable "administrator_password" {
  description = "Contrasena del administrador. Se pasa por TF_VAR_administrator_password, nunca se escribe en un archivo versionado."
  type        = string
  sensitive   = true
}

variable "database_names" {
  description = "Bases de datos a crear, una por microservicio (CA-02)."
  type        = list(string)
  default     = ["identity_db", "incident_db"]
}

variable "tags" {
  description = "Tags comunes aplicados al servidor."
  type        = map(string)
  default     = {}
}
