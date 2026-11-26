resource "random_password" "postgres_admin" {
  length  = 32
  special = false
}

module "postgres" {
  source = "../modules/postgres"

  name                 = var.postgres_name
  location             = var.postgres_location
  resource_group_name  = data.azurerm_resource_group.this.name
  administrator_login  = var.postgres_admin_login
  administrator_secret = random_password.postgres_admin.result
  databases            = var.postgres_databases
  allow_azure_services = var.postgres_allow_azure_services
  allowed_ips          = var.postgres_allowed_ips
  tags                 = local.tags
}
