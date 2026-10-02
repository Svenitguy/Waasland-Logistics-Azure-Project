terraform {
  required_version = ">= 1.5.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7.0"
      configuration_aliases = [azurerm.hub, azurerm.dev] # Vertelt de module dat er twee subscriptions zijn
    }
  }
}
