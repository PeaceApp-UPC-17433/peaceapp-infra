variable "resource_group_name" {
  description = "Nombre del resource group de PeaceApp."
  type        = string
  default     = "rg-peaceapp"
}

variable "location" {
  description = "Region de Azure. North Central US: la suscripcion Azure for Students solo habilita Chile Central, Brazil South, North Central US, Canada East y West Central US, y la cuota de vCPU de Brazil South no permitio crear el cluster alli (ver seccion 3.4.1 del informe)."
  type        = string
  default     = "North Central US"
}

variable "aks_cluster_name" {
  description = "Nombre del cluster AKS."
  type        = string
  default     = "aks-peaceapp"
}

variable "aks_node_count" {
  description = "Numero de nodos del pool por defecto."
  type        = number
  default     = 1
}

variable "aks_node_vm_size" {
  description = "Tamano de VM del pool por defecto."
  type        = string
  default     = "Standard_D2ads_v7"
}

variable "postgres_server_name" {
  description = "Nombre del Azure Database for PostgreSQL Flexible Server."
  type        = string
  default     = "peaceapp-pg-17433"
}

variable "postgres_admin_login" {
  description = "Usuario administrador de PostgreSQL."
  type        = string
  default     = "peaceapp_admin"
}

variable "postgres_admin_password" {
  description = "Contrasena del administrador de PostgreSQL. Pasar via TF_VAR_postgres_admin_password, nunca en un archivo versionado (CA-06, TS-08)."
  type        = string
  sensitive   = true
}

variable "postgres_database_names" {
  description = "Bases de datos a crear, una por microservicio desplegado."
  type        = list(string)
  default     = ["identity_db", "incident_db"]
}

variable "tags" {
  description = "Tags comunes aplicados a todos los recursos."
  type        = map(string)
  default = {
    project     = "PeaceApp"
    environment = "pruebas"
    managed_by  = "terraform"
  }
}
