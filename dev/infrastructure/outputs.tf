output "resource_group_name" {
  description = "Resource group containing Task 1 resources."
  value       = azurerm_resource_group.main.name
}

output "container_app_name" {
  description = "Azure Container App hosting Directus."
  value       = azurerm_container_app.directus.name
}

output "container_app_url" {
  description = "Directus Container App generated URL."
  value       = azurerm_container_app.directus.latest_revision_fqdn
}

output "postgres_database_name" {
  description = "CMS database name."
  value       = azurerm_postgresql_flexible_server_database.cms_db.name
}

output "key_vault_name" {
  description = "Key Vault containing example secret references."
  value       = azurerm_key_vault.main.name
}

output "media_container_name" {
  description = "Private Blob container for CMS media assets."
  value       = azurerm_storage_container.media_assets.name
}
