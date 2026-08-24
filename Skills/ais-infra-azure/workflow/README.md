# Workflow Integration

How this skill integrates with the AIS spec lifecycle commands.

## During `/ais.spec.design`

When the spec involves infrastructure:

1. **IaC Language Decision** — Confirm Bicep vs Terraform is decided (check constitution/architecture)
2. **Constitution Check** — Confirm these standards are reflected in project constitution
3. **Module Selection** — For every Azure resource in the design, identify the AVM module to use.
   Look up the module name dynamically — do not assume; verify it exists in the registry first.
   See `../references/AVM-MODULES.md` (Bicep) or `../references/AVM-TERRAFORM.md` (Terraform).
   Name the specific module in design.md. Do not leave module selection to implementation time.
4. **Security Baseline** — Apply all standards from `standards/` to the design:
   - Network topology and PE requirements → `standards/networking.md`
   - Identity strategy → `standards/identity-access.md`
   - Data protection classification → `standards/data-protection.md`
   - Reliability tier selection → `standards/reliability.md`
5. **Verification Strategy** — Include:
   - Lint pass (Bicep: `az bicep lint` / Terraform: `terraform validate` + `tflint`)
   - Plan/what-if clean output
   - Azure Policy compliance check
   - Naming/tagging validation
6. **Data Model** — Map to Azure resource types and their AVM module identifiers
7. **Architecture Decisions** — Record any AVM exceptions or security exceptions as ADRs

### Infrastructure Section in design.md

Add a dedicated `## Infrastructure` section with this structure:

```markdown
## Infrastructure

### IaC Language
[Bicep / Terraform] — confirmed in constitution / architecture decision record.

### Resources

| Resource | Type | AVM Module | Version | Notes |
|----------|------|-----------|---------|-------|
| Storage account | `Microsoft.Storage/storageAccounts` | `br/public:avm/res/storage/storage-account` | X.Y.Z | Private endpoint required |
| Key Vault | `Microsoft.KeyVault/vaults` | `br/public:avm/res/key-vault/vault` | X.Y.Z | Purge protection ON |

### Security Exceptions

<!-- List any exceptions to the default security baseline, per SKILL.md#exceptions format -->
None.

### Governance

- Defender for Cloud: [Standard / Free — justified if Free]
- Policy initiative: [Azure Security Benchmark / CIS / other]
- Compliance initiative assigned before production: [Yes / No — with date if No]
```

## During `/ais.spec.tasks`

Infrastructure tasks follow the standard `tasks.md` checklist format:
`- [ ] [ID] [P?] Description`

Required task categories and their label prefixes:

- `[Setup]` Install/verify IaC tooling, confirm AVM registry access
- `[IaC]` Core infrastructure implementation — one task per AVM module
- `[Security]` Private endpoints, NSGs, identity assignments, Key Vault config
- `[Monitoring]` Diagnostic settings, AMBA policy assignment, alert action groups
- `[Governance]` Defender for Cloud plans, Azure Policy assignment, compliance check
- `[Lint]` IaC lint pass (`az bicep lint` / `terraform validate + tflint`)
- `[Plan]` Deployment plan/what-if validation — review output for unexpected deletions
- `[Policy]` Azure Policy compliance check — zero critical violations
- `[Evidence]` Capture resource IDs, deployment output, policy compliance report

## During `/ais.spec.implement`

Infrastructure implementation MUST:

1. **Bicep**: Start with `bicep restore`; **Terraform**: Start with `terraform init`
2. Lint before every commit (`az bicep lint` / `terraform validate` + `tflint`)
3. Apply security baseline from `standards/` — check each applicable SEC-*/OPS-*/REL-*/GOV-* rule
4. Run plan/what-if before applying — review for unexpected deletions or replacements
5. Capture deployment output as evidence
6. Validate naming/tagging post-deployment
7. Document any security exceptions in design.md
8. Update implementation-plan.md with resource IDs and deployment status

## Quick Reference: Which Standard Files to Load

| Spec involves... | Load these standards |
|-----------------|---------------------|
| Any Azure infrastructure | `iac.md` + `naming-tagging.md` + `deployment.md` |
| Networking / connectivity | + `networking.md` |
| Authentication / authorization | + `identity-access.md` |
| Databases / storage / secrets | + `data-protection.md` |
| Production deployment | + `operations.md` + `reliability.md` |
| All of the above (full stack) | Load all standards |

## Constitution Clauses (Template)

When running `/ais.setup.constitution`, include these in the project constitution.
Replace `[Bicep / Terraform]` with the project's chosen language:

```markdown
### Infrastructure as Code: Azure Verified Modules First

All Azure infrastructure MUST use Azure Verified Modules (AVM) as the primary
building block. Custom modules require an ADR documenting why AVM is
insufficient and an upgrade plan for when AVM coverage expands. All IaC MUST
pass automated linting, plan/what-if validation, and Azure Policy compliance
before merge.

| ID | Standard | Decision | Status | Source |
|----|----------|----------|--------|--------|
| TS-IaC-001 | IaC Language | [Bicep / Terraform] | Decided | Architecture |
| TS-IaC-002 | Module Source | AVM Registry | Decided | Architecture |
| TS-IaC-003 | Naming Convention | Azure CAF | Decided | CAF |
| TS-IaC-004 | Secret Management | Key Vault references only | Decided | Security |
| TS-IaC-005 | Deployment Method | [Deployment Stacks / Terraform Apply] | Decided | Architecture |
| TS-IaC-006 | State Management | [N/A / Azure Storage backend] | Decided | Architecture |

| ID | Gate | Threshold | Enforcement |
|----|------|-----------|-------------|
| QG-IaC-001 | IaC Lint | Zero errors, zero warnings | CI pipeline |
| QG-IaC-002 | AVM Usage | All resources use AVM unless ADR exists | Design review + CI |
| QG-IaC-003 | Plan/What-if Clean | No unexpected destructive changes | PR gate |
| QG-IaC-004 | Policy Compliance | Zero violations | PR gate |
| QG-IaC-005 | Naming/Tagging | CAF-compliant names, required tags present | CI lint |
| QG-IaC-006 | Security Baseline | All SEC-* rules pass or have documented exceptions | Design review |
```
