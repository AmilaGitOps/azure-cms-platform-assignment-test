variable "project" {
  description = "Project/application short name."
  type        = string
  default     = "webco-cms"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region. Australia East is used for the Australian platform assumption."
  type        = string
  default     = "australiaeast"
}

variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
  default     = "rg-webco-cms-dev-aue"
}

variable "postgres_admin_username" {
  description = "PostgreSQL administrator username."
  type        = string
  default     = "cmsadmin"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password. Set through TF_VAR_postgres_admin_password or a secure CI secret. Do not commit real values."
  type        = string
  sensitive   = true
}

variable "directus_key" {
  description = "Directus KEY secret. Set through TF_VAR_directus_key or a secure CI secret. Do not commit real values."
  type        = string
  sensitive   = true
}

variable "directus_secret" {
  description = "Directus SECRET value. Set through TF_VAR_directus_secret or a secure CI secret. Do not commit real values."
  type        = string
  sensitive   = true
}

variable "container_image" {
  description = "Directus container image to run in Azure Container Apps."
  type        = string
  default     = "directus/directus:latest"
}

variable "container_cpu" {
  description = "Container CPU allocation."
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Container memory allocation."
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum Container Apps replicas."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum Container Apps replicas."
  type        = number
  default     = 3
}

variable "allowed_public_ip_ranges" {
  description = "Optional public IP ranges allowed to access PostgreSQL. Empty list means no public firewall rules are created."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    owner       = "platform"
    workload    = "directus-cms"
    managed_by  = "terraform"
  }
}
