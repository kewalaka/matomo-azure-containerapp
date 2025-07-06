output "resource_group_name" {
  value = local.resource_group_name
}

output "matomo_web_url" {
  value       = module.container_apps["web"].fqdn_url
  description = "The public URL for the Matomo web interface"
}

output "container_app_names" {
  value = {
    for k, v in module.container_apps : k => v.name
  }
  description = "The names of the deployed Container Apps"
}
