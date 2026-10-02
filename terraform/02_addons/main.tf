# 1. Het verplichte AzureBastionSubnet binnen het Hub VNet
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet" # Moet exact deze naam zijn
  resource_group_name  = data.terraform_remote_state.base.outputs.hub_resource_group_name
  virtual_network_name = data.terraform_remote_state.base.outputs.hub_vnet_name
  address_prefixes     = ["10.0.4.0/26"] 
}

# 2. Een Public IP aanmaken (Verplicht voor de Basic SKU!)
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-wlcs-bastion-prod-001"
  location            = "northeurope"
  resource_group_name = data.terraform_remote_state.base.outputs.hub_resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard" # Public IP SKU moet Standard zijn voor Bastion

  tags = {
    Environment = "Platform"
    Project     = "WLCS-Azure-Enterprise"
    Owner       = "sys-admins"
  }
}

# 3. De Azure Bastion Host (Basic SKU)
resource "azurerm_bastion_host" "bastion" {
  name                = "bas-wlcs-platform-prod-001"
  location            = "northeurope"
  resource_group_name = data.terraform_remote_state.base.outputs.hub_resource_group_name
  sku                 = "Basic" # Gewijzigd naar Basic zoals voorgesteld!

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = {
    Environment = "Platform"
    Project     = "WLCS-Azure-Enterprise"
    Owner       = "sys-admins"
  }
}
