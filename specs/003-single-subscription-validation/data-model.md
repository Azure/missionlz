# Phase 1 Data Model: Validate Weekly MLZ Deployments in AllInOne with Automatic Cleanup

**Feature Issue**: [#1309](https://github.com/Azure/missionlz/issues/1309) (canonical source of truth)  
**Branch**: `1309-single-subscription-validation`

## Entities

### 1. `ValidationRunConfig`

Represents the input configuration for a single deployment validation run.

| Field | Type | Constraints / Defaults | Description |
|-------|------|------------------------|-------------|
| `CloudEnvironment` | `string` | Default: `'AzureUSGovernment'` | Target Azure cloud environment (`AzureUSGovernment` or `AzureCloud`). |
| `Location` | `string` | Default: `'usgovarizona'`; must not be `'usgovvirginia'` for AllInOne | Target Azure region for subscription deployment and resource groups. |
| `SubscriptionId` | `string` | Required GUID | Primary (AllInOne) subscription ID used as the default for all tiers. |
| `HubSubscriptionId` | `string` | Default: `SubscriptionId` | Subscription ID for the `hub` tier. |
| `IdentitySubscriptionId` | `string` | Default: `SubscriptionId` | Subscription ID for the `identity` tier. |
| `OperationsSubscriptionId` | `string` | Default: `SubscriptionId` | Subscription ID for the `operations` tier. |
| `SharedServicesSubscriptionId` | `string` | Default: `SubscriptionId` | Subscription ID for the `sharedServices` tier. |
| `Identifier` | `string` | 1–5 lowercase alphanumeric chars (`^[a-z0-9]{1,5}$`); default: `wk` + 3 random chars | Unique per-run MLZ `identifier` parameter used for naming and tagging. |
| `EnvironmentAbbreviation` | `string` | Allowed: `'dev'`, `'prod'`, `'test'`; default: `'dev'` | MLZ `environmentAbbreviation` parameter. |
| `TemplatePath` | `string` | Default: `'src/mlz.bicep'` | Path to the core MLZ Bicep entrypoint. |
| `DeployIdentity` | `bool` | Default: `$true` | Enables the `identity` spoke tier in `src/mlz.bicep`. |
| `DeployDefender` | `bool` | Fixed: `$true` (validation rejects `$false`) | Enables Microsoft Defender for Cloud in `src/mlz.bicep`. |
| `TestScriptPath` | `string` | Optional (`''` when not configured) | Optional path to the [#1310](https://github.com/Azure/missionlz/issues/1310) post-deployment functional test script. |

### 2. `SubscriptionBaselineSnapshot`

Captures the pre-deployment state of each target subscription before `az deployment sub create` runs.

| Field | Type | Description |
|-------|------|-------------|
| `SubscriptionId` | `string` | Target subscription GUID. |
| `CapturedAtUtc` | `string` | ISO-8601 UTC timestamp when the baseline was recorded. |
| `ResourceGroupNames` | `string[]` | Names of all resource groups existing in the subscription prior to deployment. |
| `PolicyAssignmentNames` | `string[]` | Names of subscription-scoped policy assignments existing prior to deployment. |
| `SecurityContactNames` | `string[]` | Names of subscription security contacts (`Microsoft.Security/securityContacts`) existing prior to deployment. |
| `DefenderPricingTiers` | `hashtable` | Map of Defender plan name (`VirtualMachines`, `StorageAccounts`, etc.) to pre-existing `pricingTier` (`Free` or `Standard`). |

### 3. `CleanupSummary`

Records the actions and any errors encountered during the post-run cleanup phase.

| Field | Type | Description |
|-------|------|-------------|
| `DeletedResourceGroups` | `string[]` | Run-created resource groups deleted during cleanup. |
| `DeletedPolicyAssignments` | `string[]` | Run-created subscription policy assignments deleted during cleanup. |
| `DeletedSecurityContacts` | `string[]` | Run-created security contacts deleted during cleanup. |
| `ResetDefenderPlans` | `string[]` | Defender plans reset back to `Free` because the run changed them from their baseline `Free` state. |
| `PreservedPreExistingItems` | `string[]` | Summary identifiers of baseline items left untouched. |
| `Errors` | `string[]` | Error messages for any cleanup action that failed. |

### 4. `ValidationRunReport`

The structured result returned by `Invoke-DeploymentValidation.ps1` and written to JSON / GitHub Actions step summary.

| Field | Type | Allowed Values / Description |
|-------|------|------------------------------|
| `RunId` | `string` | Unique deployment name (`mlz-val-<Identifier>-<timestamp>`). |
| `Identifier` | `string` | The 1–5 character MLZ `identifier` used for the run. |
| `CloudEnvironment` | `string` | Target cloud (`AzureUSGovernment`). |
| `Location` | `string` | Target region (`usgovarizona`). |
| `Subscriptions` | `object` | Map of `hub`, `identity`, `operations`, `sharedServices` subscription IDs. |
| `StartedAtUtc` | `string` | ISO-8601 UTC start timestamp. |
| `CompletedAtUtc` | `string` | ISO-8601 UTC completion timestamp. |
| `DeploymentStatus` | `string` | `'Succeeded'` \| `'Failed'` \| `'NotStarted'` |
| `DeploymentError` | `string` | Error details when `DeploymentStatus -eq 'Failed'`, otherwise `$null`. |
| `TestStatus` | `string` | `'Passed'` \| `'Failed'` \| `'Skipped'` |
| `TestError` | `string` | Error details when `TestStatus -eq 'Failed'`, otherwise `$null`. |
| `CleanupStatus` | `string` | `'Succeeded'` \| `'Failed'` \| `'NotRun'` |
| `CleanupSummary` | `CleanupSummary` | Detailed record of deleted, reset, and preserved resources plus any cleanup errors. |
| `OverallStatus` | `string` | `'Succeeded'` only when `DeploymentStatus -eq 'Succeeded'`, `CleanupStatus -eq 'Succeeded'`, and `TestStatus -in @('Passed', 'Skipped')`; otherwise `'Failed'`. |

## State Transitions

```text
[Initialize & Validate Parameters]
        │
        ▼
[Capture Pre-Deployment Baseline]
        │
        ▼
[Provision MLZ (az deployment sub create)]
   ├── Succeeds ──► DeploymentStatus = Succeeded
   │                    │
   │                    ▼
   │            [Post-Deployment Test Hook (#1310)]
   │               ├── Not configured ──► TestStatus = Skipped
   │               ├── Runs & passes  ──► TestStatus = Passed
   │               └── Missing/fails  ──► TestStatus = Failed
   │
   └── Fails/Throws ──► DeploymentStatus = Failed, TestStatus = Skipped
        │
        ▼ (always executes via finally)
[Cleanup Run-Created Resources & Restore Defender Baseline]
   ├── All cleanup ops succeed ──► CleanupStatus = Succeeded
   └── Any cleanup op fails    ──► CleanupStatus = Failed
        │
        ▼
[Compute OverallStatus & Emit Report]
   └── Exit non-zero if OverallStatus == 'Failed'
```
