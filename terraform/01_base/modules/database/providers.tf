terraform {
  required_version = ">= 1.5.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7.0"
      configuration_aliases = [ azurerm, azurerm.dev ] # <-- Verplicht de AzureRM aliases binnen de module
    }
    # VOEG DIT BLOK TOE: Dit vertelt de module dat azapi van 'azure/' komt en lost je pipeline fout op!
    azapi = {
      source                = "azure/azapi"
      configuration_aliases = [ azapi ] # <-- Zorgt dat de module de azapi instellingen overneemt
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
  }
}
