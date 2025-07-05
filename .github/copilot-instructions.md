# Copilot Instructions for Matomo Azure Container Apps Project

## Project Overview
This is a Terraform project that deploys Matomo (web analytics) on Azure Container Apps using a three-tier architecture with separate Container Apps for database, application, and web tiers.

## Architecture Pattern
- **Database Tier**: MariaDB with internal-only ingress (external_enabled = false)
- **Application Tier**: Matomo PHP-FPM with internal-only ingress
- **Web Tier**: Nginx with external ingress (external_enabled = true)

## Key Azure Container Apps Concepts

### Ingress Configuration
- **External ingress**: `external_enabled = true` for public internet access
- **Internal ingress**: `external_enabled = false` for Container Apps environment internal communication
- **Database containers**: MUST have internal ingress (not no ingress) for inter-container communication
- **Internal FQDN pattern**: Container Apps use short names for internal communication (e.g., `ca-db-dev`, not full FQDN)

### Container Communication
- Use short container app names for container-to-container communication
- Example: `ca-db-dev` (not the full FQDN)
- Port exposure via `ports` section is for service discovery
- Target port in ingress is for actual traffic routing

## File Structure and Patterns

### Locals Organization
- `locals.tf`: Main coordination and secret definitions
- `locals.containers.{name}.tf`: Individual container definitions
- Each container defines its own volumes, secrets, and ingress requirements

### Container Definition Structure
Each container local must include:
```terraform
{
  name, image, cpu, memory, min_replicas, max_replicas
  azure_name           # Container App name in Azure, used for inter-container communication
  env_vars = {}        # Regular environment variables
  secrets = {}         # References to secret names
  volume_mounts = []   # Volume mount definitions
  volumes = []         # Volume definitions (AzureFile, Secret, EmptyDir)
  required_secrets = [] # List of secret keys this container needs
  ports = []           # Port exposure for service discovery
  ingress = {}         # Ingress configuration (internal or external)
  command = null       # Container command override
  args = []            # Container arguments
}
```

### Secret Management
- Secrets defined in `secret_definitions` in locals.tf
- Referenced by name in container `required_secrets` array
- MySQL passwords: `mysql_root_password` and `mysql_user_password`
- User password must be same value in both MySQL and Matomo containers

## Database Configuration (MariaDB)

### Critical Environment Variables
```terraform
env_vars = {
  MARIADB_AUTO_UPGRADE = "1"
  MARIADB_DISABLE_UPGRADE_BACKUP = "1"
  MARIADB_INITDB_SKIP_TZINFO = "1"
  MYSQL_DATABASE = "matomo"
  MYSQL_USER = "matomo"
}
secrets = {
  MYSQL_ROOT_PASSWORD = "mysql-root-password"
  MYSQL_PASSWORD = "mysql-user-password"
}
```

### Database Ingress (REQUIRED)
```terraform
ingress = {
  target_port = 3306
  external_enabled = false  # Internal only - this is KEY
  transport = "tcp"
}
```

### MariaDB Command Arguments
- Use `args = ["--max-allowed-packet=64MB"]` not `command`
- MariaDB Docker image needs entrypoint to run initialization scripts

## Volume Strategy
- **db-data**: AzureFile for database persistence (MySQL only)
- **matomo-data**: AzureFile shared between app (RW) and web (RO)
- **nginx-config**: Secret volume for web server configuration

## Azure CLI Commands for Container Apps

### Debugging Commands
```bash
# Shell into container (interactive)
az containerapp exec -n <container-name> -g <resource-group>

# Run specific command (must be quoted)
az containerapp exec -n <container-name> -g <resource-group> --command "ls -la /var/www/html/"

# View logs
az containerapp logs show -n <container-name> -g <resource-group> --follow --tail 30

# Test connectivity (use nc, not telnet)
nc -zv <target-host> <port>
```

## Common Mistakes to Avoid
1. **Don't** set database ingress to null - it needs internal ingress
2. **Don't** use `command` for MariaDB - use `args` for MySQL parameters
3. **Don't** use full FQDN for inter-container communication - use short names
4. **Don't** mix different password values between MySQL and Matomo containers
5. **Don't** use `external_enabled = true` for database or app tiers
6. **Don't** use telnet for connectivity testing - use `nc` instead

## Environment Variable Alignment
The docker-compose setup in `/app` directory is the authoritative source for environment variable names and values. Terraform configuration must match the working docker-compose setup.

## Testing Strategy
Use the docker-compose setup in `/app` directory to validate configuration before deploying to Azure. The `db.env` file contains the authoritative environment variable definitions.

## Matomo Container Initialization Issues

### Common Problem: Missing index.php and Matomo Files
The `matomo:fpm-alpine` image requires proper initialization to extract files to `/var/www/html`. If files are missing:

#### Root Cause
- Azure File share mounting can interfere with container initialization
- Matomo entrypoint script checks for `matomo.php` and skips initialization if found
- Volume timing issues prevent file extraction

#### Debugging Steps
```bash
# Check if Matomo files are missing
ls -la /var/www/html/ | grep index.php

# Check if entrypoint script exists
ls -la /entrypoint.sh

# Check if source files exist
ls -la /usr/src/matomo/

# Check mount points
mount | grep /var/www/html

# Test file system permissions
touch /var/www/html/test.txt && rm /var/www/html/test.txt

# Check if matomo.php exists (prevents initialization)
ls -la /var/www/html/matomo.php
```

#### Manual Fix (if needed)
```bash
# Delete matomo.php if it exists (allows re-initialization)
rm -f /var/www/html/matomo.php

# Change to correct directory before running entrypoint
cd /var/www/html

# Run the entrypoint script manually
/entrypoint.sh php-fpm &

# Or copy files manually from source
cp -r /usr/src/matomo/* /var/www/html/

# Set proper permissions
chown -R www-data:www-data /var/www/html
```

#### Terraform Fix
Consider using EmptyDir instead of AzureFile for initial testing:
```terraform
volumes = [
  {
    name         = "matomo-data"
    storage_type = "EmptyDir"  # Use instead of AzureFile for testing
  }
]
```

### Volume Strategy Considerations
- **EmptyDir**: Good for testing, allows proper initialization, but not persistent
- **AzureFile**: Persistent but can interfere with initialization if mounted too early
- **Solution**: Initialize with EmptyDir, then consider init containers for persistent storage
- **Critical**: Matomo entrypoint checks for `matomo.php` existence and skips