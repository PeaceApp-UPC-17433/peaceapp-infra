output "name" {
  value = azurerm_function_app_flex_consumption.this.name
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}
