# Naming & Tagging Standards

All rules apply by default. Exceptions require documentation per the
[exception process](../SKILL.md#exceptions).

## Naming Rules

| ID | Rule | Default | Exception criteria |
|----|------|---------|-------------------|
| CAF-NAME-001 | Follow [CAF naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming) | MUST | Never |
| CAF-NAME-002 | Use standard CAF abbreviations (`rg-`, `st`, `kv-`, `vnet-`, etc.) | MUST | Client-mandated naming scheme (document in constitution) |
| CAF-NAME-003 | Include environment token in name (`dev`, `stg`, `prod`) | MUST | Resources shared across environments |
| CAF-NAME-004 | Include region abbreviation for multi-region workloads | SHOULD | Single-region deployments |
| CAF-NAME-005 | Use AVM naming module or CAF naming provider | SHOULD | Simple deployments with <5 resource types |

## Tagging Rules

| ID | Rule | Default | Exception criteria |
|----|------|---------|-------------------|
| CAF-TAG-001 | Minimum tags: `environment`, `project`, `owner`, `cost-center`, `managed-by` | MUST | Never |
| CAF-TAG-002 | `managed-by` tag set to `bicep` or `terraform` | MUST | Manually managed resources (document in ADR) |
| CAF-TAG-003 | Additional tags: `data-classification`, `compliance` for regulated workloads | SHOULD | Non-regulated internal workloads |
| CAF-TAG-004 | Tags defined in a single tags variable/object (DRY) | MUST | Never |
| CAF-TAG-005 | Tags validated in CI pipeline | MUST | Never |

## Design Guidance

### Naming Pattern

```text
{resource-abbreviation}-{project}-{environment}-{region}-{instance}
```

Examples:

| Resource | Name |
|----------|------|
| Resource Group | `rg-myapp-prod-eus2-001` |
| Storage Account | `stmyappprodeus2001` (no hyphens, 24-char limit) |
| Key Vault | `kv-myapp-prod-eus2-001` |
| VNet | `vnet-myapp-prod-eus2-001` |
| Subnet | `snet-myapp-web-prod-eus2-001` |
| App Service | `app-myapp-prod-eus2-001` |
| SQL Server | `sql-myapp-prod-eus2-001` |

### CAF Abbreviations Reference

| Resource | Abbreviation | Max length | Constraints |
|----------|-------------|-----------|-------------|
| Resource Group | `rg-` | 90 | Alphanumeric, hyphens, underscores, periods |
| Storage Account | `st` | 24 | Lowercase alphanumeric only |
| Key Vault | `kv-` | 24 | Alphanumeric and hyphens |
| Virtual Network | `vnet-` | 64 | Alphanumeric, hyphens, underscores, periods |
| Subnet | `snet-` | 80 | Alphanumeric, hyphens, underscores, periods |
| Network Security Group | `nsg-` | 80 | Alphanumeric, hyphens, underscores, periods |
| App Service | `app-` | 60 | Alphanumeric and hyphens |
| Function App | `func-` | 60 | Alphanumeric and hyphens |
| SQL Database | `sqldb-` | 128 | Cannot use `<>*%&:\/?` or end with `.`/space |
| Cosmos DB | `cosmos-` | 44 | Lowercase alphanumeric and hyphens |
| AKS Cluster | `aks-` | 63 | Alphanumeric and hyphens |

Full list: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

### Naming Module Usage

#### Bicep (CAF naming utility)

```bicep
module naming 'br/public:avm/utl/naming/convention:X.Y.Z' = {
  name: 'naming'
  params: {
    prefix: ['myapp']
    suffix: [environment, region]
    uniqueLength: 4
  }
}
```

#### Terraform (Azure CAF naming provider)

```hcl
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "X.Y.Z"
  prefix  = ["myapp"]
  suffix  = [var.environment, var.location_short]
}
```

### Required Tags Object

#### Bicep

```bicep
var tags = {
  environment: environment
  project: projectName
  owner: owner
  'cost-center': costCenter
  'managed-by': 'bicep'
}
```

#### Terraform

```hcl
locals {
  tags = {
    environment         = var.environment
    project             = var.project_name
    owner               = var.owner
    cost-center         = var.cost_center
    managed-by          = "terraform"
  }
}
```

### Resource Groups

| Rule | Detail |
|------|--------|
| One purpose per resource group | Lifecycle-aligned grouping |
| Environment isolation | Separate resource groups per environment |
| Never mix IaC-managed and manual resources | Manual resources get their own RG with documentation |

## Validation Checks

The validation script checks for:

- Missing required tags in resource definitions
- Non-CAF-compliant resource names
- Inline tag definitions (should reference shared tags variable)
- Resource groups without `environment` tag

## References

- [CAF naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [CAF abbreviations](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
- [Tagging strategy](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging)
