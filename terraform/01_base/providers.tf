terraform {
  required_version = ">= 1.5.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7.0"
    }
    # VOEG DEZE PROVIDER TOE: Vereist voor de free-tier API vlaggen uit je Google-zoekopdracht
    azapi = {
      source = "azure/azapi"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-wlcs-tfstate-prod-001"
    storage_account_name = "stwlcstfstateprod001"
    container_name       = "tfstate"
    key                  = "network.tfstate"
    use_oidc             = true
  }
}

# 1. Standaard AzureRM Provider (Platform Subscription)
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  use_oidc                        = true
  subscription_id                 = var.subscription_id_platform
  resource_provider_registrations = "core"
}

# 2. AzureRM Provider Alias voor Development Workloads
provider "azurerm" {
  alias                           = "dev"
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  use_oidc                        = true
  subscription_id                 = var.subscription_id_dev
  resource_provider_registrations = "core"
}

# 3. AzAPI Provider (Gekoppeld aan je Dev Subscription via OIDC)
provider "azapi" {
  subscription_id                 = var.subscription_id_dev
  use_oidc                        = true
}
