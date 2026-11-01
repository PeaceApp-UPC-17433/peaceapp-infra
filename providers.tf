terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
  }

  # Backend local por defecto (suficiente para el alcance academico del curso).
  # Para trabajo en equipo se recomienda migrar a un backend remoto (azurerm
  # storage account), documentado pero no requerido para este avance.
}

provider "azurerm" {
  features {}
}
