variable "location" {
  type        = string
  description = "De Azure-regio voor de storage resources."
}

variable "dev_resource_group_name" {
  type        = string
  description = "De naam van de Dev Resource Group waar de storage in moet."
}

variable "spoke_vnet_id" {
  type        = string
  description = "Het ID van het Dev Spoke VNet ten behoeve van de DNS Link."
}

variable "app_subnet_id" {
  type        = string
  description = "Het ID van het Applicatie Subnet waar het Private Endpoint aan koppelt."
}
