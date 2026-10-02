terraform {
  required_version = ">= 1.5.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-wlcs-tfstate-prod-001"
    storage_account_name = "stwlcstfstateprod001"
    container_name       = "tfstate"
    key                  = "addons/terraform.tfstate"
    use_oidc             = true # Verplicht voor jouw wachtwoordloze GitHub authenticatie
  }
}

provider "azurerm" {
  features {}
  use_oidc        = true
  subscription_id = var.subscription_id_platform # <-- DYNAMISCH VIA REGINA/VARIABLE!
}

variable "subscription_id_platform" {
  type        = string
  description = "De Subscription ID voor de centrale Netwerkhub (Platform) meegegeven via GitHub Secrets"
}
