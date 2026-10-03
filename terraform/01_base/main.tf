# Aanroepen van de netwerkmodule voor Waasland Logistics
module "network" {
  source = "./modules/network"

  # Hier koppelen we de cross-subscription providers aan de module
  providers = {
    azurerm.hub = azurerm     # De standaard provider koppelen aan de hub-alias binnen de module
    azurerm.dev = azurerm.dev # De dev provider koppelen aan de dev-alias binnen de module
  }

  # HIER GEVEN WE DE LOCATIE DYNAMISCH DOOR VANUIT DE ROOT NAAR DE MODULE!
  location = var.location

  # Doorgeven van de abonnement-ID's vanuit de GitHub Secrets
  subscription_id_platform = var.subscription_id_platform
  subscription_id_dev      = var.subscription_id_dev
}

# =========================================================================
# FASE 3: COMPUTE, STORAGE & BEDRIJFSAPPLICATIE
# Deel A: Enterprise Beveiligd Storage Account met Private Endpoint (WAF)
# =========================================================================

# 1. Genereer een unieke string voor de Storage Account naam
resource "random_string" "storage_unique" {
  length  = 6
  special = false
  upper   = false
}

# 2. Het Storage Account (WAF Cost Optimization: LRS / Standaard)
resource "azurerm_storage_account" "logistics_storage" {
  provider                 = azurerm.dev 
  name                     = "stwlcslogisticsdev${random_string.storage_unique.result}"
  resource_group_name      = module.network.dev_resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  # OPMERKING: "enable_https_traffic_only" is verwijderd omdat dit nu standaard ALTIJD 'true' is in azurerm v5.x!

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

# 3. De Azure Fileshare voor Vrachtbrieven en Pakbonnen
resource "azurerm_storage_share" "vrachtbrieven_share" {
  provider             = azurerm.dev
  name                 = "vrachtbrieven-en-pakbonnen"
  # OPMERKING: In azurerm v5.x gebruikt men verplicht "storage_account_id" in plaats van name!
  storage_account_id   = azurerm_storage_account.logistics_storage.id
  quota                = 50 
}

# 4. Private DNS Zone voor de Storage File service
resource "azurerm_private_dns_zone" "storage_dns_zone" {
  provider            = azurerm.dev
  name                = "privatelink.file.core.windows.net"
  resource_group_name = module.network.dev_resource_group_name
}

# Koppel de Private DNS Zone aan het Logistics Spoke VNet
resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link" {
  provider              = azurerm.dev
  name                  = "link-st-dns-to-spoke-vnet"
  # OPMERKING: In azurerm v5.x gebruikt men verplicht "private_dns_zone_id" in plaats van de zone name & RG name!
  private_dns_zone_id   = azurerm_private_dns_zone.storage_dns_zone.id
  virtual_network_id    = module.network.spoke_vnet_id
}

# 5. Het Private Endpoint in het Applicatie Subnet (WAF Security)
resource "azurerm_private_endpoint" "storage_private_endpoint" {
  provider            = azurerm.dev
  name                = "pe-st-logistics-file-dev-001"
  location            = var.location
  resource_group_name = module.network.dev_resource_group_name
  subnet_id           = module.network.app_subnet_id

  private_service_connection {
    name                           = "psc-st-logistics-file"
    private_connection_resource_id = azurerm_storage_account.logistics_storage.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "dns-group-storage"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_dns_zone.id]
  }
}
