# =========================================================================
# 1. ADMINISTRATOR CREDENTIALS GENERATION
# =========================================================================
resource "random_password" "vm_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# =========================================================================
# 2. AZURE SQL DATABASE (Budgetvriendelijke Enterprise DTU-laag)
# =========================================================================
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-wlcs-logistics-dev-001"
  resource_group_name          = var.dev_resource_group_name
  location                     = var.location 
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

resource "azurerm_mssql_database" "kmo_db" {
  name         = "db-wlcs-logistics-dev"
  server_id    = azurerm_mssql_server.sql_server.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "BasePrice"
  max_size_gb  = 2 

  sku_name     = "Basic" 

  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

# =========================================================================
# 3. PRIVATE DNS ZONES & LINKS FOR SQL
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
# 4. PRIVATE ENDPOINT FOR SQL (Zero-Trust Data Protection)
# =========================================================================
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "pe-sql-wlcs-logistics-dev-001"
  location            = var.location
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
