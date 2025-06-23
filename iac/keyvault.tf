ephemeral "random_password" "mysql_root_password" {
  length           = 24
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

ephemeral "random_password" "mysql_user_password" {
  length           = 24
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  mysql_root_password_version = 1
  mysql_user_password_version = 1
}

module "keyvault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  name = local.keyvault_name

  sku_name                 = "standard"
  purge_protection_enabled = false
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  role_assignments = {
    "terraform-keyvault-access" = {
      principal_id               = data.azurerm_client_config.current.object_id
      principal_type             = "ServicePrincipal"
      role_definition_id_or_name = "Key Vault Secrets User"
    }
  }

  tags = local.default_tags

}

resource "azurerm_key_vault_secret" "mysql_root_password" {
  name             = "mysql-root-password"
  value_wo         = ephemeral.random_password.mysql_root_password.result
  value_wo_version = local.mysql_root_password_version
  key_vault_id     = module.keyvault.resource_id
}

ephemeral "azurerm_key_vault_secret" "mysql_root_password" {
  name         = azurerm_key_vault_secret.mysql_root_password.name
  key_vault_id = module.keyvault.resource_id
}

resource "azurerm_key_vault_secret" "mysql_user_password" {
  name             = "mysql-user-password"
  value_wo         = ephemeral.random_password.mysql_user_password.result
  value_wo_version = local.mysql_user_password_version
  key_vault_id     = module.keyvault.resource_id
}

ephemeral "azurerm_key_vault_secret" "mysql_user_password" {
  name         = azurerm_key_vault_secret.mysql_user_password.name
  key_vault_id = module.keyvault.resource_id
}
