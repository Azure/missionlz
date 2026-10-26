---
description: "Actionable, dependency-ordered tasks for Validate Weekly MLZ Deployments in AllInOne with Automatic Cleanup (#1309)"
---

# Tasks: Validate Weekly MLZ Deployments in AllInOne with Automatic Cleanup

**Input**: Design documents from `/specs/003-single-subscription-validation/` and canonical issue [#1309](https://github.com/Azure/missionlz/issues/1309)

**Prerequisites**: [plan.md](./plan.md) (required), [spec.md](./spec.md) (required for user stories), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/lifecycle-cli.md](./contracts/lifecycle-cli.md), [quickstart.md](./quickstart.md)

**Tests**: Included per canonical issue [#1309](https://github.com/Azure/missionlz/issues/1309) and [constitution.md](../../.specify/memory/constitution.md) `v1.1.0` Principle IV (Validation-Driven Infrastructure — strict **Red-Green-Refactor** TDD).

**Organization**: Tasks preserve the canonical `T001`–`T010` identifiers and User Story grouping (`US1`, `US2`) from [#1309](https://github.com/Azure/missionlz/issues/1309).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`)
- Exact file paths and verbatim `data-model.md` constraints are included in task descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Existing repository infrastructure used by this feature (`src/mlz.bicep`, `tests/Invoke-Tests.ps1`, `tests/coverage-baseline.json`, and `.github/workflows/`). No separate setup tasks are required prior to User Story work; task numbering starts at `T001` in Phase 3 to maintain 1-to-1 identity with [#1309](https://github.com/Azure/missionlz/issues/1309).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core contract and Pester test harness foundations are established directly in `T001` (`tests/deployment/Invoke-DeploymentValidation.ps1` and `tests/deployment/*.Tests.ps1`), including executing the Pester suite to verify the new tests fail for the expected reason (**Red**) before deployment, cleanup, and workflow implementation proceed.

**Checkpoint**: Once `T001` (**Red**) is complete, `T002` and `T003` (**Green**) can proceed, and `T007` (User Story 2 environment verification) can run in parallel with lifecycle development.

---

## Phase 3: User Story 1 - Shared Deployment and Cleanup Lifecycle (Priority: P1) 🎯 MVP

**Goal**: Provide a repeatable weekly and manually triggerable MLZ deployment validation lifecycle with pre-deployment ownership baseline capture, optional [#1310](https://github.com/Azure/missionlz/issues/1310) post-deployment test hook execution, guaranteed post-run cleanup (`try`/`finally`), Defender `Free` resets, and distinct deployment/test/cleanup failure reporting.

**Independent Test**: Run `pwsh -NoProfile -File ./tests/Invoke-Tests.ps1` and `pwsh -NoProfile -Command "Invoke-Pester -Path ./tests/deployment -Output Detailed"` to verify successful deployment + cleanup, partial deployment failure + cleanup, cleanup failure, original-failure preservation, pre-existing resource protection, and [#1310](https://github.com/Azure/missionlz/issues/1310) test hook handling without weakening existing CI gates or coverage thresholds.

### Tests & Contract for User Story 1 ⚠️

> **NOTE: Follow strict Red-Green-Refactor TDD per Constitution `v1.1.0` Principle IV: write tests FIRST and execute them to verify they FAIL for the expected reason in `T001` (Red), write minimal implementation code and execute the suite to verify they PASS in `T002`–`T003` (Green), and clean up duplication, structure, and readability while keeping all tests green in `T005` (Refactor).**

- [x] T001 [US1] Define the configuration (`ValidationRunConfig`: `CloudEnvironment` `Default: 'AzureUSGovernment'`, `Location` `Default: 'usgovarizona'; must not be 'usgovvirginia' for AllInOne`, `SubscriptionId` `Required GUID`, `HubSubscriptionId`/`IdentitySubscriptionId`/`OperationsSubscriptionId`/`SharedServicesSubscriptionId` `Default: SubscriptionId`, `Identifier` `1–5 lowercase alphanumeric chars (^[a-z0-9]{1,5}$); default: wk + 3 random chars`, `EnvironmentAbbreviation` `Allowed: 'dev', 'prod', 'test'; default: 'dev'`, `TemplatePath` `Default: 'src/mlz.bicep'`, `DeployIdentity` `Default: $true`, `DeployDefender` `Fixed: $true (validation rejects $false)`, `TestScriptPath` `Optional ('' when not configured)`), ownership (`SubscriptionBaselineSnapshot`: `SubscriptionId`, `CapturedAtUtc`, `ResourceGroupNames`, `PolicyAssignmentNames`, `SecurityContactNames`, `DefenderPricingTiers`), and outcome contract (`CleanupSummary` and `ValidationRunReport`: `DeploymentStatus` `'Succeeded' | 'Failed' | 'NotStarted'`, `DeploymentError` `Error details when DeploymentStatus -eq 'Failed', otherwise $null`, `TestStatus` `'Passed' | 'Failed' | 'Skipped'`, `TestError` `Error details when TestStatus -eq 'Failed', otherwise $null`, `CleanupStatus` `'Succeeded' | 'Failed' | 'NotRun'`, `OverallStatus` `'Succeeded' only when DeploymentStatus -eq 'Succeeded', CleanupStatus -eq 'Succeeded', and TestStatus -in @('Passed', 'Skipped'); otherwise 'Failed'`) for `tests/deployment/Invoke-DeploymentValidation.ps1`; write focused lifecycle tests under `tests/deployment`, one concern per `*.Tests.ps1` file, each independently runnable in any order and safe to run in parallel, before implementation and execute Pester (`Invoke-Pester -Path ./tests/deployment`) to verify they fail for the expected reason (**Red**).

### Implementation for User Story 1

- [x] T002 [US1] Implement the minimum real core Bicep deployment (`src/mlz.bicep` via `az deployment sub create`) and post-provisioning [#1310](https://github.com/Azure/missionlz/issues/1310) test hook integration (`TestStatus = 'Skipped'` when unconfigured, `'Failed'` when missing or failing) through the supported Azure CLI path in `tests/deployment/Invoke-DeploymentValidation.ps1`, using secure inputs and explicit target configuration, and execute `Invoke-Pester -Path ./tests/deployment` to verify the deployment and test-hook tests pass (**Green**).
- [x] T003 [US1] Implement the minimum pre-deployment ownership baseline capture and `try`/`finally` run-owned resource-group (`rg-<Identifier>-*` / `tags.identifier == <Identifier>` absent from baseline) and subscription-security cleanup (`Microsoft.Authorization/policyAssignments`, `Microsoft.Security/securityContacts`) in `tests/deployment/Invoke-DeploymentValidation.ps1`, including preservation of pre-existing resources and Defender `Free` resets (`az security pricing create -n <plan> --tier Free`), and execute `Invoke-Pester -Path ./tests/deployment` to verify all lifecycle tests pass (**Green**).
- [x] T004 [US1] Wire secure OIDC authentication (`id-token: write`, `contents: read`), weekly scheduling (`schedule`), independent manual execution (`workflow_dispatch`), cleanup, and sanitized failure reporting into `.github/workflows/deployment-validation.yml`.
- [ ] T005 [US1] Refactor `tests/deployment/Invoke-DeploymentValidation.ps1` and `tests/deployment/*.Tests.ps1` to clean up duplication, structure, and readability while keeping all tests green (**Refactor**), and validate successful deployment, partial deployment failure, cleanup failure, original-failure preservation, and protection of pre-existing resources through `tests/deployment/*.Tests.ps1` and existing gates (`tests/Invoke-Tests.ps1`, `tests/coverage-baseline.json`, Bicep build, and Super-Linter) without weakening tests or coverage requirements.
- [x] T006 [P] [US1] Document reproducible commands, required configuration and permissions, weekly schedule, cleanup boundaries, failure investigation, and the shared [#1310](https://github.com/Azure/missionlz/issues/1310) integration point in `docs/testing.md`.

**Checkpoint**: User Story 1 lifecycle, workflow, Pester suite, and documentation are complete and verified against all local and CI gates.

---

## Phase 4: User Story 2 - AllInOne Configuration and Live Validation (Priority: P2)

**Goal**: Verify the live AllInOne subscription configuration (`AzureUSGovernment`, `usgovarizona`, authentication, permissions, and quota) and produce live execution evidence for both a successful deployment followed by cleanup and a partial/failed deployment followed by cleanup.

**Independent Test**: With explicit authorization for live execution, run `tests/deployment/Invoke-DeploymentValidation.ps1` against the dedicated AllInOne test subscription in `AzureUSGovernment` (`usgovarizona`) for both a full deployment + cleanup and a controlled partial-failure deployment + cleanup, confirming all run-owned resources and subscription security settings are cleaned up while pre-existing resources remain intact.

### Implementation & Live Verification for User Story 2

- [ ] T007 [P] [US2] Resolve and verify AllInOne configuration (subscription ID, `AzureUSGovernment` cloud, `usgovarizona` region, permissions, and quota) and configure secure authentication for `.github/workflows/deployment-validation.yml`, using the prerequisites documented in `docs/testing.md`.
- [ ] T008 [US2] Run a successful real deployment followed by cleanup through `tests/deployment/Invoke-DeploymentValidation.ps1`; verify resource and subscription-security outcomes in the dedicated AllInOne test subscription.
- [ ] T009 [US2] Exercise a failed deployment with partial resources through `tests/deployment/Invoke-DeploymentValidation.ps1`; verify cleanup still runs, protected resources remain intact, and the final result remains failed.
- [ ] T010 [US2] Record AllInOne execution evidence, configuration, source revision, deployment/cleanup outcomes, and remaining validation gaps in the [#1309](https://github.com/Azure/missionlz/issues/1309) issue body; update the verified operating instructions in `docs/testing.md`.

**Checkpoint**: Both User Story 1 (reusable lifecycle + offline tests) and User Story 2 (live AllInOne validation evidence) are complete.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final cross-artifact verification across `T005`, `T006`, and `T010` (`./tests/Invoke-Tests.ps1`, Super-Linter, Bicep build, and `docs/testing.md` synchronization with [#1309](https://github.com/Azure/missionlz/issues/1309)). All executable work is tracked within `T001`–`T010` to match the canonical issue checklist.

---

## Dependencies & Execution Order

### Canonical Task Dependencies (from [#1309](https://github.com/Azure/missionlz/issues/1309))

- `T002` and `T003` follow `T001`.
- `T004` requires implemented deployment (`T002`) and cleanup (`T003`) behavior.
- `T005` verifies the implemented lifecycle (`T001`–`T004`); `T006` documents its behavior in `docs/testing.md`.
- `T007` can start during lifecycle development.
- `T008` and `T009` require the lifecycle (`T001`–`T005`), workflow (`T004`), and approved target configuration (`T007`) plus explicit authorization before any live Azure deployment.
- `T010` follows the live evidence tasks (`T008`, `T009`). Feature completion requires that live evidence, not just mocked tests or documentation.

### Dependency Graph

```text
T001 (Red: Contract & Failing Pester Tests)
 ├──► T002 (Green: Deployment & #1310 Hook) ──┐
 └──► T003 (Green: Baseline & Cleanup) ───────┼──► T004 (GitHub Actions Workflow) ──► T005 (Refactor & Gate Verification)
                                              │                                              │
                                              └──► T006 [P] (docs/testing.md) ───────────────┼──► T008 (Live Success + Cleanup) ──┐
                                                                                             │                                    ├──► T010 (Record Evidence & Finalize Docs)
T007 [P] (Verify AllInOne Config, Auth & Quota) ─────────────────────────────────────────────┴──► T009 (Live Failure + Cleanup) ──┘
```

### Parallel Opportunities

- **Within User Story 1**: Once `T002` and `T003` define the CLI behavior in `tests/deployment/Invoke-DeploymentValidation.ps1`, `T006` (`docs/testing.md`) can be drafted in parallel with `T004` (`.github/workflows/deployment-validation.yml`) and `T005` (`tests/deployment/*.Tests.ps1` verification) because they touch separate files.
- **Across User Stories 1 and 2**: `T007` (AllInOne subscription, authentication, and quota verification) can proceed in parallel with `T001`–`T006` lifecycle development.

---

## Parallel Example: User Story 1 & User Story 2 Preparation

```bash
# After T002 and T003 complete in tests/deployment/Invoke-DeploymentValidation.ps1:
Task T004: "Wire secure OIDC authentication, weekly scheduling, independent manual execution, cleanup, and sanitized failure reporting into .github/workflows/deployment-validation.yml"
Task T006: "Document reproducible commands, required configuration and permissions, weekly schedule, cleanup boundaries, failure investigation, and the shared #1310 integration point in docs/testing.md"
Task T007: "Resolve and verify AllInOne configuration and configure secure authentication for .github/workflows/deployment-validation.yml, using the prerequisites documented in docs/testing.md"
```

---

## Implementation Strategy

### MVP First (User Story 1: `T001`–`T006`)

1. Complete `T001` (**Red**): Author the `Invoke-DeploymentValidation.ps1` parameter/report contract and Pester tests in `tests/deployment/*.Tests.ps1`, then execute Pester to verify the tests fail for the expected reason before writing implementation code.
2. Complete `T002` and `T003` (**Green**): Implement the minimum required core Bicep deployment, [#1310](https://github.com/Azure/missionlz/issues/1310) test hook handling, pre-deployment baseline capture, and `try`/`finally` cleanup in `tests/deployment/Invoke-DeploymentValidation.ps1`, executing Pester to verify all tests pass.
3. Complete `T004`, `T005` (**Refactor**), and `T006`: Create `.github/workflows/deployment-validation.yml`, refactor `Invoke-DeploymentValidation.ps1` and the concern-specific files under `tests/deployment` for clean structure and zero duplication while keeping all Pester/coverage/linter gates green, and document operations in `docs/testing.md`.
4. **STOP and VALIDATE**: Confirm all offline tests and local CI parity gates pass before requesting approval for live execution.

### Incremental Delivery (User Story 2: `T007`–`T010`)

1. Complete `T007`: Verify AllInOne subscription ID, `AzureUSGovernment` cloud, `usgovarizona` region, OIDC authentication, permissions, and quota.
2. With explicit approval for live deployment, execute `T008` (live successful deployment + cleanup) and `T009` (live partial/failed deployment + cleanup).
3. Complete `T010`: Record verified live execution evidence in [#1309](https://github.com/Azure/missionlz/issues/1309) and finalize `docs/testing.md`.
