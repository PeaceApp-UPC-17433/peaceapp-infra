resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.name
  sku_tier            = "Free"

  role_based_access_control_enabled = true

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  node_os_upgrade_channel   = "NodeImage"

  default_node_pool {
    name       = "nodepool1"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = var.network_policy
    network_data_plane  = var.network_policy == "cilium" ? "cilium" : "azure"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [kubernetes_version]
  }
}
