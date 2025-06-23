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
  ca_mysql_name                  = "ca-mysql"
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
  container_definitions = {
    db = {
      name   = "mariadb"
      image  = "mariadb:10.11"
      cpu    = 0.5
      memory = "1Gi"
      env_vars = {
        MARIADB_AUTO_UPGRADE           = "1"
        MARIADB_DISABLE_UPGRADE_BACKUP = "1"
        MARIADB_INITDB_SKIP_TZINFO     = "1"
      }
      secrets = {
        MYSQL_ROOT_PASSWORD = "mysql-root-password"
        MYSQL_PASSWORD      = "mysql-password"
      }
      # Additional db.env values...
    }
    app = {
      name   = "matomo"
      image  = "matomo:fpm-alpine"
      cpu    = 0.5
      memory = "1Gi"
      env_vars = {
        MATOMO_DATABASE_HOST          = "localhost" # Container Apps use localhost for multi-container
        PHP_MEMORY_LIMIT              = "2048M"
        MATOMO_DATABASE_ADAPTER       = "mysql"
        MATOMO_DATABASE_TABLES_PREFIX = "matomo_"
        MATOMO_DATABASE_DBNAME        = "matomo"
        MATOMO_DATABASE_USERNAME      = "matomo"
      }
      secrets = {
        MATOMO_DATABASE_PASSWORD = "mysql-password"
      }
    }
    web = {
      name   = "nginx"
      image  = "nginx:alpine"
      cpu    = 0.25
      memory = "0.5Gi"
      # Config volume mount for matomo.conf
    }
  }
}
