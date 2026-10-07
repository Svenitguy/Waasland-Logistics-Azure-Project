# =========================================================================
# 1. CORE NETWERKINFRASTRUCTUUR (HUB-SPOKE TOPOLOGIE via module)
# =========================================================================
module "network" {
  source = "./modules/network"

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
  source = "./modules/storage"

  providers = {
    azurerm.dev = azurerm.dev
  }

  location                = var.location
  dev_resource_group_name = module.network.dev_resource_group_name
  spoke_vnet_id           = module.network.spoke_vnet_id
  app_subnet_id           = module.network.app_subnet_id
}

# =========================================================================
# 3. SECURITY & DATA LAYER (Azure Key Vault & Serverless SQL Database)
# =========================================================================
module "database" {
  source = "./modules/database"

  # GECORRIGEERD: De AzAPI provider is nu expliciet doorgelust naar de child module
  providers = {
    azurerm      = azurerm     # De standaard provider (Platform/OIDC Hub context)
    azurerm.dev  = azurerm.dev # De specifieke Dev workload provider
    azapi        = azapi       # Koppelt de geavanceerde Microsoft REST-API provider door
  }

  # CAF & POLICY RESILIENCE FIX: Database wijkt uit naar België omdat Ierland/Amsterdam vol zitten
  location                = "belgiumcentral" 
  dev_resource_group_name = module.network.dev_resource_group_name
  tenant_id               = var.tenant_id

  spoke_vnet_id           = module.network.spoke_vnet_id
  app_subnet_id           = module.network.app_subnet_id
  db_subnet_id            = module.network.db_subnet_id
}
