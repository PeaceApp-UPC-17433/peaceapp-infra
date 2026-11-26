terraform {
  required_version = ">= 1.9"

  backend "azurerm" {
    container_name   = "tfstate"
    use_oidc         = true
    use_azuread_auth = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

provider "kubernetes" {
  host                   = local.kube.host
  client_certificate     = base64decode(local.kube.client_certificate)
  client_key             = base64decode(local.kube.client_key)
  cluster_ca_certificate = base64decode(local.kube.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = local.kube.host
    client_certificate     = base64decode(local.kube.client_certificate)
    client_key             = base64decode(local.kube.client_key)
    cluster_ca_certificate = base64decode(local.kube.cluster_ca_certificate)
  }
}
