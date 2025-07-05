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
    # Init container to check database connectivity and storage readiness
    init_containers = [
      {
        name    = "wait-for-db-and-storage"
        cpu     = 0.5
        memory  = "1Gi"
        image   = "alpine:latest"
        command = ["/bin/sh"]
        args = [
          "-c",
          <<-EOT
            # Install netcat for connectivity testing
            apk add --no-cache netcat-openbsd
            
            # Wait for database to be ready
            echo "Waiting for database at ${local.container_mysql.azure_name}:3306..."
            while ! nc -z ${local.container_mysql.azure_name} 3306; do
              echo "Database not ready, waiting..."
              sleep 5
            done
            echo "Database is ready!"
            
            # Check storage is writable
            echo "Testing storage write access..."
            touch /var/www/html/init-test.txt
            if [ -f /var/www/html/init-test.txt ]; then
              echo "Storage is writable!"
              rm /var/www/html/init-test.txt
            else
              echo "Storage is not writable!"
              exit 1
            fi
            
            # Initialize Matomo files if needed
            if [ ! -f /var/www/html/index.php ]; then
              echo "Initializing Matomo files..."
              # Copy files from source location
              cp -r /usr/src/matomo/* /var/www/html/ 2>/dev/null || echo "No source files found"
              chown -R www-data:www-data /var/www/html
            else
              echo "Matomo files already exist"
            fi
            
            echo "Init container completed successfully!"
          EOT
        ]
        volume_mounts = [
          {
            name = "matomo-data"
            path = "/var/www/html"
          }
        ]
      }
    ]
  }
}
