terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

# De standaard provider (voor het Platform / de Hub)
provider "azurerm" {
  features {}
  use_oidc        = true
  subscription_id = var.subscription_id_platform
}

# De extra provider voor de Dev Workloads (met een alias)
provider "azurerm" {
  alias = "dev"
  features {}
  use_oidc        = true
  subscription_id = var.subscription_id_dev
}
