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

## Troubleshooting

```bash

az containerapp list -o table

db_container=ca-matomo-db-dev
rg=rg-matomo-azure-containerapp-dev

# general troubleshooting
az containerapp exec -n $db_container -g $rg
az containerapp logs show -n $db_container -g $rg --follow --tail 30

# Check if MariaDB is actually running and accepting connections
az containerapp exec -n $db_container -g $rg 

mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT 1;"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;"
mysql -u matomo -p$MYSQL_PASSWORD -e "SELECT 1;"

# Web/App troubleshooting
web_container=ca-matomo-web-dev
app_container=ca-matomo-app-dev
rg=rg-matomo-azure-containerapp-dev

# Check if matomo files exist in web container
az containerapp exec -n $web_container -g $rg --command "ls -la /var/www/html/"

# Check if matomo files exist in app container  
az containerapp exec -n $app_container -g $rg --command "ls -la /var/www/html/"

# If the entrypoint for the app container fails to run, then matomo
# files will be missing from /var/www/html.  These are copied to 
# this location by the /entrypoint.sh script

# if this partially completes, it can lead to an issue if the matomo.php
# file exists - as this is used as the check

# a workaround is to re-run the entrypoint script:
# /var/www/html $ /entrypoint.sh
```
