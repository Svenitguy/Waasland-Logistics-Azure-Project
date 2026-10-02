output "hub_vnet_name" {
  value       = azurerm_virtual_network.vnet_hub.name
  description = "De fysieke naam van het centrale Platform Hub VNet."
}

output "hub_rg_name" {
  value       = azurerm_resource_group.rg_hub.name
  description = "De fysieke naam van de Hub Resource Group."
}
