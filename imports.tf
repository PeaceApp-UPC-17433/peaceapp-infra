# Los recursos de la seccion 3.4 se crearon primero desde el portal y la CLI.
# Estos bloques los ponen bajo administracion de Terraform sin recrearlos:
# terraform plan debe mostrar 0 to destroy y solo agregar lo nuevo (trust_db).
locals {
  rg_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  pg_id = "${local.rg_id}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${var.postgres_server_name}"
}

import {
  to = module.resource_group.azurerm_resource_group.this
  id = local.rg_id
}

import {
  to = module.aks.azurerm_kubernetes_cluster.this
  id = "${local.rg_id}/providers/Microsoft.ContainerService/managedClusters/${var.aks_cluster_name}"
}

import {
  to = module.postgres.azurerm_postgresql_flexible_server.this
  id = local.pg_id
}

import {
  to = module.postgres.azurerm_postgresql_flexible_server_firewall_rule.allow_azure_services
  id = "${local.pg_id}/firewallRules/AllowAllAzureServices"
}

import {
  to = module.postgres.azurerm_postgresql_flexible_server_database.databases["identity_db"]
  id = "${local.pg_id}/databases/identity_db"
}

import {
  to = module.postgres.azurerm_postgresql_flexible_server_database.databases["incident_db"]
  id = "${local.pg_id}/databases/incident_db"
}
