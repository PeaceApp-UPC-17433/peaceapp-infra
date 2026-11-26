resource "azurerm_storage_account" "this" {
  name                            = var.storage_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  tags                            = var.tags

  blob_properties {
    cors_rule {
      allowed_origins    = var.cors_origins
      allowed_methods    = ["PUT", "OPTIONS"]
      allowed_headers    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }
}

resource "azurerm_storage_container" "raw" {
  name                  = "evidences-raw"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "sanitized" {
  name                  = "evidences-sanitized"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "other"
  tags                = var.tags
}

resource "azurerm_service_plan" "this" {
  name                = "asp-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

resource "azurerm_linux_function_app" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id

  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  https_only                 = true

  site_config {
    application_insights_connection_string = azurerm_application_insights.this.connection_string
    minimum_tls_version                    = "1.2"
    ftps_state                             = "Disabled"

    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    EVIDENCE_STORAGE = azurerm_storage_account.this.primary_connection_string
  }

  tags = var.tags
}

resource "azurerm_storage_management_policy" "raw_retention" {
  storage_account_id = azurerm_storage_account.this.id

  rule {
    name    = "delete-raw-evidence"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["evidences-raw/"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 1
      }
    }
  }
}
