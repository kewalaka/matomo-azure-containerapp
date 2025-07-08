module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.3"

  location                 = data.azurerm_resource_group.this.location
  name                     = local.storage_account_name
  resource_group_name      = data.azurerm_resource_group.this.name
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  account_tier             = "Standard"

  network_rules = {
    bypass         = ["AzureServices"]
    default_action = "Deny"
  }
  public_network_access_enabled = true

  shares = {
    matomo-data = {
      name  = "matomo-data"
      quota = 5
    }
    db-data = {
      name  = "db-data"
      quota = 5
    }
  }
  # container apps relies on this
  shared_access_key_enabled = true

  tags = local.default_tags
}

