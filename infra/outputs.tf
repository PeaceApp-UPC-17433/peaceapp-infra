output "resource_group" {
  value = data.azurerm_resource_group.this.name
}

output "aks_name" {
  value = module.aks.name
}

output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "postgres_admin_password" {
  value     = random_password.postgres_admin.result
  sensitive = true
}

output "frontend_domain" {
  value = module.edge.frontend_domain
}

output "api_domain" {
  value = module.edge.api_domain
}

output "function_name" {
  value = var.enable_function ? module.media_sanitizer[0].name : null
}

output "dns_records" {
  value = module.edge.dns_records
}

output "evidence_storage_account" {
  value = var.enable_function ? module.media_sanitizer[0].storage_account_name : ""
}
