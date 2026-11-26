locals {
  prefix = "${var.app_name}-${var.environment}"

  tags = {
    app         = var.app_name
    environment = var.environment
    managed_by  = "terraform"
  }
}
