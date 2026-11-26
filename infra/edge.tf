module "edge" {
  source = "../modules/edge"

  dns_zone      = var.dns_zone
  app_subdomain = var.app_subdomain
  ingress_ip    = var.ingress_ip
}
