resource "azurerm_storage_account" "this" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = data.azurerm_resource_group.this.location
  name                     = local.storage_account_name
  resource_group_name      = data.azurerm_resource_group.this.name

  tags = local.default_tags
}

# Storage shares for persistent data
resource "azurerm_storage_share" "matomo_data" {
  name               = "matomo-data"
  storage_account_id = azurerm_storage_account.this.id
  quota              = 50
}

resource "azurerm_storage_share" "db_data" {
  name               = "db-data"
  storage_account_id = azurerm_storage_account.this.id
  quota              = 50
}


# ephemeral "azapi_resource_action" "key" {
#   type                = "Microsoft.Storage/storageAccounts/listKeys/action"
#   resource_group_name = data.azurerm_resource_group.this.name
#   resource_name       = azurerm_storage_account.this.name
#   api_version         = "2021-04-01"

#   response_export_values = {
#     primary_access_key = "keys[0].value"
#   }

# }

