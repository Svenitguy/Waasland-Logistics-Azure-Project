# =========================================================================
# LOCAL FALLBACKS VOOR FEATURE-BRANCH VALIDATIE (GitOps Best Practice)
# =========================================================================
locals {
  # Als de remote state de output nog niet heeft (omdat base nog niet is ge-applied op main),
  # valt Terraform hier automatisch terug op de hardcoded naam om het plan succesvol te genereren.
  rg_name   = try(data.terraform_remote_state.base.outputs.hub_resource_group_name, "rg-wlcs-hub-prod-001")
  vnet_name = try(data.terraform_remote_state.base.outputs.hub_vnet_name, "vnet-wlcs-hub-prod-001")
  location  = try(data.terraform_remote_state.base.outputs.hub_location, "northeurope")
}

# =========================================================================
# 1. ENTERPRISE CLOUD TOEGANG VIA AZURE BASTION (DYNAMIC PROVISIONING)
# =========================================================================

# Het verplichte subnet voor Azure Bastion binnen het centrale Hub VNet
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = local.rg_name
  virtual_network_name = local.vnet_name
  address_prefixes     = ["10.0.4.0/26"]
}

# Het publieke IP-adres ten behoeve van de Bastion service
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-wlcs-bastion-prod-001"
  location            = local.location
  resource_group_name = local.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Platform"
    Project     = "WLCS-Azure-Enterprise"
    Owner       = "sys-admins"
  }
}

# De Azure Bastion Host
resource "azurerm_bastion_host" "bastion" {
  name                = "bas-wlcs-platform-prod-001"
  location            = local.location
  resource_group_name = local.rg_name
  sku                 = "Basic"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = {
    Environment = "Platform"
    Project     = "WLCS-Azure-Enterprise"
    Owner       = "sys-admins"
    Lifecyle    = "Ephemeral-On-Demand"
  }
}
