# Reliability Standards

All rules apply by default. Exceptions require documentation per the
[exception process](../SKILL.md#exceptions).

## Rules

| ID | Rule | Default | Exception criteria |
|----|------|---------|-------------------|
| REL-001 | Zone-redundant SKUs for production | MUST | Single-region dev/test; regions with <3 zones |
| REL-002 | Multi-region only when requirements explicitly demand it | SHOULD | Default is single-region; only implement when RTO/RPO or compliance requires it |
| REL-003 | Backup retention: 7d minimum, 30d for production | MUST | Ephemeral data with documented recovery plan |
| REL-004 | Recovery time/point objectives stated in design | MUST | Non-critical internal tools |
| REL-005 | Health probes with appropriate thresholds (not default) | MUST | Single-instance non-HA resources |
| REL-006 | Graceful degradation patterns documented | SHOULD | Stateless/idempotent services with retry |
| REL-007 | Circuit breaker or retry policies for external dependencies | SHOULD | Fire-and-forget scenarios |
| REL-008 | Chaos testing plan for production-critical workloads | SHOULD | Low-criticality internal services |

## Design Guidance

### Availability Tiers

Define the target tier in design.md and select resources accordingly.
**Default is Standard** — only escalate when requirements explicitly demand it:

| Tier | SLA Target | Zone Redundancy | Multi-Region | DR Strategy | When |
|------|-----------|-----------------|--------------|-------------|------|
| Standard | 99.9% | Yes (production) | No | Redeploy from IaC | Default for all workloads |
| High | 99.95% | Yes | Warm standby | Failover with manual intervention | Requirements state RTO < 1h |
| Critical | 99.99% | Yes | Active-active | Automated failover | Requirements state RTO < 5min or regulatory mandate |

### Zone Redundancy Checklist

For production resources, use zone-redundant SKUs:

| Resource | Zone-Redundant SKU / Config |
|----------|----------------------------|
| App Service | Premium v3 with zone redundancy enabled |
| Azure SQL | Zone-redundant HA (Business Critical or Hyperscale) |
| Storage | ZRS or GZRS replication |
| Key Vault | Zone-redundant by default (Premium) |
| AKS | Multi-zone node pools (`zones = [1, 2, 3]`) |
| Application Gateway | v2 with zone parameter |
| Azure Cache for Redis | Premium/Enterprise with zone redundancy |
| Service Bus / Event Hubs | Premium with zone redundancy |

### RTO/RPO Documentation

The spec's design.md MUST include:

```markdown
### Recovery Objectives

| Component | RTO | RPO | Strategy |
|-----------|-----|-----|----------|
| [Database] | [4h] | [1h] | [Geo-restore from backup] |
| [App Service] | [15min] | [0 — stateless] | [Redeploy from IaC + swap slot] |
| [Storage] | [1h] | [24h] | [GZRS replication + soft delete] |
```

### Failure Mode Analysis

For critical workloads, document:

1. **Single points of failure** — What has no redundancy?
2. **Blast radius** — If component X fails, what else is affected?
3. **Recovery automation** — What's manual vs automated in DR?
4. **Data loss window** — What data can be lost between backups?

## Validation Checks

The validation script checks for:

- Non-zone-redundant SKUs in production-tagged resources
- Missing health probe configuration on load-balanced resources
- Storage accounts without ZRS/GZRS in production
- Missing RTO/RPO section in design documents

## References

- [Azure reliability documentation](https://learn.microsoft.com/azure/reliability/)
- [Well-Architected reliability pillar](https://learn.microsoft.com/azure/well-architected/reliability/)
- [Availability zone support by service](https://learn.microsoft.com/azure/reliability/availability-zones-service-support)
- See `../references/BICEP-PATTERNS.md` and `../references/TERRAFORM-PATTERNS.md` for code examples
