resource "time_static" "budget_start" {}

module "budget" {
  source = "../modules/budget"

  name              = "budget-${local.prefix}"
  resource_group_id = data.azurerm_resource_group.this.id
  amount            = var.monthly_budget
  start_date        = formatdate("YYYY-MM-01'T'00:00:00Z", time_static.budget_start.rfc3339)
  contact_emails    = [var.budget_contact_email]
}
