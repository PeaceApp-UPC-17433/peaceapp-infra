variable "cluster_name" {
  description = "Nombre del cluster AKS."
  type        = string
}

variable "location" {
  description = "Region de Azure. La suscripcion Azure for Students solo habilita Chile Central, Brazil South, North Central US, Canada East y West Central US."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group donde se crea el cluster."
  type        = string
}

variable "dns_prefix" {
  description = "Prefijo DNS del cluster."
  type        = string
}

variable "node_count" {
  description = "Numero de nodos del pool por defecto."
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "Tamano de VM del pool por defecto. Standard_D2ads_v7 porque las series B y Dv3 no estaban habilitadas en la suscripcion."
  type        = string
  default     = "Standard_D2ads_v7"
}

variable "tags" {
  description = "Tags comunes aplicados al cluster."
  type        = map(string)
  default     = {}
}
