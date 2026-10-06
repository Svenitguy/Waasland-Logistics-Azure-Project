variable "location" {
  type        = string
  description = "De Azure-regio voor de database en Key Vault."
}

variable "dev_resource_group_name" {
  type        = string
  description = "De naam van de Dev Resource Group."
}

variable "tenant_id" {
  type        = string
  description = "Het Azure Tenant ID ten behoeve van de Key Vault configuratie."
}

# HIER STAAN ZE: De drie verplichte variabelen voor de Private Endpoints!
variable "spoke_vnet_id" {
  type        = string
  description = "Het ID van het Spoke VNet voor de DNS-koppelingen."
}

variable "app_subnet_id" {
  type        = string
  description = "Het ID van het Applicatie Subnet voor de Key Vault Private Endpoint."
}

variable "db_subnet_id" {
  type        = string
  description = "Het ID van het Database Subnet voor de SQL Private Endpoint."
}
