output "resource_group_name" {
  value = module.resource_group.name
}

output "aks_cluster_name" {
  value = module.aks.name
}

output "aks_node_resource_group" {
  value = module.aks.node_resource_group
}

output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "postgres_database_names" {
  value = module.postgres.database_names
}
