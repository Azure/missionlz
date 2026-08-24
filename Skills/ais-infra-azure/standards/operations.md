# Operational Excellence Standards

All rules apply by default. Exceptions require documentation per the
[exception process](../SKILL.md#exceptions).

## Rules

| ID | Rule | Default | Exception criteria |
|----|------|---------|-------------------|
| OPS-001 | Diagnostic settings: send all logs + metrics to Log Analytics | MUST | Cost-constrained dev (send errors only) |
| OPS-002 | Resource locks (CanNotDelete) on production stateful resources | MUST | Ephemeral/recreatable resources |
| OPS-003 | Backup configured for all stateful resources (DB, Storage, VM) | MUST | Stateless/recomputable resources |
| OPS-004 | Use AMBA (Azure Monitor Baseline Alerts) for alert definitions | MUST | Custom alerting framework with documented justification |
| OPS-005 | Alerts for: availability, error rate, latency, resource health | MUST | Non-critical dev/test resources |
| OPS-006 | Cost anomaly alerts on resource groups | SHOULD | Individual resource experimentation |
| OPS-007 | Auto-scale configured for production compute | SHOULD | Fixed-capacity workloads with documented justification |
| OPS-008 | Deployment slots for zero-downtime releases (App Service) | SHOULD | Batch/offline workloads |
| OPS-009 | Health probes configured on all load-balanced resources | MUST | Single-instance non-HA resources |
| OPS-010 | Activity log sent to central Log Analytics workspace | MUST | Never |
| OPS-011 | Azure Monitor action groups defined per environment | MUST | Dev-only with no on-call |
| OPS-012 | Resource health alerts for all production resources | SHOULD | Resources with custom health probes |

## Design Guidance

### Diagnostic Settings

Every resource MUST configure diagnostic settings:

```text
Required configuration:
- All log categories enabled (or explicit subset documented)
- All metrics enabled
- Destination: Log Analytics workspace (primary)
- Optional secondary: Storage Account (for long-term retention / compliance)
```

AVM modules expose `diagnosticSettings` (Bicep) or `diagnostic_settings` (Terraform)
as standard interface parameters — always populate them.
### Azure Monitor Baseline Alerts (AMBA)

AMBA is the **alerting equivalent of AVM** — it provides pre-built, best-practice
alert definitions deployed via Azure Policy. Use AMBA as the default alert
framework instead of hand-crafting alert rules.

| Aspect | Detail |
|--------|--------|
| **What** | Curated metric/log alerts for 100+ Azure resource types |
| **How** | Deployed as Azure Policy initiatives (assign at management group or subscription) |
| **Source** | [github.com/Azure/azure-monitor-baseline-alerts](https://github.com/Azure/azure-monitor-baseline-alerts) |
| **Docs** | [aka.ms/amba](https://aka.ms/amba) |
| **Deployment** | Bicep/Terraform via ALZ policy modules or standalone policy assignments |
| **Customization** | Override thresholds via policy parameters; disable individual alerts per-resource via tag |

#### AMBA Deployment Options

| Method | When |
|--------|------|
| ALZ Policy Integration | Landing zone deployments with management group hierarchy |
| Standalone Policy Assignment | Single subscription or resource group scope |
| Bicep module | `br/public:avm/ptn/monitoring/amba:X.Y.Z` (when available) |
| Terraform | Clone AMBA repo + deploy with `azurerm_management_group_policy_assignment` |

#### AMBA Coverage

AMBA provides alerts for:
- Compute (VMs, VMSS, AKS, App Service)
- Networking (VNet Gateway, ExpressRoute, Load Balancer, Front Door)
- Storage (Storage Accounts, Managed Disks)
- Databases (SQL, Cosmos DB, PostgreSQL, MySQL)
- Security (Key Vault, Defender for Cloud)
- Platform (Activity Log, Service Health, Resource Health)

If AMBA covers the resource type, use its alert definitions. Only create custom
alerts for application-specific metrics not covered by AMBA.

#### Suppressing AMBA Alerts

To opt a resource out of a specific AMBA alert:

```text
Tag: MonitorDisable = "true"    (disables all AMBA alerts for that resource)
Tag: MonitorDisableXXX = "true" (disables specific alert rule XXX)
```

Document any suppression as a security exception.
### Monitoring & Alerting

| Layer | What to monitor | Alert threshold |
|-------|----------------|-----------------|
| Platform | Resource health events | Any degraded/unavailable state |
| Application | HTTP 5xx rate, latency p95, availability | SLO-based thresholds |
| Infrastructure | CPU, memory, disk, network | >80% sustained for 5min |
| Cost | Daily spend anomaly | >20% above 7-day average |
| Security | Defender for Cloud alerts | Any high/critical severity |

### Resource Locks

| Lock type | When | Applied to |
|-----------|------|-----------|
| CanNotDelete | Production stateful resources | Storage, databases, Key Vault, VNets |
| ReadOnly | Critical shared infrastructure | Hub VNets, DNS zones, policy assignments |
| None | Dev/test ephemeral resources | Anything recreatable via IaC |

### Backup Strategy

| Resource type | Minimum retention | Method |
|---------------|-------------------|--------|
| SQL Database | 7d (dev), 35d (prod) | Automated backup (built-in) |
| Cosmos DB | Continuous backup preferred | Continuous or periodic (24h/7d) |
| Storage Account | Soft delete 7d + versioning | Blob soft delete + container soft delete |
| VMs | Daily, 30d retention | Azure Backup vault |
| AKS / App Service | Config in IaC (stateless) | Re-deploy from source (no backup needed) |

### Tagging for Operations

In addition to CAF tags (see `naming-tagging.md`), operations benefits from:

| Tag | Purpose |
|-----|---------|
| `backup-policy` | Which backup schedule applies |
| `monitoring-tier` | Standard / Enhanced / Critical |
| `maintenance-window` | When patching/restarts are allowed |

## Validation Checks

The validation script checks for:

- Resources without diagnostic settings configuration
- Missing resource lock definitions for production resources
- Load balancers without health probe configuration
- Missing alert rule definitions

## References

- [Azure Monitor Baseline Alerts (AMBA)](https://aka.ms/amba)
- [AMBA GitHub repo](https://github.com/Azure/azure-monitor-baseline-alerts)
- [Azure Monitor overview](https://learn.microsoft.com/azure/azure-monitor/overview)
- [Resource locks](https://learn.microsoft.com/azure/azure-resource-manager/management/lock-resources)
- [Backup best practices](https://learn.microsoft.com/azure/backup/guidance-best-practices)
- See `../references/BICEP-PATTERNS.md` and `../references/TERRAFORM-PATTERNS.md` for code examples
