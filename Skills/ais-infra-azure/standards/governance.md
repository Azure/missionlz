# Governance Standards

All rules apply by default. Exceptions require documentation per the
[exception process](../SKILL.md#exceptions).

## Rules

| ID | Rule | Default | Exception criteria |
|----|------|---------|-------------------|
| GOV-001 | Defender for Cloud Standard tier enabled on all production subscriptions | MUST | Dev/test subscriptions with no sensitive data (Free tier acceptable) |
| GOV-002 | Azure Policy assignments in place before first production deployment | MUST | Greenfield with documented timeline for policy rollout |
| GOV-003 | Built-in regulatory compliance initiative assigned (CIS, NIST, or equivalent) | SHOULD | Internal tools with no regulatory obligations |
| GOV-004 | Defender for Cloud security score reviewed before go-live | MUST | Non-production environments |
| GOV-005 | Resource-level Defender plans enabled for: Servers, Storage, SQL, Key Vault, Containers | SHOULD | Resources not yet generally available in target region |
| GOV-006 | Continuous export of Defender alerts to Log Analytics workspace | MUST | Dev-only environments with no on-call |
| GOV-007 | Azure Policy deny effects used for critical compliance controls | SHOULD | When only audit visibility is needed initially |
| GOV-008 | Policy compliance report reviewed and zero critical violations before production release | MUST | Violations with documented remediation plan and timeline |

## Design Guidance

### Defender for Cloud

Defender for Cloud provides two capabilities relevant to all Azure workloads:

| Capability | What it does | Enforce via |
|-----------|-------------|-------------|
| Cloud Security Posture Management (CSPM) | Detects misconfigurations, scores security posture | Always-on at subscription level |
| Cloud Workload Protection (CWP) | Runtime threat detection per resource type | Enable per resource type (Servers, Storage, SQL, etc.) |

**CSPM is free** and enabled by default on all subscriptions — no reason to disable it.
**CWP** has per-resource pricing — enable for production workloads handling sensitive data.

Recommended Defender plans for most workloads:

| Resource type | Defender plan |
|--------------|--------------|
| Azure SQL / Cosmos DB | Defender for SQL / Cosmos DB |
| Storage accounts | Defender for Storage |
| Key Vault | Defender for Key Vault |
| AKS clusters | Defender for Containers |
| App Service | Defender for App Service |
| VMs (if applicable) | Defender for Servers |

### Azure Policy

Azure Policy is the primary enforcement mechanism for compliance at scale.
Use it to **prevent** non-compliant resources from being created (deny effects)
and **audit** existing drift.

| Mode | When |
|------|------|
| Audit | Initial rollout — see drift without blocking deployments |
| Deny | Once teams understand what's blocked — prevents non-compliant resources |
| DeployIfNotExists | Automatically remediate — e.g., auto-deploy diagnostic settings |

**Built-in initiatives to assign** (pick the one matching your compliance requirements):

| Initiative | Use when |
|-----------|---------|
| Azure Security Benchmark | General Azure best practices baseline |
| CIS Microsoft Azure Foundations Benchmark | Security-focused organisations |
| NIST SP 800-53 | US federal or regulated workloads |
| ISO 27001 | ISO-certified organisations |
| PCI DSS | Payment card data in scope |
| HIPAA/HITRUST | Healthcare data |

### Policy as Code

Define policy assignments in IaC alongside the resources they protect:

#### Bicep

```bicep
module policyAssignment 'br/public:avm/res/authorization/policy-assignment:X.Y.Z' = {
  name: 'asbPolicyAssignment'
  params: {
    name: 'asb-baseline'
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8'
    location: location
    identity: { type: 'SystemAssigned' }
    parameters: {}
  }
}
```

#### Terraform

```hcl
resource "azurerm_subscription_policy_assignment" "asb" {
  name                 = "asb-baseline"
  display_name         = "Azure Security Benchmark"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
  subscription_id      = data.azurerm_subscription.current.id
  location             = var.location
  identity { type = "SystemAssigned" }
}
```

### Continuous Export

Export Defender alerts and recommendations to Log Analytics for SIEM integration:

```hcl
resource "azurerm_security_center_automation" "export" {
  name                = "defender-export-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_subscription.current.id]

  action {
    type        = "LogicApp"
    resource_id = azurerm_logic_app_workflow.siem_export.id
  }

  source {
    event_source = "Alerts"
    rule_set {
      rule {
        property_path  = "properties.metadata.severity"
        operator       = "Equals"
        expected_value = "High"
        property_type  = "String"
      }
    }
  }
}
```

Or use the simpler Log Analytics workspace export via `azurerm_security_center_workspace`.

## Validation Checks

The validation script currently does not check governance configuration (Azure
Policy and Defender are subscription-level, not file-level). Validate via:

```bash
# Check Defender for Cloud status
az security pricing list --output table

# Check policy compliance
az policy state summarize --subscription <id> --output table

# Check Defender secure score
az security secure-scores list --output table
```

Include policy compliance output as evidence in the spec's implementation-plan.md
before marking production deployment tasks complete.

## References

- [Defender for Cloud overview](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction)
- [Azure Policy overview](https://learn.microsoft.com/azure/governance/policy/overview)
- [Azure Security Benchmark](https://learn.microsoft.com/security/benchmark/azure/)
- [Regulatory compliance built-ins](https://learn.microsoft.com/azure/governance/policy/samples/)
- See `../references/BICEP-PATTERNS.md` and `../references/TERRAFORM-PATTERNS.md` for code examples
