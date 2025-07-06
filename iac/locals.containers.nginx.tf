locals {
  container_nginx = {
    name         = "nginx"
    azure_name   = "ca-matomo-web-${var.env_code}"
    image        = "nginx:alpine"
    cpu          = 0.25
    memory       = "0.5Gi"
    max_replicas = 1
    min_replicas = 1
    env_vars = {
      NGINX_HOST = "localhost"
      NGINX_PORT = "80"
    }
    secrets = {}
    volume_mounts = [
      {
        name      = "matomo-data"
        path      = "/var/www/html"
        read_only = true
      },
      {
        name = "nginx-config"
        path = "/etc/nginx/conf.d"
      }
    ]
    volumes = [
      {
        name         = "matomo-data"
        storage_type = "AzureFile"
        storage_name = "matomo-data"
      },
      {
        name         = "nginx-config"
        storage_type = "Secret"
        secrets = [{
          secret_name = "nginx-config"
          path        = "default.conf"
        }]
      }
    ]
    required_secrets = ["nginx_config"]
    command          = null
    ports = [
      {
        port      = 80
        transport = "http"
      }
    ]
    ingress = {
      target_port      = 80
      external_enabled = true
      transport        = "http"
    }
    # Init container to check app container and storage readiness
    # init_containers = [
    #   {
    #     name    = "wait-for-app-and-storage"
    #     cpu     = 0.25
    #     memory  = "0.5Gi"
    #     image   = "nginx:alpine"
    #     command = ["/bin/sh"]
    #     args = [
    #       "-c",
    #       <<-EOT
    #         # Wait for app container to be ready
    #         echo "Waiting for app container at ${local.container_matomo_app.azure_name}:9000..."
    #         while ! nc -z ${local.container_matomo_app.azure_name} 9000; do
    #           echo "App container not ready, waiting..."
    #           sleep 5
    #         done
    #         echo "App container is ready!"

    #         # Check storage is readable and has required files
    #         echo "Testing storage read access..."
    #         if [ -f /var/www/html/index.php ]; then
    #           echo "Storage is readable and Matomo files are present!"
    #         else
    #           echo "Storage is not readable or Matomo files are missing!"
    #           echo "Contents of /var/www/html:"
    #           ls -la /var/www/html/
    #           exit 1
    #         fi

    #         echo "Nginx init container completed successfully!"
    #       EOT
    #     ]
    #     volume_mounts = [
    #       {
    #         name = "matomo-data"
    #         path = "/var/www/html"
    #       }
    #     ]
    #   }
    # ]
  }
}
