# =========================================================================
# 1. ENTERPRISE CLOUD TOEGANG VIA AZURE BASTION (DYNAMIC PROVISIONING)
# =========================================================================

# Het verplichte subnet voor Azure Bastion binnen het centrale Hub VNet
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet" # Absolute Microsoft naam-eis!
  resource_group_name  = data.terraform_remote_state.base.outputs.hub_resource_group_name
  virtual_network_name = data.terraform_remote_state.base.outputs.hub_vnet_name
  address_prefixes     = ["10.0.4.0/26"] 
}

# Het publieke IP-adres ten behoeve van de Bastion service
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-wlcs-bastion-prod-001"
  location            = data.terraform_remote_state.base.outputs.hub_location # <-- NU VOLLEDIG DYNAMISCH!
  resource_group_name = data.terraform_remote_state.base.outputs.hub_resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard" # Public IP SKU moet Standard zijn voor Bastion

  tags = {
    Environment = "Platform"
    Project     = "WLCS-Azure-Enterprise"
    Owner       = "sys-admins"
  }
}

# De Azure Bastion Host - Ingericht voor on-demand GitOps-destructie (WAF Cost Optimization)
resource "azurerm_bastion_host" "bastion" {
  name                = "bas-wlcs-platform-prod-001"
  location            = data.terraform_remote_state.base.outputs.hub_location # <-- NU VOLLEDIG DYNAMISCH!
  resource_group_name = data.terraform_remote_state.base.outputs.hub_resource_group_name
  sku                 = "Basic" # Kan naar keuze gewijzigd worden naar "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = {
    Environment = "Platform"
    Project     = "WLCS-Azure-Enterprise"
    Owner       = "sys-admins"
    Lifecyle    = "Ephemeral-On-Demand" # Toont recruiters jouw kostenbewustzijn!
  }
}
