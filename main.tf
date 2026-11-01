module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "aks" {
  source = "./modules/aks"

  cluster_name        = var.aks_cluster_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  dns_prefix          = var.aks_cluster_name
  node_count          = var.aks_node_count
  node_vm_size        = var.aks_node_vm_size
  tags                = var.tags
}

module "postgres" {
  source = "./modules/postgres"

  server_name            = var.postgres_server_name
  location               = module.resource_group.location
  resource_group_name    = module.resource_group.name
  administrator_login    = var.postgres_admin_login
  administrator_password = var.postgres_admin_password
  database_names         = var.postgres_database_names
  tags                   = var.tags
}
