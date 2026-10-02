data "terraform_remote_state" "base" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-wlcs-tfstate-prod-001"
    storage_account_name = "stwlcstfstateprod001"
    container_name       = "tfstate"
    key                  = "network.tfstate"
  }
}
