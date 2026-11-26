variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "administrator_login" {
  type = string
}

variable "administrator_secret" {
  type      = string
  sensitive = true
}

variable "databases" {
  type = list(string)
}

variable "allow_azure_services" {
  type    = bool
  default = false
}

variable "allowed_ips" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
