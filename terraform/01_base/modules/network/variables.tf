variable "location" {
  type        = string
  description = "De Azure-regio doorgegeven vanuit de root-module"
}

variable "subscription_id_platform" {
  type        = string
  description = "Subscription ID voor het Platform (Hub)"
}

variable "subscription_id_dev" {
  type        = string
  description = "Subscription ID voor Logistics (Dev-Spoke)"
}
