# Network Security Standards

All rules apply by default. Exceptions require documentation per the
[exception process](../SKILL.md#exceptions).

## Rules

| ID | Rule | Default | Exception criteria |
|----|------|---------|-------------------|
| SEC-NET-001 | Private endpoints for all PaaS resources in production | MUST | Internal-only dev/test with no sensitive data |
| SEC-NET-002 | Public network access disabled in production | MUST | Public-facing frontends (App Gateway, Front Door, CDN) |
| SEC-NET-003 | TLS 1.2 minimum on all endpoints | MUST | Legacy system integration with documented migration plan |
| SEC-NET-004 | No wildcard (`*`) in NSG source/destination | MUST | Never — always use explicit CIDRs or service tags |
| SEC-NET-005 | Default-deny NSG on all subnets | MUST | AKS system subnets managed by the cluster |
| SEC-NET-006 | DNS private zones configured for private endpoints | MUST | When using Azure Private DNS Resolver with custom DNS |
| SEC-NET-007 | WAF enabled on public-facing HTTP endpoints | MUST | Non-HTTP protocols; internal-only APIs |
| SEC-NET-008 | DDoS protection on VNets with public IPs | SHOULD | Cost-constrained dev/test environments |
| SEC-NET-009 | No public IPs directly attached to VMs/NICs | MUST | Bastion/jumpbox with NSG lockdown + JIT access |
| SEC-NET-010 | Network segmentation: workload isolation via subnets + NSGs | MUST | Single-resource VNets |
| SEC-NET-011 | Egress traffic filtered (Azure Firewall, NVA, or NSG) | SHOULD | Dev environments with documented risk |

## Design Guidance

### Private Endpoints

- Every PaaS resource with private endpoint support MUST use it in production
- Create a dedicated `snet-pe-*` subnet for private endpoints
- Associate a DNS private zone per resource type (e.g., `privatelink.blob.core.windows.net`)
- Use centralized Private DNS Zone groups when using hub-spoke topology

### Network Security Groups

- Every subnet MUST have an NSG attached (even if using Azure Firewall)
- Start with deny-all inbound/outbound, then add allow rules
- Use service tags (`AzureCloud`, `Storage`, `Sql`) over IP ranges
- Log NSG flow logs to Storage Account + Traffic Analytics

### Topology Patterns

| Pattern | When to use |
|---------|-------------|
| Hub-spoke VNet | Multi-workload, shared services (DNS, firewall, bastion) |
| VNet peering | Cross-subscription/region connectivity |
| Private Link service | Expose internal services to consumers without VNet peering |
| Azure Front Door + Private Origin | Global HTTP ingress with WAF and private backend |

### Subnet Sizing

- Plan subnets for growth — minimum `/27` for workload subnets
- Dedicated subnets for: AzureBastionSubnet, AzureFirewallSubnet, GatewaySubnet
- Private endpoint subnets: allow at minimum 1 IP per PE + growth room

## Validation Checks

The validation script (`scripts/validate_infra.py`) checks for:

- NSG wildcard rules in source/destination
- Resources without private endpoint configuration
- Public network access properties set to `Enabled`
- Missing TLS version properties

## References

- [Azure Private Link documentation](https://learn.microsoft.com/azure/private-link/)
- [NSG best practices](https://learn.microsoft.com/azure/virtual-network/network-security-group-how-it-works)
- [Hub-spoke topology](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- See `../references/BICEP-PATTERNS.md` and `../references/TERRAFORM-PATTERNS.md` for code examples
