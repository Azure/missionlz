# Phase 0 Research: Validate Weekly MLZ Deployments in AllInOne with Automatic Cleanup

**Feature Issue**: [#1309](https://github.com/Azure/missionlz/issues/1309) (canonical source of truth)  
**Branch**: `1309-single-subscription-validation`

## R1: Core MLZ Template Entry Point and Single-Subscription Parameter Mapping

- **Decision**: Deploy `src/mlz.bicep` at subscription scope via Azure CLI (`az deployment sub create`) with `hubSubscriptionId`, `identitySubscriptionId`, `operationsSubscriptionId`, and `sharedServicesSubscriptionId` all mapped to the verified AllInOne subscription ID (supplied securely via caller parameter / CI configuration and verified in `T007`), `deployIdentity = true`, `deployDefender = true`, `location = 'usgovarizona'`, and a unique 5-character `identifier` (`wk<3-char-alphanumeric>`).
- **Rationale**:
  - `src/mlz.bicep` targets `subscription` scope (`targetScope = 'subscription'`), always provisions the `hub`, `operations`, and `sharedServices` tiers, and conditionally provisions the `identity` tier when `deployIdentity = true`.
  - `identifier` has `@minLength(1)` and `@maxLength(5)` in `src/mlz.bicep` and is applied to resource group names (`rg-<identifier>-<loc>-<env>-<tier>-network`) as well as the `identifier` tag on resource groups and resources via `src/modules/logic.bicep`.
  - `deployDefender` defaults to `true` in `src/mlz.bicep` and must remain `true` per `#1309` to validate the full core security posture.
- **Alternatives considered**:
  - Compiling or running `az deployment sub what-if` only: Rejected by `#1309` ("This must perform a real deployment, not only compilation, linting, or a what-if").
  - Setting `deployDefender = false` to avoid subscription-level side effects: Explicitly prohibited by `#1309` ("Do not disable `deployDefender` to simplify cleanup").

## R2: Pre-Deployment Ownership Baseline and Subscription-Level Cleanup

- **Decision**: Capture a pre-deployment ownership baseline per unique subscription ID before provisioning begins, recording existing resource group names, subscription-level policy assignment names (`Microsoft.Authorization/policyAssignments`), security contact names (`Microsoft.Security/securityContacts`), and Defender for Cloud plan pricing tiers (`Microsoft.Security/pricings`). During cleanup, delete only resource groups, subscription policy assignments, and security contacts absent from the baseline (and matching run ownership for resource groups) and reset only Defender plans whose pricing tier changed from `Free` during the run back to `Free`.
- **Rationale**:
  - `src/modules/defender-for-cloud.bicep` deploys subscription-scoped resources (`Microsoft.Security/pricings@2023-01-01`, optional `Microsoft.Security/securityContacts@2020-01-01-preview` named `default`, and `Microsoft.Authorization/policyAssignments@2022-06-01` named `Microsoft Cloud Security Benchmark`).
  - As documented in `#1309` (`Subscription-Level Cleanup`) and `docs/deployment-guides/command-line-tools.md`, subscription-scope `Microsoft.Security/pricings` does not support HTTP `DELETE` (which is valid only for resource-level pricing). Resetting Defender plans via `az security pricing create -n <plan> --tier Free` restores the subscription to its pre-run state without calling an unsupported `DELETE` endpoint.
  - Discovering run-created resource groups by querying live subscription resource groups (filtered by `tags.identifier == <Identifier>` or `name` matching `rg-<Identifier>-*` and absent from the baseline snapshot) ensures partial deployments that fail before emitting ARM/Bicep outputs are still cleaned up completely.
- **Alternatives considered**:
  - Relying on Bicep deployment outputs to find resource groups to delete: Rejected because failed or partially completed deployments do not produce deployment outputs.
  - Blindly deleting `Microsoft Cloud Security Benchmark`, `default` security contact, or downgrading all Defender plans to `Free`: Rejected because `#1309` requires preserving any pre-existing policy assignments, security contacts, and Defender plans that were already configured before the validation run.

## R3: Failure-Preserving Lifecycle Orchestration (`try`/`finally`) and Test Hook Contract

- **Decision**: Implement `tests/deployment/Invoke-DeploymentValidation.ps1` with a strict three-phase state machine (`Deploy` -> `Test` -> `Cleanup`) wrapped in `try`/`finally` so `Cleanup` always executes when `Deploy` starts, while tracking `DeploymentStatus`, `TestStatus`, `CleanupStatus`, and `OverallStatus` independently.
- **Rationale**:
  - If `Deploy` fails, `Test` is marked `Skipped`, `Cleanup` still runs in the `finally` block, and `OverallStatus` remains `Failed` even when `Cleanup` succeeds.
  - If `Deploy` succeeds and `-TestScriptPath` is omitted, `TestStatus` is recorded as `Skipped` (never `Passed`), satisfying `#1309`'s rule that missing [#1310](https://github.com/Azure/missionlz/issues/1310) functional tests must never be reported as passed. If `-TestScriptPath` is explicitly provided by the caller and the file does not exist or throws/exits non-zero, `TestStatus` is `Failed` and fails the run.
  - If `Cleanup` encounters any error (resource group deletion failure, policy/contact deletion failure, or Defender pricing reset failure), `CleanupStatus` is `Failed` and `OverallStatus` is `Failed`.
- **Alternatives considered**:
  - Separate GitHub Actions steps for deploy and cleanup without a unified script state machine: Rejected because local execution and Red-Green-Refactor Pester unit testing require the same deterministic lifecycle behavior (`Development Workflow: Local Build Parity` and `Principle IV: Validation-Driven Infrastructure`).

## R4: Reusability for Multi-Subscription Validation (#1316) Without Scope Creep

- **Decision**: Accept tier-specific subscription ID parameters (`-HubSubscriptionId`, `-IdentitySubscriptionId`, `-OperationsSubscriptionId`, `-SharedServicesSubscriptionId`) that default to `-SubscriptionId` in `Invoke-DeploymentValidation.ps1`, deduplicating subscription IDs when capturing baselines and cleaning up subscription-scoped resources.
- **Rationale**:
  - Satisfies `#1309` US1/FR-010 ("Establish reusable deployment, secure authentication/configuration, cleanup, reporting, and testing code. The multi-subscription Feature #1316 remains in the backlog and will reuse that implementation when it starts") while keeping this branch strictly scoped to single-subscription AllInOne validation.
- **Alternatives considered**:
  - Hardcoding a single subscription variable throughout cleanup functions: Rejected because `#1316` would have to rewrite baseline and cleanup logic instead of passing tier subscription IDs.

## R5: Target Cloud, Region, and Quota Verification

- **Decision**: Target `AzureUSGovernment` in region `usgovarizona` for the dedicated AllInOne test subscription, with subscription ID, authentication, permissions, and quota verified under User Story 2 (`T007`–`T009`). Exclude `usgovvirginia`.
- **Rationale**:
  - Confirmed in `#1309` Description (`Use Azure Government (AzureUSGovernment), region usgovarizona (US Gov Arizona), for AllInOne validation. US Gov Virginia is excluded because of the requester-reported quota restrictions there. Quota-sufficiency verification is deferred during local implementation.`).
- **Alternatives considered**:
  - Defaulting to `usgovvirginia`: Rejected by `#1309`.
