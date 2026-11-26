variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "storage_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "cors_origins" {
  type = list(string)
}
