data "azurerm_client_config" "current" {}

# Get info about the resource group the solution is deployed into
data "azurerm_resource_group" "this" {
  name = local.resource_group_name
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.log_analytics_workspace_name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "PerGB2018"

  retention_in_days = 30

  tags = local.default_tags
}

module "container_app_environment" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-app-managedenvironment?ref=0.3"

  name                = local.container_app_environment_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  log_analytics_workspace = { resource_id = azurerm_log_analytics_workspace.this.id }

  storages = {
    "matomo-data" = {
      account_name = azurerm_storage_account.this.name
      share_name   = azurerm_storage_share.matomo_data.name
      access_key   = azurerm_storage_account.this.primary_access_key
      access_mode  = "ReadWrite"
    }
    "matomo-config" = {
      account_name = azurerm_storage_account.this.name
      share_name   = azurerm_storage_share.matomo_config.name
      access_key   = azurerm_storage_account.this.primary_access_key
      access_mode  = "ReadWrite"
    }
    "db-data" = {
      account_name = azurerm_storage_account.this.name
      share_name   = azurerm_storage_share.db_data.name
      access_key   = azurerm_storage_account.this.primary_access_key
      access_mode  = "ReadWrite"
    }
  }

  tags = local.default_tags

  # zone redundancy must be disabled unless we supply a subnet for vnet integration.
  zone_redundancy_enabled = false
}


module "matomo_app" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.6.0"

  container_app_environment_resource_id = module.container_app_environment.id
  name                                  = local.ca_mysql_name
  resource_group_name                   = data.azurerm_resource_group.this.name
  revision_mode                         = "Single"
  template = {
    containers = [
      # MariaDB container
      {
        name   = local.container_definitions.db.name
        memory = local.container_definitions.db.memory
        cpu    = local.container_definitions.db.cpu
        image  = local.container_definitions.db.image

        env = concat(
          [for k, v in local.container_definitions.db.env_vars : {
            name  = k
            value = v
          }],
          [for k, v in local.container_definitions.db.secrets : {
            name        = k
            secret_name = v
          }]
        )

        volume_mounts = [{
          name = "db-data"
          path = "/var/lib/mysql"
        }]

        command = ["--max-allowed-packet=64MB"]
      }
    ]
  }
  ingress = {
    target_port      = 80
    external_enabled = true
    traffic_weight = [{
      latest_revision = true
      percentage      = 100
    }]
  }
  managed_identities = {
    type = "SystemAssigned"
  }

  secrets = {
    mysql_root_password = {
      name                = "mysql-root-password"
      key_vault_secret_id = module.keyvault.secrets.mysql_root_password.id
    }
    mysql_user_password = {
      name                = "mysql-user-password"
      key_vault_secret_id = module.keyvault.secrets.mysql_user_password.id
    }
  }

  tags = local.default_tags
}

resource "azurerm_role_assignment" "container_app_keyvault_access" {
  scope                = module.keyvault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.matomo_app.resource.identity[0].principal_id
}
