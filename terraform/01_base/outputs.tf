output "hub_vnet_name" {
  value       = module.network.hub_vnet_name
  description = "De naam van het centrale Platform Hub VNet."
}

output "hub_resource_group_name" {
  value       = module.network.hub_rg_name
  description = "De Resource Group van het Hub netwerk."
}
