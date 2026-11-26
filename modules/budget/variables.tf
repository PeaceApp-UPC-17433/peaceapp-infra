variable "name" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "amount" {
  description = "USD por mes."
  type        = number
}

variable "start_date" {
  description = "Primer día de un mes: 2026-12-01T00:00:00Z"
  type        = string
}

variable "contact_emails" {
  type = list(string)
}
