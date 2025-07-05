locals {
  container_matomo_app = {
    name         = "matomo"
    azure_name   = "ca-matomo-app-${var.env_code}"
    image        = "matomo:fpm-alpine"
    cpu          = 0.5
    memory       = "1Gi"
    max_replicas = 1
    min_replicas = 1
    env_vars = {
      MATOMO_DATABASE_HOST          = "${local.container_mysql.azure_name}"
      MATOMO_DATABASE_ADAPTER       = "mysql"
      MATOMO_DATABASE_TABLES_PREFIX = "matomo_"
      PHP_MEMORY_LIMIT              = "1024M"
      # This must match the MYSQL_PASSWORD and MYSQL_DATABASE from the db container.
      MATOMO_DATABASE_DBNAME   = "matomo"
      MATOMO_DATABASE_USERNAME = "matomo"
    }
    secrets = {
      # This must match MYSQL_PASSWORD from the db container.
      MATOMO_DATABASE_PASSWORD = "mysql-user-password"
    }
    volume_mounts = [
      {
        name = "matomo-data"
        path = "/var/www/html"
      }
    ]
    volumes = [
      {
        name         = "matomo-data"
        storage_type = "AzureFile"
        storage_name = "matomo-data"
      }
    ]
    required_secrets = ["mysql_user_password"]
    command          = null
    ports = [
      {
        port      = 9000
        transport = "tcp"
      }
    ]
    ingress = {
      target_port      = 9000
      external_enabled = false
      transport        = "tcp"
    }
  }
}
