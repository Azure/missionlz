# Contract: Deployment Validation Lifecycle CLI & Workflow Interface

**Feature Issue**: [#1309](https://github.com/Azure/missionlz/issues/1309) (canonical source of truth)  
**Branch**: `1309-single-subscription-validation`

## 1. PowerShell Entrypoint Contract (`tests/deployment/Invoke-DeploymentValidation.ps1`)

### Synopsis

Executes a full Mission Landing Zone deployment validation lifecycle: parameter validation, pre-deployment ownership baseline snapshot, subscription-scope Bicep provisioning (`src/mlz.bicep`), optional post-deployment functional test hook ([#1310](https://github.com/Azure/missionlz/issues/1310)), and guaranteed post-run cleanup (`try`/`finally`).

### Parameters

| Parameter | Type | Mandatory | Default | Contract Rules |
|-----------|------|-----------|---------|----------------|
| `-SubscriptionId` | `string` | Yes | — | Non-empty GUID string; used as default for all enabled tiers in AllInOne mode. |
| `-HubSubscriptionId` | `string` | No | `$SubscriptionId` | Overrides hub subscription ID (reusable by [#1316](https://github.com/Azure/missionlz/issues/1316)). |
| `-IdentitySubscriptionId` | `string` | No | `$SubscriptionId` | Overrides identity spoke subscription ID. |
| `-OperationsSubscriptionId` | `string` | No | `$SubscriptionId` | Overrides operations spoke subscription ID. |
| `-SharedServicesSubscriptionId` | `string` | No | `$SubscriptionId` | Overrides sharedServices spoke subscription ID. |
| `-Location` | `string` | No | `'usgovarizona'` | Target Azure region. Rejects `'usgovvirginia'` due to quota restrictions in `#1309`. |
| `-CloudEnvironment` | `string` | No | `'AzureUSGovernment'` | Target Azure cloud name verified against active `az account show`. |
| `-Identifier` | `string` | No | Generated `wk<3-alnum>` | Must match `^[a-z0-9]{1,5}$`. |
| `-EnvironmentAbbreviation` | `string` | No | `'dev'` | Must be `'dev'`, `'prod'`, or `'test'`. |
| `-TemplatePath` | `string` | No | `'src/mlz.bicep'` | Path to core MLZ Bicep template. |
| `-DeployIdentity` | `bool` | No | `$true` | Passes `deployIdentity=true` to `src/mlz.bicep`. |
| `-DeployDefender` | `bool` | No | `$true` | Must be `$true`; throws parameter validation error if `$false` is supplied. |
| `-TestScriptPath` | `string` | No | `''` | Optional path to [#1310](https://github.com/Azure/missionlz/issues/1310) test runner script. |
| `-ReportOutputPath` | `string` | No | `''` | Optional file path to write the JSON `ValidationRunReport`. |
| `-PassThru` | `switch` | No | `$false` | Returns the structured `ValidationRunReport` object to the pipeline. |

### Exit Code & Error Semantics

- **Exit `0`** (or returns report without throwing when `-PassThru` is not failing): Only when `DeploymentStatus -eq 'Succeeded'`, `CleanupStatus -eq 'Succeeded'`, and `TestStatus -in @('Passed', 'Skipped')`.
- **Throws / Exit `1`**:
  - Pre-deployment validation or baseline capture fails.
  - `DeploymentStatus -eq 'Failed'` (even when `CleanupStatus -eq 'Succeeded'`).
  - `TestStatus -eq 'Failed'` (including when `-TestScriptPath` is explicitly provided but does not exist, or when the test script exits non-zero/throws).
  - `CleanupStatus -eq 'Failed'` (even when `DeploymentStatus -eq 'Succeeded'`).

### Post-Deployment Test Hook Interface ([#1310](https://github.com/Azure/missionlz/issues/1310))

When `-TestScriptPath` is provided and exists, `Invoke-DeploymentValidation.ps1` invokes it after provisioning succeeds and before cleanup starts, passing:
- `-SubscriptionId`
- `-HubSubscriptionId`
- `-IdentitySubscriptionId`
- `-OperationsSubscriptionId`
- `-SharedServicesSubscriptionId`
- `-Location`
- `-Identifier`
- `-EnvironmentAbbreviation`

If `-TestScriptPath` is omitted/empty, `TestStatus` is recorded as `'Skipped'` (never `'Passed'`).

---

## 2. GitHub Actions Workflow Contract (`.github/workflows/deployment-validation.yml`)

### Triggers

- `schedule`: Weekly cron (`0 9 * * 1` — Mondays at 09:00 UTC).
- `workflow_dispatch`: Manual trigger with optional inputs:
  - `location` (approved choice: `usgovarizona`)
  - `environment_abbreviation` (default: `dev`, options: `dev`, `test`, `prod`)
  - `identifier` (optional override; auto-generated when blank)
  - `test_script_path` (optional path for [#1310](https://github.com/Azure/missionlz/issues/1310) functional test suite)

### Security & Permissions

- Minimum `permissions`: `id-token: write`, `contents: read`.
- Authenticates to `AzureUSGovernment` via `azure/login` using OIDC federated credentials (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`).
- Uses the `AllInOne` GitHub environment and the Government audience `api://AzureADTokenExchangeUSGov`; serializes runs without canceling an active lifecycle.
- Both triggers check out current `main`, and the summary records the actual checked-out revision.
- Publishes the sanitized report even on failure; missing reports are visible errors.
- Never logs secrets, tokens, or customer IP ranges in workflow outputs or `$GITHUB_STEP_SUMMARY`.
