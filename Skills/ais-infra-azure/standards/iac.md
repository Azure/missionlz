# IaC Standards

## 1. Azure Verified Modules (AVM) First

AVM publishes modules for **both** Bicep and Terraform. Always prefer AVM.

| Rule | Detail |
|------|--------|
| **Module source (Bicep)** | Bicep Public Registry: `br/public:avm/res/*`, `br/public:avm/ptn/*` |
| **Module source (Terraform)** | Terraform Registry: `Azure/avm-res-*`, `Azure/avm-ptn-*` |
| **Fallback only** | Custom modules permitted ONLY when no AVM module exists for the resource type |
| **Exception process** | Document in an ADR: resource type, why AVM is insufficient, custom module location, upgrade plan |
| **Version pinning** | Always pin module versions explicitly — no `:latest` (Bicep), no unpinned `source` (Terraform) |
| **Update cadence** | Review AVM module versions quarterly; update when security patches available |

## 2. Language Choice

The project decides between Bicep or Terraform at architecture time. Both are
valid; mixing within a single project is NOT.

### If Bicep

| Rule | Detail |
|------|--------|
| **Style** | Follow [Bicep best practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices) |
| **Linting** | `az bicep lint` must pass with zero errors and zero warnings |
| **What-if** | All PRs touching `infra/` must include `az deployment group what-if` output |
| **No raw ARM** | Never commit raw ARM JSON; always use Bicep source |

### If Terraform

| Rule | Detail |
|------|--------|
| **Style** | Follow [Terraform style conventions](https://developer.hashicorp.com/terraform/language/syntax/style) and [AzureRM best practices](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) |
| **Linting** | `terraform validate` + `tflint` (with azurerm ruleset) must pass with zero errors |
| **Plan** | All PRs touching `infra/` must include `terraform plan` output |
| **State** | Remote state in Azure Storage with state locking; never commit `.tfstate` |
| **Provider pinning** | Pin `azurerm` provider version in `required_providers` block |

## 3. Module Selection Priority

### Bicep

```text
1. AVM Resource Module (br/public:avm/res/*)     — Single resource, full config
2. AVM Pattern Module (br/public:avm/ptn/*)      — Multi-resource pattern (e.g., hub-spoke)
3. AVM Utility Module (br/public:avm/utl/*)      — Helpers (naming, RBAC assignments)
4. Custom module with ADR justification           — Only when 1-3 don't exist
```

### Terraform

```text
1. AVM Resource Module (Azure/avm-res-*)          — Single resource, full config
2. AVM Pattern Module (Azure/avm-ptn-*)           — Multi-resource pattern
3. AVM Utility Module (Azure/avm-utl-*)           — Helpers
4. Custom module with ADR justification           — Only when 1-3 don't exist
```

### Dynamic Lookup

Do NOT hardcode module paths. Look them up dynamically:

- **Authoritative index**: https://aka.ms/avm/moduleindex
- **Bicep registry browse**: https://github.com/Azure/bicep-registry-modules/tree/main/avm/res
- **Terraform registry browse**: https://registry.terraform.io/namespaces/Azure (filter `avm-`)

**Derivation rules** (when you know the ARM resource type):

| Language | Pattern |
|----------|---------|
| Bicep | `br/public:avm/res/{provider}/{resource-type}:{version}` — lowercase ARM namespace, hyphenated |
| Terraform | `Azure/avm-res-{provider}{resource}/azurerm` — lowercase, dots/slashes removed |

Example: `Microsoft.Storage/storageAccounts` →
- Bicep: `br/public:avm/res/storage/storage-account:X.Y.Z`
- Terraform: `Azure/avm-res-storage-storageaccount/azurerm` version `X.Y.Z`

Always verify the module exists and get the latest version from the registry
before using it. Pin the version explicitly.

See `../references/AVM-MODULES.md` for Bicep lookup instructions.
See `../references/AVM-TERRAFORM.md` for Terraform lookup instructions.

## 4. Custom Module Requirements

When no AVM module exists and a custom module is necessary:

| Rule | Detail |
|------|--------|
| **Interface contract** | Custom modules MUST expose: `name`, `location`, `tags`, `lock`, `diagnostic_settings`/`diagnosticSettings` at minimum |
| **Security defaults** | Apply all SEC-* rules as module defaults; allow override only via explicit parameters |
| **Validation** | Module must pass the same lint/validate checks as AVM modules |
| **ADR** | Document: what AVM module was checked, when, why it's insufficient, and when to re-check |
| **Upgrade path** | Include a comment in the module source linking to the AVM module index for future migration |

## 5. File Structure

### Bicep project

```text
infra/
├── main.bicep                    # Orchestrator — composes modules
├── main.bicepparam               # Default parameters
├── environments/
│   ├── dev.bicepparam
│   ├── staging.bicepparam
│   └── prod.bicepparam
└── modules/                      # Custom modules (only when AVM insufficient)
    └── README.md                 # Documents why each custom module exists
```

### Terraform project

```text
infra/
├── main.tf                       # Root module — composes AVM modules
├── variables.tf                  # Input variable declarations
├── outputs.tf                    # Output values
├── providers.tf                  # Provider config + version constraints
├── backend.tf                    # Remote state configuration
├── terraform.tfvars              # Default variable values (non-secret)
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── modules/                      # Custom modules (only when AVM insufficient)
    └── README.md                 # Documents why each custom module exists
```
