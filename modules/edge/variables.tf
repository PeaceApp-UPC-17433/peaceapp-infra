variable "dns_zone" {
  type = string
}

variable "app_subdomain" {
  type = string
}

variable "ingress_ip" {
  type    = string
  default = ""
}
