output "hub_vnet_name" {
  value       = module.network.hub_vnet_name
  description = "De naam van het centrale Platform Hub VNet."
}

output "hub_resource_group_name" {
  value       = module.network.hub_rg_name
  description = "De Resource Group van het Hub netwerk."
}

output "hub_location" {
  value       = module.network.hub_location
  description = "De Azure-regio van de Hub."
}

# --- HIERONDER NIEUW TOEGEVOEGD VOOR COUPLING MET ADDI-ONS & RESOURCES ---

output "hub_vnet_id" {
  value       = module.network.hub_vnet_id
  description = "Het resource ID van het Hub VNet."
}

output "spoke_vnet_id" {
  value       = module.network.spoke_vnet_id
  description = "Het resource ID van het Dev Spoke VNet."
}

output "app_subnet_id" {
  value       = module.network.app_subnet_id
  description = "Het resource ID van het Logistics Applicatie Subnet."
}

output "dev_resource_group_name" {
  value       = module.network.dev_resource_group_name # <-- Dit moet "dev_resource_group_name" zijn!
  description = "De Resource Group van de Dev workloads."
}
