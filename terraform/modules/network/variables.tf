variable "location" {
  type        = string
  default     = "westeurope"
  description = "De primaire Azure-regio voor Waasland Logistics"
}

variable "subscription_id_platform" {
  type        = string
  description = "Subscription ID voor het Platform (Hub)"
}

variable "subscription_id_dev" {
  type        = string
  description = "Subscription ID voor Logistics (Dev-Spoke)"
}
