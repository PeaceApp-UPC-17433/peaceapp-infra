module "media_sanitizer" {
  count  = var.enable_function ? 1 : 0
  source = "../modules/function"

  name                = "func-${local.prefix}-media"
  location            = var.function_location
  resource_group_name = data.azurerm_resource_group.this.name
  storage_name        = "st${var.app_name}media${substr(sha1(data.azurerm_resource_group.this.id), 0, 6)}"
  cors_origins        = ["https://${module.edge.frontend_domain}"]
  tags                = local.tags
}
