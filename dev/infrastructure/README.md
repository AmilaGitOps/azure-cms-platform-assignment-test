# Task 1 - Azure Infrastructure as Code

This folder contains Terraform for the Task 1 core Azure infrastructure:

- Azure Container Apps to host Directus
- Azure Database for PostgreSQL Flexible Server with database `cms_db`
- Azure Key Vault with example secret references for `directus-key` and `directus-secret`
- Azure Blob Storage with a private container named `media-assets`

## Files

- `versions.tf` - Terraform and provider version constraints
- `variables.tf` - inputs with sensitive variables for secrets
- `main.tf` - Azure resources
- `outputs.tf` - useful deployment outputs
- `terraform.tfvars.example` - example only, no real values

## How secrets are handled

No real credentials are stored in this repo. Sensitive values are Terraform variables and should be provided through `TF_VAR_*` environment variables, a CI/CD secret store, or a local uncommitted `terraform.tfvars` file. Directus application secrets are stored in Azure Key Vault and referenced by Azure Container Apps using a user-assigned managed identity.

## Example commands

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```
