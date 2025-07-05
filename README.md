# Matomo instance on Azure with Terraform

This project deploys Matomo (web analytics) on Azure Container Apps using a three-tier architecture:

```text
Internet → Nginx (Port 80) → PHP-FPM (Port 9000) → MariaDB (Port 3306)
```

This serves two purposes:

- As the analytics engine for my blog
- As a project to test the Azure Verified Modules for Azure Container Apps (ACA) resource & ACA environment.

## Component Flow

Entry Point: Nginx Container

1) Internet Traffic → Nginx Container (port 80)

- Nginx receives HTTP requests
- Static files served from /var/www/html (shared volume)
- PHP requests proxied to localhost:9000

1) Nginx → Matomo PHP-FPM Container (port 9000)

- PHP-FPM processes PHP requests
- Has read-write access to /var/www/html
- Connects to database at localhost:3306

1) Matomo PHP-FPM → MariaDB Container (port 3306)

- Database stores analytics data
- Uses persistent volume in Azure Files for data storage

## Volumes

- `matomo-data`: Shared between nginx (read-only) and app (read-write)
- `nginx-config`: Secret volume for nginx configuration
- `db-data`: MariaDB persistent storage

## Security

- Database credentials stored in Azure Key Vault
- Generated using ephemeral Terraform resources
- Container Apps uses managed identity for Key Vault access

## Docker references from Matomo

- <https://github.com/matomo-org/docker>

- <https://github.com/libresh/compose-matomo/tree/master>
