locals {
  frontend_domain = "${var.app_subdomain}.${var.dns_zone}"
  api_domain      = "api.${local.frontend_domain}"
  ingress_ip      = var.ingress_ip == "" ? "<ip-del-ingress>" : var.ingress_ip
}
