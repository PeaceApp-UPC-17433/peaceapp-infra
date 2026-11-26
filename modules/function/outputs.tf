output "name" {
  value = azurerm_linux_function_app.this.name
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}
