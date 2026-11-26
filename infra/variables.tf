variable "app_name" {
  type    = string
  default = "peaceapp"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "resource_group_name" {
  type    = string
  default = "rg-peaceapp"
}

variable "location" {
  type    = string
  default = "northcentralus"
}

variable "postgres_location" {
  type    = string
  default = "northcentralus"
}

variable "dns_zone" {
  type    = string
  default = "angelanampa.dev"
}

variable "app_subdomain" {
  type    = string
  default = "peaceapp"
}

variable "ingress_ip" {
  type    = string
  default = ""
}

variable "aks_name" {
  type    = string
  default = "aks-peaceapp"
}

variable "aks_node_vm_size" {
  type    = string
  default = "Standard_B2as_v2"
}

variable "aks_node_count" {
  type    = number
  default = 1
}

variable "aks_network_policy" {
  type    = string
  default = "cilium"
}

variable "postgres_name" {
  type    = string
  default = "peaceapp-pg-17433"
}

variable "postgres_admin_login" {
  type    = string
  default = "peaceapp_admin"
}

variable "postgres_databases" {
  type    = list(string)
  default = ["identity_db", "incident_db", "trust_db", "alerts_db", "community_db", "notification_db"]
}

variable "postgres_allow_azure_services" {
  type    = bool
  default = true
}

variable "postgres_allowed_ips" {
  type    = list(string)
  default = []
}

variable "function_location" {
  type    = string
  default = "northcentralus"
}

variable "enable_function" {
  type    = bool
  default = true
}

variable "monthly_budget" {
  type    = number
  default = 20
}

variable "budget_contact_email" {
  type = string
}
