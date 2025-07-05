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
  }
}
