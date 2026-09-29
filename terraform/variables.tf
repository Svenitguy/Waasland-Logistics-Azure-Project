variable "tenant_id" {
  type        = string
  description = "De Microsoft Entra ID Tenant ID van Waasland Logistics"
}

variable "client_id" {
  type        = string
  description = "De Client ID van de GitHub Actions OIDC App-registratie"
}

variable "subscription_id_platform" {
  type        = string
  description = "De Subscription ID voor de centrale Netwerkhub (Platform)"
}

variable "subscription_id_dev" {
  type        = string
  description = "De Subscription ID voor de Logistics Dev-Spoke"
}

