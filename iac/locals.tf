locals {
  appname        = "matomo-azure-containerapp"
  default_suffix = "${local.appname}-${var.env_code}"

  # optional computed short name
  # this assume two letters for the resource type, three for the location, and three for the environment code (= 24 chars max)
  short_appname        = substr(replace(local.appname, "-", ""), 0, 16)
  default_short_suffix = "${local.short_appname}${var.env_code}"

  # add resource names here, using CAF-aligned naming conventions
  resource_group_name            = "rg-${local.default_suffix}"
  storage_account_name           = "st${local.default_short_suffix}"
  keyvault_name                  = "kv${local.default_short_suffix}"
  container_app_environment_name = "cae-${local.default_suffix}"
  log_analytics_workspace_name   = "law-${local.default_suffix}"

  # tflint-ignore: terraform_unused_declarations
  location = data.azurerm_resource_group.this.location

  # tflint-ignore: terraform_unused_declarations
  default_tags = merge(
    var.default_tags,
    tomap({
      "Environment"  = var.env_code
      "LocationCode" = var.short_location_code
    })
  )
}

locals {
  secret_definitions = {
    mysql_root_password = {
      name                = "mysql-root-password"
      key_vault_secret_id = azurerm_key_vault_secret.mysql_root_password.versionless_id
      identity            = "system"
    }
    mysql_user_password = {
      name                = "mysql-user-password"
      key_vault_secret_id = azurerm_key_vault_secret.mysql_user_password.versionless_id
      identity            = "system"
    }
    nginx_config = {
      name = "nginx-config"
      value = templatefile("${path.module}/conf/matomo.conf", {
        MATOMO_CONTAINER_APP_NAME_AND_PORT = "${local.container_matomo_app.azure_name}:${local.container_matomo_app.ingress.target_port}"
      })
    }
  }

  container_definitions = {
    db  = local.container_mysql
    app = local.container_matomo_app
    web = local.container_nginx
  }
}
