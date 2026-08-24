# Deployment & State Management Standards

All rules apply by default. Exceptions require documentation per the
[exception process](../SKILL.md#exceptions).

## Rules

| ID | Rule | Default | Exception criteria |
|----|------|---------|-------------------|
| DEPLOY-001 | CI/CD pipeline for all shared environments | MUST | Local development only |
| DEPLOY-002 | No manual deployments to staging/production | MUST | Emergency hotfix with post-hoc IaC update |
| DEPLOY-003 | Pre-merge validation: lint + plan/what-if | MUST | Never |
| DEPLOY-004 | Azure Policy compliance check before merge | MUST | Policy not yet configured (document timeline) |
| DEPLOY-005 | Environment promotion via parameter/tfvars files | MUST | Single-environment workloads |
| DEPLOY-006 | Deployment evidence captured (resource IDs, diffs) | MUST | Never |
| DEPLOY-007 | Rollback procedure documented | MUST | Stateless resources recreatable from IaC |

## Bicep Deployment

| Rule | Detail |
|------|--------|
| **Deployment method** | Azure Deployment Stacks (preferred) or standard resource group deployments |
| **Environment promotion** | Parameter files per environment (`.bicepparam`) |
| **Secret handling** | Key Vault references in parameter files; never hardcode secrets |
| **Rollback** | Deployment Stacks with deny settings or documented manual rollback procedure |
| **What-if** | Required on every PR; reviewed for unexpected deletions/replacements |

### Deployment Stacks (recommended)

```bash
# Create/update a deployment stack
az stack group create \
  --name myapp-prod \
  --resource-group rg-myapp-prod-eus2-001 \
  --template-file main.bicep \
  --parameters environments/prod.bicepparam \
  --deny-settings-mode denyWriteAndDelete \
  --action-on-unmanage deleteResources
```

## Terraform Deployment

| Rule | Detail |
|------|--------|
| **State backend** | Azure Storage Account with container-level locking (`azurerm` backend) |
| **Workspaces or directories** | Use Terraform workspaces OR per-environment directories — decide in architecture |
| **Environment promotion** | `.tfvars` files per environment |
| **Secret handling** | Key Vault data sources or `sensitive = true` variables; never hardcode secrets |
| **Rollback** | State-based rollback with `terraform plan -target` or prior state version restore |
| **Plan** | Required on every PR; auto-posted as PR comment |

### State Backend Configuration

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-prod-eus2-001"
    storage_account_name = "sttfstateprodeus2001"
    container_name       = "tfstate"
    key                  = "myapp.prod.terraform.tfstate"
    use_oidc             = true  # Prefer OIDC over access keys
  }
}
```

### State Security

| Rule | Detail |
|------|--------|
| Storage Account with private endpoint | State is sensitive; no public access |
| Container-level RBAC | Service principal gets `Storage Blob Data Contributor` on state container only |
| Versioning enabled | Allows state rollback |
| Soft delete enabled | Prevents accidental state loss |
| State locking | Enabled by default with `azurerm` backend |

## CI/CD Pipeline Requirements

### Pre-merge (PR gate)

1. Lint pass (zero errors, zero warnings)
2. `plan` / `what-if` output posted as PR comment
3. No unexpected resource deletions without approval
4. Policy compliance check
5. Validation script pass

### Post-merge (deployment)

1. Apply/deploy to target environment
2. Capture deployment output (resource IDs, timestamps)
3. Post-deployment validation (smoke test / health check)
4. Update implementation-plan.md with evidence

### Environment Flow

```text
PR → lint + plan → merge → deploy dev → smoke test → promote staging → test → promote prod
```

## Validation Checks

The validation script checks for:

- Committed `.tfstate` files
- Missing remote backend configuration
- Hardcoded secrets in parameter/variable files
- Missing environment-specific parameter files

## References

- [Deployment Stacks](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deployment-stacks)
- [Terraform AzureRM backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
- [GitHub Actions for Azure](https://learn.microsoft.com/azure/developer/github/github-actions)
- See `../ci/README.md` for pipeline snippet templates
