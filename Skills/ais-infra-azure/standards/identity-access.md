# Identity & Access Standards

All rules apply by default. Exceptions require documentation per the
[exception process](../SKILL.md#exceptions).

## Rules

| ID | Rule | Default | Exception criteria |
|----|------|---------|-------------------|
| SEC-IAM-001 | Managed identity for all service-to-service auth | MUST | Third-party services that don't support MI |
| SEC-IAM-002 | No access keys/connection strings in config | MUST | Never — use Key Vault references or MI |
| SEC-IAM-003 | RBAC scoped to resource or resource group (not subscription) | MUST | Platform-level automation with dedicated service principal |
| SEC-IAM-004 | No Owner/Contributor for workload identities | MUST | Break-glass accounts with PIM and audit |
| SEC-IAM-005 | Separate identities per workload/environment | MUST | Shared dev environments with documented boundary |
| SEC-IAM-006 | User-assigned managed identity preferred over system-assigned | SHOULD | Simple single-resource deployments |
| SEC-IAM-007 | Federated credentials for CI/CD (no stored secrets) | MUST | Self-hosted runners without Azure AD integration |
| SEC-IAM-008 | Key Vault access via RBAC (not access policies) | MUST | Legacy Key Vaults with documented migration plan |

## Design Guidance

### Managed Identity Selection

| Type | When |
|------|------|
| User-assigned | Shared across resources, survives redeployment, explicit lifecycle |
| System-assigned | Single tightly-coupled resource, simpler but deleted with resource |

Default to **user-assigned** for production workloads. System-assigned is
acceptable for single-purpose resources with no identity sharing needs.

### RBAC Assignments in IaC

- Define role assignments in IaC alongside the resources they protect
- Use built-in roles; avoid custom roles unless truly necessary
- Scope to the narrowest level: resource > resource group > subscription
- For Bicep: use `Microsoft.Authorization/roleAssignments` with `principalType: 'ServicePrincipal'`
- For Terraform: use `azurerm_role_assignment` with condition blocks

### Secrets & Credentials

| Location | Allowed? |
|----------|----------|
| Source code | Never |
| Parameter files / `.tfvars` | Never |
| CI/CD pipeline variables (plain) | Never |
| Key Vault secrets | Yes — accessed via MI or federated credential |
| CI/CD secret variables (masked) | Only for bootstrap (Key Vault URI, tenant ID) |
| Terraform state | Never store secrets as outputs; mark `sensitive = true` |
| Bicep outputs | Never output secret values; reference Key Vault directly |

### CI/CD Authentication

- Use **workload identity federation** (OIDC) for GitHub Actions → Azure
- Configure federated credentials scoped to specific repos/branches/environments
- No stored client secrets for production deployments
- Separate service principals per environment with least-privilege RBAC

## Validation Checks

The validation script checks for:

- Hardcoded secrets, connection strings, or passwords in IaC files
- Access keys or SAS tokens in parameter/variable files
- Role assignments scoped at subscription level without justification
- Missing `principalType` in Bicep role assignment resources

## References

- [Managed identities overview](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview)
- [Workload identity federation](https://learn.microsoft.com/entra/workload-id/workload-identity-federation)
- [Azure RBAC best practices](https://learn.microsoft.com/azure/role-based-access-control/best-practices)
- See `../references/BICEP-PATTERNS.md` and `../references/TERRAFORM-PATTERNS.md` for code examples
