# Data Protection Standards

All rules apply by default. Exceptions require documentation per the
[exception process](../SKILL.md#exceptions).

## Rules

| ID | Rule | Default | Exception criteria |
|----|------|---------|-------------------|
| SEC-DATA-001 | Encryption at rest enabled (service-managed key minimum) | MUST | Never — always encrypted |
| SEC-DATA-002 | CMK (customer-managed key) for production sensitive data | SHOULD | Low-sensitivity workloads with documented classification |
| SEC-DATA-003 | Soft delete enabled (Key Vault, Storage, SQL) | MUST | Ephemeral/disposable resources in dev only |
| SEC-DATA-004 | Purge protection on Key Vault in production | MUST | Dev/test Key Vaults only |
| SEC-DATA-005 | TLS in transit for all data flows | MUST | Never — always encrypted in transit |
| SEC-DATA-006 | No secrets in source code, parameters, or state files | MUST | Never |
| SEC-DATA-007 | Storage accounts: secure transfer required (`https` only) | MUST | Never |
| SEC-DATA-008 | Storage accounts: blob public access disabled | MUST | Public static content served via CDN/Front Door |
| SEC-DATA-009 | SQL/Cosmos: Transparent Data Encryption (TDE) enabled | MUST | Never — always enabled |
| SEC-DATA-010 | Immutable backup for compliance workloads | SHOULD | Non-regulated workloads with documented classification |

## Design Guidance

### Encryption Strategy

| Tier | What | When |
|------|------|------|
| Service-managed keys (SMK) | Default encryption at rest | All workloads (baseline) |
| Customer-managed keys (CMK) | You control the key in your Key Vault | Sensitive/regulated production data |
| Double encryption | Infrastructure + service layer encryption | HIPAA, PCI-DSS, government workloads |

### Key Vault Architecture

- One Key Vault per environment per workload (avoid cross-workload sharing)
- Enable soft delete (14-day minimum retention) and purge protection in production
- Access via RBAC (`Key Vault Secrets User`, `Key Vault Crypto User`) — not access policies
- Separate Key Vaults for: application secrets, encryption keys, certificates
- Network-restrict Key Vault to private endpoint access only

### Storage Account Hardening

```text
Required settings for all Storage Accounts:
- minimum_tls_version        = "TLS1_2"
- allow_nested_items_to_be_public = false  (Terraform) / allowBlobPublicAccess: false (Bicep)
- https_traffic_only_enabled = true
- default_to_oauth_authentication = true
- shared_access_key_enabled  = false  (when possible; requires RBAC data-plane access)
- network_rules.default_action = "Deny"  (with private endpoint)
```

### Data Classification

Before designing data storage, classify data:

| Level | Examples | Minimum protection |
|-------|----------|-------------------|
| Public | Marketing content, open APIs | SMK, TLS |
| Internal | Internal docs, non-PII logs | SMK, TLS, private endpoint |
| Confidential | PII, financial data | CMK, TLS, PE, audit logs, backup |
| Restricted | Credentials, health records | CMK + double encryption, PE, vault, immutable audit |

## Validation Checks

The validation script checks for:

- Missing `minTlsVersion` / `minimum_tls_version` properties
- Public blob access enabled
- Shared access key enabled without justification
- Secrets/passwords as plaintext in IaC files or parameter files
- Missing soft delete / purge protection on Key Vault resources

## References

- [Azure encryption at rest](https://learn.microsoft.com/azure/security/fundamentals/encryption-atrest)
- [Customer-managed keys](https://learn.microsoft.com/azure/security/fundamentals/encryption-models)
- [Storage security guide](https://learn.microsoft.com/azure/storage/common/storage-security-guide)
- See `../references/BICEP-PATTERNS.md` and `../references/TERRAFORM-PATTERNS.md` for code examples
