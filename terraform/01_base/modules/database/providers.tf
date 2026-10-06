terraform {
  required_version = ">= 1.5.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7.0"
      configuration_aliases = [ azurerm, azurerm.dev ] # <-- DIT VERPLICHT DE ALIASES BINNEN DE MODULE
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
  }
}
