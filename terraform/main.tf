# Aanroepen van de netwerkmodule voor Waasland Logistics
module "network" {
  source = "./modules/network"

  # Hier koppelen we de providers aan de module
  providers = {
    azurerm.hub = azurerm     # De standaard provider koppelen aan de hub-alias binnen de module
    azurerm.dev = azurerm.dev # De dev provider koppelen aan de dev-alias binnen de module
  }

  # Doorgeven van de variabelen (indien nodig voor tags/namen)
  subscription_id_platform = var.subscription_id_platform
  subscription_id_dev      = var.subscription_id_dev
}
