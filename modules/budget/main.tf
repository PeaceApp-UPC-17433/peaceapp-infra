locals {
  thresholds = {
    actual_50  = { threshold = 50, type = "Actual" }
    actual_80  = { threshold = 80, type = "Actual" }
    actual_100 = { threshold = 100, type = "Actual" }
    forecast   = { threshold = 100, type = "Forecasted" }
  }
}

resource "azurerm_consumption_budget_resource_group" "this" {
  name              = var.name
  resource_group_id = var.resource_group_id
  amount            = var.amount
  time_grain        = "Monthly"

  time_period {
    start_date = var.start_date
  }

  dynamic "notification" {
    for_each = local.thresholds
    content {
      enabled        = true
      threshold      = notification.value.threshold
      threshold_type = notification.value.type
      operator       = "GreaterThan"
      contact_emails = var.contact_emails
    }
  }
}
