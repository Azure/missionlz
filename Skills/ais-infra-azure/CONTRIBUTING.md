# Contributing to ais-infra-azure

## Structure

```text
Skills/ais-infra-azure/
├── SKILL.md              # Index: frontmatter, overview, loading instructions
├── CONTRIBUTING.md       # This file
├── standards/            # Domain-specific rules (one file per domain)
│   ├── iac.md            # AVM-first, language choice, modules, file structure
│   ├── naming-tagging.md # CAF naming, abbreviations, required tags
│   ├── networking.md     # Private endpoints, NSG, TLS, WAF, DDoS
│   ├── identity-access.md# Managed identity, RBAC, secrets, federation
│   ├── data-protection.md# Encryption, soft delete, classification
│   ├── operations.md     # Diagnostics, locks, backup, alerts, scaling
│   ├── reliability.md    # Zone redundancy, multi-region, RTO/RPO
│   ├── governance.md     # Defender for Cloud, Azure Policy, compliance
│   └── deployment.md     # CI/CD, state, rollback, environments
├── workflow/             # Spec lifecycle hooks
│   └── README.md         # Design → Tasks → Implement integration
├── ci/                   # Pipeline templates
│   └── README.md         # GitHub Actions snippets
├── references/           # Lookup guides and code patterns
│   ├── AVM-MODULES.md    # Bicep module derivation & lookup
│   ├── AVM-TERRAFORM.md  # Terraform module derivation & lookup
│   ├── BICEP-PATTERNS.md # Bicep code conventions & examples
│   └── TERRAFORM-PATTERNS.md # Terraform code conventions & examples
└── scripts/              # Validation tooling
    └── validate_infra.py # Static analysis for IaC files
```

## How to Contribute

### 1. Branch

Create a branch from `main` with prefix `chore/infra-skill-*`.

### 2. Determine what to change

| Change type | Where |
|-------------|-------|
| New security/compliance rule | `standards/{domain}.md` |
| New code pattern or example | `references/{BICEP,TERRAFORM}-PATTERNS.md` |
| Module lookup changes | `references/AVM-MODULES.md` or `AVM-TERRAFORM.md` |
| Workflow hook updates | `workflow/README.md` + `.specify/prompts/` |
| CI pipeline changes | `ci/README.md` |
| Validation script updates | `scripts/validate_infra.py` |
| Skill overview/loading logic | `SKILL.md` (index only — keep it thin) |

### 3. Rule ID Conventions

New rules must follow the existing ID scheme:

| Prefix | Domain | File |
|--------|--------|------|
| `SEC-NET-NNN` | Network security | `standards/networking.md` |
| `SEC-IAM-NNN` | Identity & access | `standards/identity-access.md` |
| `SEC-DATA-NNN` | Data protection | `standards/data-protection.md` |
| `OPS-NNN` | Operational excellence | `standards/operations.md` |
| `REL-NNN` | Reliability | `standards/reliability.md` |
| `GOV-NNN` | Governance & compliance | `standards/governance.md` |
| `CAF-NAME-NNN` | Naming conventions | `standards/naming-tagging.md` |
| `CAF-TAG-NNN` | Tagging rules | `standards/naming-tagging.md` |
| `DEPLOY-NNN` | Deployment & CI/CD | `standards/deployment.md` |

Increment from the last used number. Never reuse retired IDs.

### 4. Rule Format

Every rule table row must include:

```markdown
| ID | Rule description | Default (MUST/SHOULD) | Exception criteria |
```

- **MUST** = Required by default, exceptions need documented justification
- **SHOULD** = Strongly recommended, deviation needs rationale but not full ADR
- Rules with `Never` as exception criteria are absolute — never add exceptions

### 5. Exception Criteria

Every MUST rule MUST have an exception path (even if narrow). The only
exception to this is rules where allowing any exception would create an
unacceptable security risk (marked `Never`).

### 6. No Hardcoded Module Lists

Reference docs MUST teach agents how to look up modules dynamically.
Never maintain static catalogs of module names or versions.

### 7. Test Changes

- If updating `validate_infra.py`, test with both Bicep and Terraform fixtures
- If adding patterns to `references/`, verify they compile/validate
- If updating workflow hooks, regenerate agent skills from prompts

### 8. Regenerate Agent Skills

If you update `workflow/README.md` or modify lifecycle hooks:

1. Update `.specify/prompts/ais.spec.{design,tasks,implement}.md`
2. Run the generate script to sync `.agents/skills/`

## What NOT to Change

- Don't add AWS/GCP alternatives — this skill is Azure-only
- Don't add application-level patterns (auth flows, API design)
- Don't hardcode tool/module versions
- Don't remove exception paths without framework-wide discussion
- Don't put detailed content in `SKILL.md` — it's an index; details go in `standards/`, `workflow/`, `ci/`, or `references/`

## PR Requirements

- Label: `release:minor` for new rules/guidance, `release:patch` for fixes/clarifications
- Release note explaining what changed and why
- If adding new SEC-* rules, confirm alignment with Azure Security Benchmark v4+
- If adding new OPS-* rules, confirm alignment with Azure Monitor best practices
- Footer: `Coded with [AIS-spec](https://github.com/ais-internal/ais-spec)`

## Adding a New Domain

If a new domain doesn't fit existing files:

1. Create `standards/{new-domain}.md` following the same structure:
   - Title, intro, rules table, design guidance, validation checks, references
2. Define a new ID prefix (e.g., `GOV-NNN` for governance)
3. Add the file to the SKILL.md standards table
4. Add the domain to the workflow README's "which standards to load" table
5. Update this CONTRIBUTING.md structure diagram and ID table
