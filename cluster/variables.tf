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

variable "admin_email" {
  description = "Correo del administrador inicial. Debe poder recibir mensajes (restablecer contrasena, avisos)."
  type        = string
  default     = ""

  validation {
    condition     = var.admin_email == "" || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.admin_email))
    error_message = "admin_email debe ser un correo valido."
  }
}

variable "admin_password" {
  description = "Contrasena del administrador inicial. Solo se usa si no existe ningun administrador."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    # RE2 no admite lookahead: cada requisito se comprueba por separado.
    condition = var.admin_password == "" || (
      length(var.admin_password) >= 12 && length(var.admin_password) <= 72 &&
      can(regex("[a-z]", var.admin_password)) && can(regex("[A-Z]", var.admin_password)) && can(regex("[0-9]", var.admin_password))
    )
    error_message = "admin_password: de 12 a 72 caracteres, con mayuscula, minuscula y numero."
  }
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
