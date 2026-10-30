# Implementation Plan: Validate Weekly MLZ Deployments in AllInOne with Automatic Cleanup

**Branch**: `1309-single-subscription-validation` | **Date**: 2026-10-22 | **Spec**: [spec.md](./spec.md)

**Canonical Feature Issue**: [#1309](https://github.com/Azure/missionlz/issues/1309) (authoritative source of truth for requirements, User Stories, tasks, acceptance criteria, and progress)

**Input**: Feature specification from `/specs/003-single-subscription-validation/spec.md`

## Summary

Implement a repeatable weekly and manually triggerable deployment validation lifecycle for the core Mission Landing Zone (`src/mlz.bicep`) targeting the dedicated AllInOne test subscription in `AzureUSGovernment` (`usgovarizona`). The lifecycle maps `hub`, `identity`, `operations`, and `sharedServices` to the verified AllInOne subscription ID with `deployIdentity = true` and `deployDefender = true`, captures a pre-deployment ownership baseline before provisioning, runs an optional post-deployment functional test hook for [#1310](https://github.com/Azure/missionlz/issues/1310), and guarantees cleanup of run-created resource groups and subscription-level security resources (`try`/`finally`) while resetting only run-modified Defender pricing plans back to `Free` and preserving all pre-existing resources and original failure statuses.

## Technical Context

**Language/Version**: PowerShell 7.4+ (`pwsh`), Bicep (via Azure CLI `az bicep`), GitHub Actions YAML

**Primary Dependencies**: Azure CLI (`az`), Pester `6.0.0`, `azure/login` (GitHub Actions OIDC authentication)

**Storage**: N/A (in-memory baseline snapshot and optional JSON validation run report artifact)

**Testing**: Pester `6.0.0` via `./tests/Invoke-Tests.ps1` and the concern-specific files under `./tests/deployment`

**Target Platform**: `AzureUSGovernment` cloud, region `usgovarizona` (`usgovvirginia` excluded due to quota restrictions), `ubuntu-latest` GitHub Actions runner and local `pwsh` CLI

**Project Type**: Infrastructure-as-Code (Bicep) deployment validation harness and CI/CD workflow

**Performance Goals**: Complete full single-subscription provisioning, optional post-deployment test hook, and deterministic cleanup within a single scheduled workflow run without leaking subscription resources

**Constraints**:
- `deployDefender` MUST remain `true`
- Subscription-scope `Microsoft.Security/pricings` does not support HTTP `DELETE`; run-modified Defender plans must be reset to `Free` (`az security pricing create -n <plan> --tier Free`)
- Must preserve pre-existing resource groups, policy assignments, security contacts, Defender `Standard` plans, and authentication/bootstrap resources
- Must never log or persist secrets, credentials, or customer network addressing
- Must preserve local/CI parity (`./tests/Invoke-Tests.ps1`) and the repository's coverage ratchet (`tests/coverage-baseline.json`)

**Scale/Scope**: Single-subscription AllInOne topology in `AzureUSGovernment` (`usgovarizona`) deploying `hub`, `identity`, `operations`, and `sharedServices` into the verified AllInOne subscription ID with parameterized tier subscription IDs so [#1316](https://github.com/Azure/missionlz/issues/1316) can reuse the lifecycle without rework

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Constitution Principle / Section | Pre-Design Gate | Post-Design Re-Check | Notes |
|----------------------------------|-----------------|----------------------|-------|
| **I. Simplicity** | PASS | PASS | Uses a single PowerShell entrypoint (`tests/deployment/Invoke-DeploymentValidation.ps1`) invoking the supported Azure CLI deployment and cleanup commands directly with no intermediate wrapper layers. |
| **II. YAGNI (You Aren't Gonna Need It)** | PASS | PASS | Implements only the AllInOne deployment/cleanup lifecycle, workflow, Pester tests, and docs required by `#1309`; does not build `#1310` comprehensive assertions or `#1316` multi-subscription workflows. |
| **III. Single Responsibility Principle** | PASS | PASS | Separates baseline capture, Bicep provisioning, post-deployment test hook invocation, cleanup, and reporting into distinct functions within the validation harness while keeping workflow orchestration in `.github/workflows/deployment-validation.yml`. |
| **IV. Validation-Driven Infrastructure (NON-NEGOTIABLE)** | PASS | PASS | Enforces strict Red-Green-Refactor TDD: writes automated Pester 6.0.0 lifecycle tests, one concern per file under `tests/deployment`, first and executes them to verify they fail for the expected reason before writing implementation code (`T001` Red), writes minimal implementation code in `Invoke-DeploymentValidation.ps1` and executes the suite to verify tests pass (`T002`–`T003` Green), and cleans up duplication, structure, and readability while keeping all tests and gates green (`T005` Refactor). Also performs real single-subscription Bicep deployment in `AzureUSGovernment` (`usgovarizona`), preserves the `src/artifacts/*.ps1` coverage ratchet, and passes Super-Linter and Bicep build gates. |
| **Deployment Standards** | PASS | PASS | Validates reproducible single-subscription deployment from `src/mlz.bicep` and deterministic teardown back to the pre-deployment baseline. |
| **Platform Constraints** | PASS | PASS | Uses `src/mlz.bicep` via the supported Azure CLI deployment path in `AzureUSGovernment` with parameterized cloud and region (`usgovarizona`) and zero hardcoded environment URLs. |
| **Security** | PASS | PASS | Keeps `deployDefender = true`, uses OIDC least-privilege workflow permissions (`id-token: write`, `contents: read`), and never stores or outputs secrets, credentials, or customer IP ranges. |
| **DevOps** | PASS | PASS | Keeps `src/mlz.bicep` / `src/mlz.json` untouched (or synced if ever modified), passes `super-linter` and `validate-build-bicep` with zero warnings, and tracks requirements, User Stories (`US1`, `US2`), and tasks (`T001`–`T010`) in canonical issue `#1309`. |
| **Development Workflow** | PASS | PASS | Developed on dedicated branch `1309-single-subscription-validation`. Public `docs/testing.md` states that the weekly AllInOne run exists and does not publish operator instructions. |

## Project Structure

### Documentation (this feature)

```text
specs/003-single-subscription-validation/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── lifecycle-cli.md # CLI and GitHub Actions workflow contract
└── checklists/
    └── requirements.md  # Specification quality checklist (/speckit-specify output)
```

### Source Code (repository root)

```text
src/
├── mlz.bicep                                  # Existing subscription-scope MLZ core entrypoint
└── modules/
    ├── resource-groups.bicep                  # Existing tier resource group provisioning
    ├── security.bicep                         # Existing policy & Defender module orchestration
    └── defender-for-cloud.bicep               # Existing subscription Defender pricings, contact, benchmark policy

tests/
├── Invoke-Tests.ps1                           # Existing Pester 6.0.0 runner & coverage ratchet entrypoint
└── deployment/
    ├── Invoke-DeploymentValidation.ps1                 # AllInOne deployment, test hook, and cleanup lifecycle script
    ├── Initialize-DeploymentValidationTest.ps1        # Isolated Azure CLI double and fresh run state; not a test
    ├── Invoke-DeploymentValidation.Configuration.Tests.ps1
    ├── Invoke-DeploymentValidation.Baseline.Tests.ps1
    ├── Invoke-DeploymentValidation.Deployment.Tests.ps1
    ├── Invoke-DeploymentValidation.Cleanup.Tests.ps1
    ├── Invoke-DeploymentValidation.TestHook.Tests.ps1
    ├── Invoke-DeploymentValidation.Outcome.Tests.ps1
    └── Invoke-DeploymentValidation.Workflow.Tests.ps1 # Workflow configuration and isolated step execution

.github/
└── workflows/
    └── deployment-validation.yml              # Weekly scheduled + manual dispatch validation workflow

docs/
├── testing.md                                 # States that weekly AllInOne validation exists
└── deployment-guides/
    └── command-line-tools.md                  # Existing supported CLI deployment & removal reference
```

**Structure Decision**: Place the deployment validation lifecycle script and its Pester tests under `tests/deployment/` so `tests/Invoke-Tests.ps1` automatically discovers each `*.Tests.ps1` file without altering the `src/artifacts/*.ps1` coverage scope, and invoke `tests/deployment/Invoke-DeploymentValidation.ps1` directly from `.github/workflows/deployment-validation.yml`. Each test file owns one behavior and can run in its own runspace.

## Complexity Tracking

No constitution violations. Note on `DevOps > GitHub Issue Discipline`: per repository owner direction for `#1309`, User Stories (`US1`, `US2`) and task checklists (`T001`–`T010`) are maintained directly inside the canonical `#1309` Feature issue body rather than split into separate User Story sub-issues.
