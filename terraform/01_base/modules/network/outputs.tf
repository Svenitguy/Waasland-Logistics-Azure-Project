output "hub_vnet_name" {
  value       = azurerm_virtual_network.vnet_hub.name
  description = "De fysieke naam van het centrale Platform Hub VNet."
}

output "hub_rg_name" {
  value       = azurerm_resource_group.rg_hub.name
  description = "De fysieke naam van de Hub Resource Group."
}

output "hub_location" {
  value       = azurerm_resource_group.rg_hub.location
  description = "De Azure-regio van de Hub."
}

# --- HIERONDER NIEUW TOEGEVOEGD VOOR FASE 3 ---

output "hub_vnet_id" {
  value       = azurerm_virtual_network.vnet_hub.id
  description = "Het resource ID van het Hub VNet."
}

output "spoke_vnet_id" {
  value       = azurerm_virtual_network.vnet_spoke_dev.id
  description = "Het resource ID van het Dev Spoke VNet."
}

output "app_subnet_id" {
  value       = azurerm_subnet.snet_app.id
  description = "Het resource ID van het Logistics Applicatie Subnet."
}

# HIER AANGEPAST: De naam moet exact "dev_resource_group_name" zijn!
output "dev_resource_group_name" {
  value       = azurerm_resource_group.rg_dev.name
  description = "De Resource Group naam van de Dev workload-omgeving."
}

# --- HIERONDER TOEGEVOEGD VOOR COUPLING MET DATABASE & PRIVATE ENDPOINTS ---

output "web_subnet_id" {
  value       = azurerm_subnet.snet_web.id
  description = "Het resource ID van het Web Subnet."
}

output "db_subnet_id" {
  value       = azurerm_subnet.snet_db.id
  description = "Het resource ID van het geïsoleerde Database Subnet."
}
