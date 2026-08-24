---
name: ais-infra-azure
description: >-
  Enforce Azure infrastructure best practices for all IaC work. Mandates Azure
  Verified Modules (AVM) as the default building block, Cloud Adoption Framework
  (CAF) naming and tagging, and Well-Architected Framework alignment. Supports
  both Bicep and Terraform as first-class IaC languages — the project decides
  which to use; this skill enforces AVM and Azure standards regardless of
  language choice. Load this skill whenever a spec touches infrastructure,
  deployment, or cloud resource provisioning.
license: Proprietary
compatibility: Bicep path requires Azure CLI 2.60+, Bicep CLI 0.28+; Terraform path requires Terraform 1.6+, AzureRM provider 3.x+
metadata:
  author: ais-internal
  version: "2.0"
---

# Azure Infrastructure Best Practices

This skill enforces Azure infrastructure standards whenever a spec involves
cloud resource provisioning, deployment pipelines, or IaC. It is the
authoritative reference for infrastructure decisions in any project that
targets Azure.

**Language-agnostic**: Both Bicep and Terraform are first-class. The project
constitution decides which language is used; this skill enforces AVM-first
module selection, CAF compliance, and security baselines regardless of choice.

## When to Use

- Spec is tagged `infra-only` or includes infrastructure user stories
- Design includes Azure resource provisioning
- Tasks involve Bicep files, Terraform files, ARM templates, or deployment pipelines
- Any work under `infra/` directory
- Spec mentions networking, compute, storage, databases, or platform services on Azure

## Skill Structure

This skill is modular. Load the sections relevant to your work:

```text
Skills/ais-infra-azure/
├── SKILL.md              ← You are here (index + loading instructions)
├── CONTRIBUTING.md       # How to contribute to this skill
├── standards/            # Domain-specific rules
│   ├── iac.md            # AVM-first, language choice, modules, file structure
│   ├── naming-tagging.md # CAF naming, abbreviations, required tags
│   ├── networking.md     # Private endpoints, NSG, TLS, WAF, DDoS
│   ├── identity-access.md# Managed identity, RBAC, secrets, federation
│   ├── data-protection.md# Encryption, soft delete, classification
│   ├── operations.md     # Diagnostics, locks, backup, alerts, scaling
│   ├── reliability.md    # Zone redundancy, multi-region, RTO/RPO
│   ├── governance.md     # Defender for Cloud, Azure Policy, compliance
│   └── deployment.md     # CI/CD, state, rollback, environments
├── workflow/             # Spec lifecycle integration
│   └── README.md         # Design → Tasks → Implement hooks
├── ci/                   # Pipeline templates
│   └── README.md         # GitHub Actions snippets (Bicep + Terraform)
├── references/           # Lookup guides and code patterns
│   ├── AVM-MODULES.md    # Bicep module derivation & dynamic lookup
│   ├── AVM-TERRAFORM.md  # Terraform module derivation & dynamic lookup
│   ├── BICEP-PATTERNS.md # Bicep code conventions & examples
│   └── TERRAFORM-PATTERNS.md # Terraform code conventions & examples
└── scripts/              # Validation tooling
    └── validate_infra.py # Static analysis for IaC files
```

## Standards Overview

| Domain | File | Key rules |
|--------|------|-----------|
| **IaC & Modules** | [`standards/iac.md`](standards/iac.md) | AVM-first, version pinning, language choice, file structure |
| **Naming & Tagging** | [`standards/naming-tagging.md`](standards/naming-tagging.md) | CAF conventions, required tags, naming modules |
| **Network Security** | [`standards/networking.md`](standards/networking.md) | Private endpoints, NSG, TLS 1.2+, WAF, DDoS |
| **Identity & Access** | [`standards/identity-access.md`](standards/identity-access.md) | Managed identity, RBAC, no stored secrets, federation |
| **Data Protection** | [`standards/data-protection.md`](standards/data-protection.md) | Encryption at rest/transit, soft delete, CMK, classification |
| **Operations** | [`standards/operations.md`](standards/operations.md) | Diagnostics, locks, backup, alerts, auto-scale |
| **Reliability** | [`standards/reliability.md`](standards/reliability.md) | Zone redundancy, multi-region, RTO/RPO, health probes |
| **Governance** | [`standards/governance.md`](standards/governance.md) | Defender for Cloud, Azure Policy, compliance mapping |
| **Deployment** | [`standards/deployment.md`](standards/deployment.md) | CI/CD pipelines, state management, rollback, evidence |

## Loading Instructions

### Minimum (any infrastructure work)

Always load:
1. `standards/iac.md` — Module selection, language rules
2. `standards/naming-tagging.md` — Naming and tagging compliance
3. `standards/deployment.md` — How to deploy and validate
4. `workflow/README.md` — Lifecycle integration

### Full stack (production infrastructure)

Load all of the above plus:
5. `standards/networking.md` — Network security
6. `standards/identity-access.md` — Identity and access
7. `standards/data-protection.md` — Data protection
8. `standards/operations.md` — Operational excellence
9. `standards/reliability.md` — Reliability and DR
10. `standards/governance.md` — Defender for Cloud and policy

### Selective (based on spec scope)

| Spec involves... | Additional standards to load |
|-----------------|------------------------------|
| Networking / connectivity | `networking.md` |
| Auth / service-to-service | `identity-access.md` |
| Databases / storage / secrets | `data-protection.md` |
| Production readiness | `operations.md` + `reliability.md` + `governance.md` |
| CI/CD pipeline setup | `ci/README.md` |

## Exceptions

All rules default ON. When a project requirement conflicts with a rule,
document an exception:

```markdown
#### Security Exception: [Rule ID]
- **Resource**: [resource name/type]
- **Rule**: [rule being waived]
- **Justification**: [why this is acceptable]
- **Compensating control**: [what mitigates the risk]
- **Accepted by**: [owner name/role]
- **Review date**: [when to re-evaluate]
```

Place exceptions in the spec's `design.md` or as a standalone ADR.
Rules marked `Never` in exception criteria cannot be waived.

## Validation (optional local helper)

The validation script is a convenience tool for quick local checks — not a
required CI gate. `az bicep lint`, `tflint`, and Azure Policy are the real
enforcement chain.

```bash
# Auto-detect language
python3 Skills/ais-infra-azure/scripts/validate_infra.py --path infra/

# Explicit language
python3 Skills/ais-infra-azure/scripts/validate_infra.py --path infra/ --lang bicep
python3 Skills/ais-infra-azure/scripts/validate_infra.py --path infra/ --lang terraform
```

See `ci/README.md` for the required CI pipeline setup.

## References

- `references/AVM-MODULES.md` — How to find and use Bicep AVM modules
- `references/AVM-TERRAFORM.md` — How to find and use Terraform AVM modules
- `references/BICEP-PATTERNS.md` — Bicep code patterns and conventions
- `references/TERRAFORM-PATTERNS.md` — Terraform code patterns and conventions
- `CONTRIBUTING.md` — How to add rules, patterns, or validation checks
