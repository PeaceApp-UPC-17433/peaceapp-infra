resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.server_name
  location            = var.location
  resource_group_name = var.resource_group_name

  version    = "16"
  sku_name   = "B_Standard_B1ms" # Burstable B1ms (CA-02 / 2.6: costo minimo, suficiente para el proyecto academico)
  storage_mb = 32768

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  zone = "1"

  tags = var.tags
}

# "Allow public access from any Azure service" (0.0.0.0-0.0.0.0): la base solo
# acepta conexiones desde servicios de Azure, como documenta la seccion 3.4.2.
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "AllowAllAzureServices"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Una base de datos por microservicio (CA-02: base de datos por servicio).
resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each  = toset(var.database_names)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
