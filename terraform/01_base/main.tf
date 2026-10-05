# =========================================================================
# 1. CORE NETWERKINFRASTRUCTUUR (HUB-SPOKE TOPOLOGIE via module)
# =========================================================================
module "network" {
  source = "../modules/network"

  providers = {
    azurerm.hub = azurerm     
    azurerm.dev = azurerm.dev 
  }

  location                 = var.location
  subscription_id_platform = var.subscription_id_platform
  subscription_id_dev      = var.subscription_id_dev
}

# =========================================================================
# 2. COMPUTE, STORAGE & BEDRIJFSAPPLICATIE (STORAGE via module)
# =========================================================================
module "storage" {
  source = "../modules/storage"

  # We koppelen de Dev provider aan de dev alias binnen de module
  providers = {
    azurerm.dev = azurerm.dev
  }

  # Dynamische invoer verkregen uit de outputs van de netwerkmodule!
  location                = var.location
  dev_resource_group_name = module.network.dev_resource_group_name
  spoke_vnet_id           = module.network.spoke_vnet_id
  app_subnet_id           = module.network.app_subnet_id
}
