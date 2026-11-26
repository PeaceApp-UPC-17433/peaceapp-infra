mock_provider "azurerm" {}

variables {
  name                 = "pg-test"
  location             = "brazilsouth"
  resource_group_name  = "rg-test"
  administrator_login  = "pgadmin"
  administrator_secret = "una-clave-larga-123"
  databases            = ["a_db", "b_db"]
}

run "una_base_por_servicio" {
  command = plan

  assert {
    condition     = length(azurerm_postgresql_flexible_server_database.databases) == 2
    error_message = "Debe crearse una base por nombre."
  }
}

run "sin_acceso_abierto_por_defecto" {
  command = plan

  assert {
    condition     = length(azurerm_postgresql_flexible_server_firewall_rule.azure_services) == 0
    error_message = "La regla de servicios de Azure debe ser opt-in."
  }
}

run "ip_permitida_crea_regla" {
  command = plan

  variables {
    allowed_ips = ["20.10.10.10"]
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server_firewall_rule.allowed) == 1
    error_message = "Cada IP permitida genera una regla."
  }
}
