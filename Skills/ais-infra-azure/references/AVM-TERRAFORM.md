# AVM Module Lookup (Terraform)

Do NOT rely on hardcoded module names. Always look up modules dynamically.

## How to Find AVM Modules

### 1. Browse the Module Index (authoritative)

```
https://aka.ms/avm/moduleindex
```

### 2. Search the Terraform Registry

```
https://registry.terraform.io/namespaces/Azure
```

Filter by module name prefix:
- `avm-res-` for resource modules
- `avm-ptn-` for pattern modules
- `avm-utl-` for utility modules

### 3. Search GitHub

```
https://github.com/orgs/Azure/repositories?q=terraform-azurerm-avm
```

## Module Naming Convention

AVM Terraform modules follow a predictable naming pattern:

```text
Azure/avm-res-{provider}{resource}/azurerm          — Resource modules
Azure/avm-ptn-{pattern-name}/azurerm                — Pattern modules
Azure/avm-utl-{utility-name}/azurerm                — Utility modules
```

The `{provider}{resource}` maps to the ARM resource provider namespace with
dots and slashes removed and lowercased. Examples:

| ARM Resource Type | AVM Module Source |
|-------------------|------------------|
| `Microsoft.Storage/storageAccounts` | `Azure/avm-res-storage-storageaccount/azurerm` |
| `Microsoft.Network/virtualNetworks` | `Azure/avm-res-network-virtualnetwork/azurerm` |
| `Microsoft.KeyVault/vaults` | `Azure/avm-res-keyvault-vault/azurerm` |
| `Microsoft.ContainerService/managedClusters` | `Azure/avm-res-containerservice-managedcluster/azurerm` |

**Derivation rule**: Take the ARM type → drop `Microsoft.` → lowercase → remove
`/` between provider and resource → hyphenate → prefix with `avm-res-`.

## Version Pinning

Always pin to a specific version. Never use unpinned module sources.

```hcl
# CORRECT — pinned version
module "storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.2.0"

  name                = local.names.storage_account
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}

# WRONG — no version pin
module "storage" {
  source = "Azure/avm-res-storage-storageaccount/azurerm"
  # missing version!
}

# WRONG — git source without ref
module "storage" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-storage-storageaccount.git"
}
```

## AVM Module Common Interfaces

All AVM Terraform modules support these standard parameters:

| Variable | Type | Purpose |
|----------|------|---------|
| `name` | string | Resource name |
| `location` | string | Azure region |
| `resource_group_name` | string | Target resource group |
| `tags` | map(string) | Resource tags |
| `lock` | object | Resource lock configuration |
| `role_assignments` | map(object) | RBAC role assignments |
| `diagnostic_settings` | map(object) | Diagnostic settings (logs + metrics) |
| `managed_identities` | object | System/user-assigned identity config |
| `private_endpoints` | map(object) | Private endpoint connections |

## Module Categories

| Category | Source Prefix | Purpose |
|----------|--------------|---------|
| Resource modules | `Azure/avm-res-*` | Single Azure resource, full config surface |
| Pattern modules | `Azure/avm-ptn-*` | Multi-resource compositions (e.g., hub-spoke) |
| Utility modules | `Azure/avm-utl-*` | Helpers (shared types, naming) |

## State Backend Configuration

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "project.terraform.tfstate"
    use_azuread_auth     = true  # Prefer AAD over access keys
  }
}
```

## Provider Configuration

```hcl
# providers.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"  # Pin to minor version range
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2"    # CAF naming provider
    }
  }
}

provider "azurerm" {
  features {}
}
```

## Testing with Terraform Test Framework

```hcl
# tests/main.tftest.hcl
run "validate_naming" {
  command = plan

  variables {
    environment  = "dev"
    project_name = "test"
    location     = "canadacentral"
  }

  assert {
    condition     = startswith(module.rg.name, "rg-")
    error_message = "Resource group must follow CAF naming: rg-*"
  }
}
```
