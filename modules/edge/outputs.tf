output "frontend_domain" {
  value = local.frontend_domain
}

output "api_domain" {
  value = local.api_domain
}

output "dns_records" {
  value = [
    { type = "A", host = var.app_subdomain, value = local.ingress_ip },
    { type = "A", host = "api.${var.app_subdomain}", value = local.ingress_ip },
  ]
}
