# Quickstart: AllInOne Weekly Deployment Validation & Automatic Cleanup

**Feature Issue**: [#1309](https://github.com/Azure/missionlz/issues/1309) (canonical source of truth)  
**Branch**: `1309-single-subscription-validation`

## Prerequisites

1. **PowerShell 7.4+** (`pwsh`) and **Pester 6.0.0** (for running unit/lifecycle tests locally):
   ```powershell
   Install-Module Pester -RequiredVersion 6.0.0 -Scope CurrentUser -Force -SkipPublisherCheck
   ```
2. **Azure CLI (`az`)** with the Bicep CLI installed (`az bicep version`), authenticated to `AzureUSGovernment` for live runs using the verified AllInOne tenant and subscription IDs (`T007`):
   ```bash
   az cloud set --name AzureUSGovernment
   az login --tenant "$AZURE_TENANT_ID"
   az account set --subscription "$AZURE_SUBSCRIPTION_ID"
   ```

## 1. Run Offline Unit & Lifecycle Tests (Local/CI Parity)

Run the Pester suite (including mocked lifecycle tests for `Invoke-DeploymentValidation.ps1`) without an Azure connection:

```powershell
pwsh -NoProfile -File ./tests/Invoke-Tests.ps1
```

Or run only the deployment validation lifecycle tests directly:

```powershell
pwsh -NoProfile -Command "Invoke-Pester -Path ./tests/deployment -Output Detailed"
```

**Expected Outcome**:
- Follows the Constitution `v1.1.0` **Red-Green-Refactor** TDD cycle:
  - **Red (`T001`)**: Running `Invoke-Pester` before implementation confirms the lifecycle tests fail for the expected reason.
  - **Green (`T002`–`T003`)**: Running `Invoke-Pester` after minimal implementation confirms all lifecycle tests pass.
  - **Refactor (`T005`)**: Running `./tests/Invoke-Tests.ps1` after refactoring confirms all tests and the coverage ratchet remain green.
- Verifies successful deployment + cleanup, partial deployment failure + cleanup (preserving original failure), cleanup failure reporting, pre-existing resource and Defender `Standard` plan preservation, and [#1310](https://github.com/Azure/missionlz/issues/1310) test hook handling (`Skipped` when unconfigured, `Failed` when missing/failing).

## 2. Run Live AllInOne Validation Locally (Requires Explicit Authorization)

> **Note**: Do not run live Azure deployments without explicit approval for that run.

```powershell
pwsh -NoProfile -File ./tests/deployment/Invoke-DeploymentValidation.ps1 `
  -SubscriptionId $env:AZURE_SUBSCRIPTION_ID `
  -CloudEnvironment 'AzureUSGovernment' `
  -Location 'usgovarizona' `
  -ReportOutputPath './validation-report.json'
```

**Expected Outcome**:
1. Captures pre-deployment baseline of resource groups, subscription policy assignments, security contacts, and Defender plan pricing tiers in the verified AllInOne subscription.
2. Provisions `src/mlz.bicep` with `hub`, `identity`, `operations`, and `sharedServices` mapped to the verified AllInOne subscription ID and `deployDefender = true`.
3. Executes the [#1310](https://github.com/Azure/missionlz/issues/1310) post-deployment test hook if `-TestScriptPath` is provided (or marks `TestStatus = 'Skipped'` when omitted).
4. Cleans up all run-created resource groups and run-created subscription policy assignments/security contacts and resets any Defender plans changed by the run back to `Free`, leaving pre-existing subscription resources intact.
5. Writes `./validation-report.json` and exits `0` only if deployment, testing (when configured), and cleanup all succeeded.
