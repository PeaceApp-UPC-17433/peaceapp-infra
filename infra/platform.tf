data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

module "aks" {
  source = "../modules/aks"

  name                = var.aks_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  node_vm_size        = var.aks_node_vm_size
  node_count          = var.aks_node_count
  network_policy      = var.aks_network_policy
  tags                = local.tags
}
