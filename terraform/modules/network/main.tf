# =========================================================================
# 1. CENTRALE PLATFORM NETWERKHUB (WLCS-Platform-Prod Abonnement)
# =========================================================================

# Resource Group voor de Hub
resource "azurerm_resource_group" "rg_hub" {
  provider = azurerm.hub
  name     = "rg-wlcs-hub-prod-001"
  location = var.location
  tags = {
    Environment = "Platform"
    Project     = "WLCS-Core"
    Owner       = "sys-admins"
  }
}

# Het Virtuele Netwerk (Hub vNet)
resource "azurerm_virtual_network" "vnet_hub" {
  provider            = azurerm.hub
  name                = "vnet-wlcs-hub-prod-001"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name
  address_space       = ["10.0.0.0/20"]

  # HIER TOEGEVOEGD: VNet Hub Tags om de Policy tevreden te stellen
  tags = {
    Environment = "Platform"
    Project     = "WLCS-Core"
    Owner       = "sys-admins"
  }
}

# Subnet voor de Azure Firewall (Subnets ondersteunen GEEN tags)
resource "azurerm_subnet" "snet_firewall" {
  provider             = azurerm.hub
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg_hub.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.0.0.0/26"]
}

# Subnet voor de VPN Gateway (Subnets ondersteunen GEEN tags)
resource "azurerm_subnet" "snet_gateway" {
  provider             = azurerm.hub
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg_hub.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.0.0.64/27"]
}

# Gedeeld Beheersubnet (Subnets ondersteunen GEEN tags)
resource "azurerm_subnet" "snet_hub_shared" {
  provider             = azurerm.hub
  name                 = "snet-hub-shared-mgmt-001"
  resource_group_name  = azurerm_resource_group.rg_hub.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.0.1.0/24"]
}


# =========================================================================
# 2. LOGISTICS WORKLOAD SPOKE (WLCS-Logistics-Dev Abonnement)
# =========================================================================

# Resource Group voor de Dev Workloads
resource "azurerm_resource_group" "rg_dev" {
  provider = azurerm.dev
  name     = "rg-wlcs-logistics-dev-001"
  location = var.location
  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

# Het Virtuele Netwerk (Dev Spoke vNet)
resource "azurerm_virtual_network" "vnet_spoke_dev" {
  provider            = azurerm.dev
  name                = "vnet-wlcs-logistics-dev-001"
  location            = azurerm_resource_group.rg_dev.location
  resource_group_name = azurerm_resource_group.rg_dev.name
  address_space       = ["10.1.0.0/20"]

  # HIER TOEGEVOEGD: Spoke VNet Tags om de Policy tevreden te stellen
  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }
}

# Subnets binnen de Dev Spoke (Subnets ondersteunen GEEN tags)
resource "azurerm_subnet" "snet_web" {
  provider             = azurerm.dev
  name                 = "snet-logistics-web-dev"
  resource_group_name  = azurerm_resource_group.rg_dev.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke_dev.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "snet_app" {
  provider             = azurerm.dev
  name                 = "snet-logistics-app-dev"
  resource_group_name  = azurerm_resource_group.rg_dev.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke_dev.name
  address_prefixes     = ["10.1.2.0/24"]
}

# Geïsoleerd Database Subnet (Subnets ondersteunen GEEN tags)
resource "azurerm_subnet" "snet_db" {
  provider             = azurerm.dev
  name                 = "snet-logistics-db-dev"
  resource_group_name  = azurerm_resource_group.rg_dev.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke_dev.name
  address_prefixes     = ["10.1.3.0/24"]
}


# =========================================================================
# 3. NETWORK SECURITY GROUPS & ISOLATIE (WAF Security)
# =========================================================================

# NSG voor het Database Subnet
resource "azurerm_network_security_group" "nsg_db" {
  provider            = azurerm.dev
  name                = "nsg-logistics-db-dev"
  location            = azurerm_resource_group.rg_dev.location
  resource_group_name = azurerm_resource_group.rg_dev.name

  # HIER TOEGEVOEGD: NSG Tags om de Policy tevreden te stellen
  tags = {
    Environment = "Dev"
    Project     = "WLCS-Logistics"
    Owner       = "sys-admins"
  }

  security_rule {
    name                       = "Allow-App-To-DB"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "10.1.2.0/24"
    destination_address_prefix = "10.1.3.0/24"
  }

  security_rule {
    name                       = "Deny-All-Other-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Koppel de NSG fysiek aan het Database Subnet (Ondersteunt GEEN tags)
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_db" {
  provider                  = azurerm.dev
  subnet_id                 = azurerm_subnet.snet_db.id
  network_security_group_id = azurerm_network_security_group.nsg_db.id
}


# =========================================================================
# 4. VNET PEERINGS (Peerings ondersteunen GEEN tags)
# =========================================================================

# Peering van Hub naar Dev Spoke
resource "azurerm_virtual_network_peering" "hub_to_dev" {
  provider                     = azurerm.hub
  name                         = "peer-hub-to-logistics-dev"
  resource_group_name          = azurerm_resource_group.rg_hub.name
  virtual_network_name         = azurerm_virtual_network.vnet_hub.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_spoke_dev.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Peering van Dev Spoke naar Hub
resource "azurerm_virtual_network_peering" "dev_to_hub" {
  provider                     = azurerm.dev
  name                         = "peer-logistics-dev-to-hub"
  resource_group_name          = azurerm_resource_group.rg_dev.name
  virtual_network_name         = azurerm_virtual_network.vnet_spoke_dev.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
