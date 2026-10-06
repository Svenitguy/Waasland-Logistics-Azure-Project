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

  # DIT IS DE CRUCIALE EMTERPRISE OPSET: geef de module toegang tot beide scopes
  providers = {
    azurerm      = azurerm     # De standaard provider (Platform/OIDC Hub context)
    azurerm.dev  = azurerm.dev # De specifieke Dev workload provider
  }

  location                = var.location
  dev_resource_group_name = module.network.dev_resource_group_name
  tenant_id               = var.tenant_id

  spoke_vnet_id           = module.network.spoke_vnet_id
  app_subnet_id           = module.network.app_subnet_id
  db_subnet_id            = module.network.db_subnet_id
}
