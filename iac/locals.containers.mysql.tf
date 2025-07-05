locals {
  container_mysql = {
    name         = "mariadb"
    azure_name   = "ca-matomo-db-${var.env_code}"
    image        = "mariadb:10.11"
    cpu          = 0.25
    memory       = "0.5Gi"
    max_replicas = 1
    min_replicas = 1
    env_vars = {
      MARIADB_AUTO_UPGRADE           = "1"
      MARIADB_DISABLE_UPGRADE_BACKUP = "1"
      MARIADB_INITDB_SKIP_TZINFO     = "1"
      MYSQL_DATABASE                 = "matomo"
      MYSQL_USER                     = "matomo"
    }
    secrets = {
      MYSQL_ROOT_PASSWORD = "mysql-root-password"
      MYSQL_PASSWORD      = "mysql-user-password"
    }
    volume_mounts = [
      {
        name = "db-data"
        path = "/var/lib/mysql"
      }
    ]
    volumes = [
      {
        name         = "db-data"
        storage_type = "AzureFile"
        storage_name = "db-data"
      }
    ]
    required_secrets = ["mysql_root_password", "mysql_user_password"]
    ports = [
      {
        port      = 3306
        transport = "tcp"
      }
    ]
    ingress = {
      target_port      = 3306
      external_enabled = false
      transport        = "tcp"
    }
    command = null
    args    = ["--max-allowed-packet=64MB"]
  }
}
