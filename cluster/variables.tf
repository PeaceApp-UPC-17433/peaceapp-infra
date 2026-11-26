variable "resource_group_name" {
  type    = string
  default = "rg-peaceapp"
}

variable "aks_name" {
  type    = string
  default = "aks-peaceapp-v2"
}

variable "postgres_name" {
  type    = string
  default = "peaceapp-pg-v2-17433"
}

variable "postgres_admin_login" {
  type    = string
  default = "peaceapp_admin"
}

variable "tfstate_resource_group" {
  type = string
}

variable "tfstate_storage_account" {
  type = string
}

variable "namespace" {
  type    = string
  default = "peaceapp"
}

variable "letsencrypt_email" {
  type = string
}

variable "resend_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "mapbox_access_token" {
  type      = string
  sensitive = true
  default   = ""
}

variable "ghcr_username" {
  type    = string
  default = ""
}

variable "ghcr_token" {
  type      = string
  default   = ""
  sensitive = true
}
