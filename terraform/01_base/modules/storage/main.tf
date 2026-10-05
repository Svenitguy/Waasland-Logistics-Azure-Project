# 1. Unieke string genereren
resource "random_string" "storage_unique" {
  length  = 6
  special = false
  upper   = false
}

# 2. Het Cloud Storage Account (WAF Cost Optimized)
resource "azurerm_storage_account" "logistics_storage" {
  provider                 = azurerm.dev
  name                     = "stwlcslogisticsdev${random_string.storage_unique.result}"
  resource_group_name      = var.dev_resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

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

# 3. Azure Fileshare voor documenten
resource "azurerm_storage_share" "vrachtbrieven_share" {
  provider           = azurerm.dev
  name               = "vrachtbrieven-en-pakbonnen"
  storage_account_id = azurerm_storage_account.logistics_storage.id
  quota              = 50
}

# 4. Private DNS Zone voor File storage
resource "azurerm_private_dns_zone" "storage_dns_zone" {
  provider            = azurerm.dev
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.dev_resource_group_name
}

# Link DNS aan het Spoke VNet
resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link" {
  provider            = azurerm.dev
  name                = "link-st-dns-to-spoke-vnet"
  private_dns_zone_id = azurerm_private_dns_zone.storage_dns_zone.id
  virtual_network_id  = var.spoke_vnet_id
}

# 5. Het Private Endpoint in het App Subnet (WAF Security/Zero-Trust)
resource "azurerm_private_endpoint" "storage_private_endpoint" {
  provider            = azurerm.dev
  name                = "pe-st-logistics-file-dev-001"
  location            = var.location
  resource_group_name = var.dev_resource_group_name
  subnet_id           = var.app_subnet_id

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
