# Aanroepen van de netwerkmodule voor Waasland Logistics
module "network" {
  source = "./modules/network"

  # Doorgeven van de abonnement-ID's vanuit de GitHub Secrets variabelen
  subscription_id_platform = var.subscription_id_platform
  subscription_id_dev      = var.subscription_id_dev
}
