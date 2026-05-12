data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  name_prefix          = "${var.project}-${var.environment}"
  safe_suffix          = random_string.suffix.result
  storage_account_name = lower(replace("st${var.project}${var.environment}${local.safe_suffix}", "-", ""))
  key_vault_name       = substr(replace("kv-${local.name_prefix}-${local.safe_suffix}", "_", "-"), 0, 24)

  common_tags = merge(var.tags, {
    environment = var.environment
    project     = var.project
  })
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${local.name_prefix}-${local.safe_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${local.name_prefix}-${local.safe_suffix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.common_tags
}

resource "azurerm_storage_account" "media" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  shared_access_key_enabled       = false
  tags                            = local.common_tags

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "media_assets" {
  name                  = "media-assets"
  storage_account_name  = azurerm_storage_account.media.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = true
  tags                       = local.common_tags
}

resource "azurerm_role_assignment" "terraform_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "directus_key" {
  name         = "directus-key"
  value        = var.directus_key
  key_vault_id = azurerm_key_vault.main.id
  content_type = "Directus KEY"
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "directus_secret" {
  name         = "directus-secret"
  value        = var.directus_secret
  key_vault_id = azurerm_key_vault.main.id
  content_type = "Directus SECRET"
  depends_on   = [azurerm_role_assignment.terraform_kv_secrets_officer]
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${local.name_prefix}-${local.safe_suffix}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  administrator_login    = var.postgres_admin_username
  administrator_password = var.postgres_admin_password
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  backup_retention_days  = 7
  zone                   = "1"
  tags                   = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "cms_db" {
  name      = "cms_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allowed_public_ips" {
  for_each         = toset(var.allowed_public_ip_ranges)
  name             = "allow-${replace(each.value, "/", "-")}"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = split("/", each.value)[0]
  end_ip_address   = split("/", each.value)[0]
}

resource "azurerm_user_assigned_identity" "container_app" {
  name                = "id-${local.name_prefix}-${local.safe_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "container_app_kv_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

resource "azurerm_role_assignment" "container_app_blob_contributor" {
  scope                = azurerm_storage_account.media.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

resource "azurerm_container_app" "directus" {
  name                         = "ca-directus-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app.id]
  }

  secret {
    name                = "directus-key"
    key_vault_secret_id = azurerm_key_vault_secret.directus_key.versionless_id
    identity            = azurerm_user_assigned_identity.container_app.id
  }

  secret {
    name                = "directus-secret"
    key_vault_secret_id = azurerm_key_vault_secret.directus_secret.versionless_id
    identity            = azurerm_user_assigned_identity.container_app.id
  }

  ingress {
    external_enabled = true
    target_port      = 8055
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "directus"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "PUBLIC_URL"
        value = "https://cms.example.com"
      }
      env {
        name  = "DB_CLIENT"
        value = "pg"
      }
      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name  = "DB_DATABASE"
        value = azurerm_postgresql_flexible_server_database.cms_db.name
      }
      env {
        name  = "DB_USER"
        value = var.postgres_admin_username
      }
      env {
        name        = "KEY"
        secret_name = "directus-key"
      }
      env {
        name        = "SECRET"
        secret_name = "directus-secret"
      }
      env {
        name  = "STORAGE_LOCATIONS"
        value = "azure"
      }
      env {
        name  = "STORAGE_AZURE_DRIVER"
        value = "azure"
      }
      env {
        name  = "STORAGE_AZURE_CONTAINER_NAME"
        value = azurerm_storage_container.media_assets.name
      }
      env {
        name  = "STORAGE_AZURE_ACCOUNT_NAME"
        value = azurerm_storage_account.media.name
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.container_app_kv_reader,
    azurerm_postgresql_flexible_server_database.cms_db,
    azurerm_storage_container.media_assets
  ]
}
