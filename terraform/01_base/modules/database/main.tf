# Dit blok haalt automatisch de actieve abonnement- en tenantgegevens op uit de gekoppelde Azure provider
data "azurerm_client_config" "current" {}

# =========================================================================
# 1. AZURE KEY VAULT (WAF Security - Centraal Geheimenbeheer - Azure v5.x Syntax)
# =========================================================================
resource "azurerm_key_vault" "kmo_vault" {
  name                        = "kv-wlcs-log-dev-001"
  location                    = var.location
  resource_group_name         = var.dev_resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id # <-- DYNAMISCH VIA DE PROVIDER GEREGELD
  sku_name                    = "standard"
  purge_protection_enabled    = true # BEST PRACTICE: Beschermt tegen per ongeluk definitief verwijderen
  rbac_authorization_enabled = true

  # DIT BLOK VERHELPT DE CRITICAL TRIVY BEVINDING (AZU-0013)
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = [] 
    virtual_network_subnet_ids = []
  }

  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

# Genereer automatisch een veilig administrator wachtwoord voor de KMO-servers
resource "random_password" "vm_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Sla het wachtwoord direct veilig op in de Key Vault
resource "azurerm_key_vault_secret" "admin_password_secret" {
  name         = "vms-admin-password"
  value        = random_password.vm_password.result
  key_vault_id = azurerm_key_vault.kmo_vault.id
}

# =========================================================================
# 2. AZURE SQL DATABASE (FinOps Serverless met Auto-Pause)
# =========================================================================
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-wlcs-logistics-dev-001"
  resource_group_name          = var.dev_resource_group_name
  location                     = "westeurope"
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
  max_size_gb  = 5

  sku_name     = "GP_S_Gen5_1" 
  min_capacity = 0.5           
  auto_pause_delay_in_minutes = 60 

  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

# =========================================================================
# 3. PRIVATE DNS ZONES & LINKS (WAF Security / Interne Resolutie)
# =========================================================================
resource "azurerm_private_dns_zone" "kv_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.dev_resource_group_name
  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_dns_link" {
  name                  = "link-kv-dns-to-spoke-vnet"
  private_dns_zone_id   = azurerm_private_dns_zone.kv_dns_zone.id
  virtual_network_id    = var.spoke_vnet_id
  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

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
# 4. PRIVATE ENDPOINTS (Zero-Trust Data Protection Matrix)
# =========================================================================
resource "azurerm_private_endpoint" "kv_private_endpoint" {
  name                = "pe-kv-wlcs-logistics-dev-001"
  location            = var.location
  resource_group_name = var.dev_resource_group_name
  subnet_id           = var.app_subnet_id

  private_service_connection {
    name                           = "psc-kv-wlcs-logistics"
    private_connection_resource_id = azurerm_key_vault.kmo_vault.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "dns-group-keyvault"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_dns_zone.id]
  }
  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

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
