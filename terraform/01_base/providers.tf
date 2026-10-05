terraform {
  required_version = ">= 1.5.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7.0"
    }
  }

  # HIERMEE VERTELLEN WE TERRAFORM DAT JOUW STATEFILE IN AZURE STAAT
  backend "azurerm" {
    resource_group_name  = "rg-wlcs-tfstate-prod-001"
    storage_account_name = "stwlcstfstateprod001"
    container_name       = "tfstate"
    key                  = "network.tfstate"
    use_oidc             = true
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
