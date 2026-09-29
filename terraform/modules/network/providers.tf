terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
      # Dit lost de waarschuwing definitief op volgens de enterprise-standaard
      configuration_aliases = [
        azurerm.hub,
        azurerm.dev
      ]
    }
  }
}
