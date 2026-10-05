terraform {
  required_version = ">= 1.5.7"
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 5.7.0"
      configuration_aliases = [azurerm.dev] # Dwingt het gebruik van de Dev subscription af
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
  }
}
