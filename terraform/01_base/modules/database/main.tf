# =========================================================================
# 1. ADMINISTRATOR CREDENTIALS GENERATION
# =========================================================================
resource "random_password" "vm_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# =========================================================================
# 2. AZURE SQL SERVER
# =========================================================================
resource "azurerm_mssql_server" "sql_server" {
  provider                     = azurerm.dev
  name                         = "sql-wlcs-logistics-dev-free-001" 
  resource_group_name          = var.dev_resource_group_name
  location                     = var.location # GECORRIGEERD: Neemt nu dynamisch "belgiumcentral" over van de root-aanroep
  version                      = "12.0"
  administrator_login          = "wlcsdbadmin"
  administrator_login_password = random_password.vm_password.result
  minimum_tls_version          = "1.2"

  public_network_access_enabled = false 

  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

# =========================================================================
# 3. AZURE SQL DATABASE VIA AZAPI (Reguliere Serverless - FinOps Optimized)
# =========================================================================
resource "azapi_resource" "kmo_db" {
  type                      = "Microsoft.Sql/servers/databases@2022-08-01-preview"
  name                      = "db-wlcs-logistics-dev"
  parent_id                 = azurerm_mssql_server.sql_server.id
  location                  = "belgiumcentral" 
  schema_validation_enabled = false

  body = {
    sku = {
      name   = "GP_S_Gen5_1"
      tier   = "GeneralPurpose"
      family = "Gen5"
    }
    properties = {
      # WE HALEN DE GRATIS VLAG WEG OM DE BELGISCHE FOUT OP TE LOSSEN:
      # Dankzij AutoPause blijft dit nagenoeg €0,- kosten!
      freeLimitExhaustionBehavior  = "AutoPause"
      autoPauseDelayInMinutes      = 60
      minCapacity                  = 0.5
      collation                    = "SQL_Latin1_General_CP1_CI_AS"
      maxSizeBytes                 = 34359738368 # 32 GB
    }
  }

  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

# =========================================================================
# 4. PRIVATE DNS ZONES & LINKS FOR SQL
# =========================================================================
resource "azurerm_private_dns_zone" "sql_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.dev_resource_group_name
  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name                  = "link-sql-dns-to-spoke-vnet"
  private_dns_zone_id   = azurerm_private_dns_zone.sql_dns_zone.id
  virtual_network_id    = var.spoke_vnet_id
  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

# =========================================================================
# 5. PRIVATE ENDPOINT FOR SQL (Moet in IRELAND liggen bij het VNet!)
# =========================================================================
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  provider            = azurerm.dev
  name                = "pe-sql-wlcs-logistics-dev-001"
  
  # GEWIJZIGD: We dwingen het endpoint naar Ierland, waar je VNet en subnet liggen!
  location            = "northeurope" 
  
  resource_group_name = var.dev_resource_group_name
  subnet_id           = var.db_subnet_id 

  private_service_connection {
    name                           = "psc-sql-wlcs-logistics"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "dns-group-sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns_zone.id]
  }
  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}
