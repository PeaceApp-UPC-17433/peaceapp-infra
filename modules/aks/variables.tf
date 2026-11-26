variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "node_vm_size" {
  type = string
}

variable "node_count" {
  type = number
}

variable "network_policy" {
  type = string

  validation {
    condition     = contains(["cilium", "azure"], var.network_policy)
    error_message = "network_policy debe ser cilium o azure."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
