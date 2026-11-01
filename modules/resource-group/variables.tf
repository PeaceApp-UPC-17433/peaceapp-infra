variable "name" {
  description = "Nombre del resource group."
  type        = string
}

variable "location" {
  description = "Region de Azure."
  type        = string
}

variable "tags" {
  description = "Tags comunes aplicados al resource group."
  type        = map(string)
  default     = {}
}
