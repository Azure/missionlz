# Terraform Patterns & Conventions

Standard patterns for Terraform files in projects using this skill.

## File Layout

```text
main.tf              — Root module: composes AVM modules
variables.tf         — Input variable declarations
outputs.tf           — Output values
providers.tf         — Provider config + version constraints
backend.tf           — Remote state configuration
locals.tf            — Computed locals (naming, tags, etc.)
data.tf              — Data sources (existing resources, Key Vault secrets)
terraform.tfvars     — Default variable values (non-secret)
environments/        — Per-environment variable overrides
modules/             — Custom modules (only when AVM insufficient)
tests/               — Terraform test framework tests
```

## Root Module Pattern (main.tf)

```hcl
# main.tf — Composes AVM modules; contains no inline resource definitions
# for resources that have an AVM module available.

module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.1.0"

  name     = local.names.resource_group
  location = var.location
  tags     = local.tags
}

module "kv" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.7.0"

  name                = local.names.key_vault
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags

  managed_identities = {
    system_assigned = true
  }
}
```

## Variables Pattern

```hcl
# variables.tf

variable "environment" {
  type        = string
  description = "Environment identifier (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for all resources"
  default     = "canadacentral"
}

variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to merge with defaults"
  default     = {}
}
```

## Locals & Naming Pattern

```hcl
# locals.tf

locals {
  prefix = "${var.project_name}-${var.environment}"

  # CAF-compliant naming
  names = {
    resource_group   = "rg-${local.prefix}"
    storage_account  = "st${replace(local.prefix, "-", "")}"
    key_vault        = "kv-${local.prefix}"
    app_service_plan = "asp-${local.prefix}"
    app_service      = "app-${local.prefix}"
    sql_server       = "sql-${local.prefix}"
    vnet             = "vnet-${local.prefix}"
    subnet           = "snet-${local.prefix}"
    nsg              = "nsg-${local.prefix}"
    managed_identity = "id-${local.prefix}"
    log_analytics    = "log-${local.prefix}"
    app_insights     = "appi-${local.prefix}"
    container_reg    = "cr${replace(local.prefix, "-", "")}"
    aks_cluster      = "aks-${local.prefix}"
  }

  # Required tags (merged with user-provided)
  tags = merge({
    environment = var.environment
    project     = var.project_name
    managed-by  = "terraform"
    owner       = "team-name"
    cost-center = "CC-1234"
  }, var.tags)
}
```

## Alternative: CAF Naming Provider

```hcl
# Use azurecaf provider for automatic CAF-compliant naming
provider "azurecaf" {}

resource "azurecaf_name" "rg" {
  name          = var.project_name
  resource_type = "azurerm_resource_group"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "kv" {
  name          = var.project_name
  resource_type = "azurerm_key_vault"
  suffixes      = [var.environment]
}
```

## Private Endpoint Pattern

```hcl
# All PaaS resources should use private endpoints in production
module "storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.2.0"

  name                = local.names.storage_account
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags

  network_rules = {
    default_action = "Deny"
  }

  private_endpoints = {
    blob = {
      subnet_resource_id = module.vnet.subnets["private-endpoints"].resource_id
      private_dns_zone_resource_ids = [
        module.dns_blob.resource_id
      ]
    }
  }
}
```

## Managed Identity Pattern

```hcl
# Prefer managed identity over keys/connection strings
module "identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.0"

  name                = local.names.managed_identity
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags
}

# Assign roles via AVM module's role_assignments parameter
module "kv" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.7.0"

  name                = local.names.key_vault
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags

  role_assignments = {
    secrets_user = {
      principal_id               = module.identity.principal_id
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_type             = "ServicePrincipal"
    }
  }
}
```

## Diagnostic Settings Pattern

```hcl
# Enable diagnostics on all resources via AVM's built-in parameter
module "app_service" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.10.0"

  name                = local.names.app_service
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags
  os_type             = "Linux"
  service_plan_id     = module.asp.resource_id

  diagnostic_settings = {
    to_law = {
      workspace_resource_id = module.log_analytics.resource_id
      log_categories        = ["AppServiceHTTPLogs", "AppServiceConsoleLogs"]
      metric_categories     = ["AllMetrics"]
    }
  }
}
```

## Environment Promotion Pattern

```hcl
# environments/dev.tfvars
environment  = "dev"
location     = "canadacentral"
project_name = "myapp"

# environments/prod.tfvars
environment  = "prod"
location     = "canadacentral"
project_name = "myapp"
```

Deploy with:

```bash
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

## Sensitive Variable Handling

```hcl
# NEVER hardcode secrets — use Key Vault data source
data "azurerm_key_vault_secret" "db_password" {
  name         = "db-admin-password"
  key_vault_id = module.kv.resource_id
}

# Or mark variables as sensitive
variable "db_admin_password" {
  type        = string
  sensitive   = true
  description = "Database admin password — sourced from Key Vault in CI"
}
```

## Anti-Patterns (DO NOT)

| Anti-Pattern | Correct Approach |
|-------------|-----------------|
| Inline `azurerm_*` resource for AVM-covered types | Use AVM module |
| Hardcoded secrets in `.tfvars` | Key Vault data source or sensitive var |
| `*` in NSG rules | Explicit port ranges |
| Public endpoints in production | Private endpoints + NSG |
| Access keys for auth | Managed Identity + RBAC |
| No version pin on module source | Always pin: `version = "0.2.0"` |
| Committed `.tfstate` files | Remote backend (Azure Storage) |
| `terraform apply` without plan review | Always `plan` → review → `apply` |
| Single `.tfvars` for all environments | Per-environment `.tfvars` files |
| Unpinned provider versions | Use `~> 3.100` style constraints |
| Local state for shared environments | Remote state with locking |
| `depends_on` for data flow | Use module output references |
