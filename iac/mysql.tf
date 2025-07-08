module "avm-res-dbformysql-flexibleserver" {
  source  = "Azure/avm-res-dbformysql-flexibleserver/azurerm"
  version = "0.1.1"

  name                   = local.mysql_server_name
  resource_group_name    = data.azurerm_resource_group.this.name
  location               = data.azurerm_resource_group.this.location
  administrator_login    = "mysqladmin"
  administrator_password = random_password.mysql_root_password.result
  sku_name               = "B_Standard_B1ms"
  zone                   = 1
  databases = {
    matomo = {
      charset   = "utf8"
      collation = "utf8_unicode_ci"
      name      = "matomo"
    }
  }
  firewall_rules = {
    access_azure = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }
  tags = local.default_tags
}

resource "mysql_user" "matomo" {
  user               = "matomo"
  plaintext_password = random_password.mysql_user_password.result
}

