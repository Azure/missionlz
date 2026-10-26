# Testing and Coverage

Mission Landing Zone measures automated test coverage for its PowerShell artifacts
and enforces a **no-regression coverage ratchet**: coverage may hold steady or
improve, but a change that lowers it fails CI. The long-term goal is 100% coverage;
the enforced floor starts where the code is today and only ever moves up.

This guide covers how to run the tests locally, how coverage is measured, how the
ratchet gate behaves, and how to raise the baseline.

## Prerequisites

- **PowerShell 7.4+** (`pwsh`), including on Windows. Windows PowerShell 5.1
  cannot run this repository's test harness.
- **Pester 6.0.0** (pinned so local and CI produce the same number):

```powershell
Install-Module Pester -RequiredVersion 6.0.0 -Scope CurrentUser -Force -SkipPublisherCheck
```

The `-SkipPublisherCheck` switch is needed on Windows to install alongside the
in-box Pester 3.4.0.

## Running the tests

From the repository root:

```powershell
pwsh ./tests/Invoke-Tests.ps1
```

This runs every `*.Tests.ps1` under `tests/`, measures line coverage over
`src/artifacts/*.ps1`, writes a JaCoCo report to `coverage.xml` at the repo root,
and prints a single coverage percentage. The same command runs in CI, so the local
result matches CI.

The tests exercise the artifact scripts through **mocks** (no live Azure calls, no
credentials, no network) and make **no edits** to the production scripts.

## How coverage is measured

- Coverage is the **line-coverage percentage** from the report-level JaCoCo `LINE`
  counter in `coverage.xml` (`covered / (covered + missed)`).
- The same number is used everywhere — local display, the CI summary, and the
  enforced baseline — via the shared helper `tests/Get-CoveragePercent.ps1`.
- `coverage.xml` is generated and git-ignored. Only `tests/coverage-baseline.json`
  is committed.

## The no-regression ratchet gate

The gate is `tests/Compare-Coverage.ps1`. It compares the measured coverage against
the committed baseline in `tests/coverage-baseline.json`:

```powershell
pwsh ./tests/Compare-Coverage.ps1 -CoverageReport ./coverage.xml
```

Exit codes:

| Exit | Meaning | Condition |
|------|---------|-----------|
| `0` | pass | Measured coverage is greater than or equal to the baseline (equal passes). |
| `0` | baseline-initialized | No baseline existed yet; it is written from the measured value. |
| `1` | fail (regression) | Measured coverage is below the baseline. Add tests to restore it. |
| `1` | fail (no data) | The report is missing, unparseable, or has zero measurable lines. |

The gate is independent of test pass/fail: even if all tests pass, adding untested
code that lowers the percentage fails the gate. There is no flag that lets a
regression pass — the baseline can only be lowered by a deliberate, reviewable edit
to `tests/coverage-baseline.json`.

## Raising the baseline (ratcheting up)

When you add tests and coverage improves, raise the floor deliberately:

```powershell
pwsh ./tests/Invoke-Tests.ps1
pwsh ./tests/Compare-Coverage.ps1 -CoverageReport ./coverage.xml -UpdateBaseline -Note "why coverage went up"
```

This rewrites `tests/coverage-baseline.json` to the new, higher value. It refuses to
lower the baseline. Commit the updated baseline with your change.

## Making the gate non-bypassable

For the ratchet to actually block merges, a repository admin must add the
**`pester-coverage`** job as a **required status check** in branch protection for
`main`. Without that, the job still runs and reports, but a failing gate would not
block the merge button.

## Bicep rule validation (coming soon)

Rule-based validation of the Bicep templates with PSRule for Azure is planned as a
follow-up (issue #1294), introduced reporting-first. It is not part of this guide
yet.

## AllInOne deployment validation

The [deployment-validation workflow](../.github/workflows/deployment-validation.yml)
implements the deployment and cleanup lifecycle for
[#1309](https://github.com/Azure/missionlz/issues/1309). It checks out current `main`
and runs every Monday at 09:00 UTC, with independent manual execution available.
The target is the dedicated AllInOne subscription in `AzureUSGovernment`,
`usgovarizona`. The hub and all enabled spokes use that same subscription;
identity and Defender deployment remain enabled.

The lifecycle and workflow have offline tests. Azure authentication, permissions,
regional quota, and successful and failed live deployment cleanup still require
verification under #1309. Mocked tests are not live deployment evidence.

### Secure configuration and permissions

Before enabling scheduled execution or approving a manual run:

1. Verify the actual AllInOne tenant, subscription, Azure Government cloud, region,
   resource-provider availability, and quota for the current core template.
   `usgovvirginia` is excluded. Quota verification may be deferred while developing
   locally, but not before provisioning.
2. Have an authorized administrator configure a Microsoft Entra application or
   managed identity with a GitHub OIDC federated credential. For the GitHub
   environment below, use issuer `https://token.actions.githubusercontent.com`,
   subject `repo:Azure/missionlz:environment:AllInOne`, and audience
   `api://AzureADTokenExchangeUSGov`. The audience must match the workflow.
3. Create the GitHub environment `AllInOne`, restrict it to `main`, and configure
   environment secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and
   `AZURE_SUBSCRIPTION_ID`. Do not configure a client secret. Configure reviewers
   according to the approved operating policy; required reviews also gate
   scheduled jobs.
4. Grant the identity only the subscription-scoped permissions needed to read
   baselines, create subscription deployments and core resources, delete run-owned
   resource groups, manage subscription policy assignments, and read/write/delete
   the applicable Defender security contacts and pricing configuration. Pricing
   cleanup uses updates, not deletion. Policy assignment writes and deletes are
   required even when optional compliance-policy deployment is disabled.
   Verify the assigned roles cover these operations before provisioning; do not
   assume a resource deployment role grants policy-assignment permissions.
5. Keep authentication/bootstrap resources outside the run-owned identifier.
   Do not run other provisioning against this dedicated subscription during a
   validation run. Workflow concurrency serializes AllInOne runs without canceling
   an active lifecycle; it cannot serialize external operators.

The workflow grants GitHub only `contents: read` and `id-token: write`, and does
not retain checkout credentials. Microsoft documents the Government environment
and token audience in
[Azure Login with OIDC](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect#connect-to-azure-government-clouds-and-azure-stack-hub-clouds).
Configuring identities, roles, environment secrets, or live execution requires
separate authorization; local implementation does not authorize those actions.

### Offline lifecycle tests

The concern-specific files under [tests/deployment](../tests/deployment/) cover
configuration, ownership baselines, provisioning, cleanup, test hooks, outcomes,
and workflow invocation. Each file can run alone. To run the directory:

```powershell
pwsh -NoProfile -Command '
    $result = Invoke-Pester -Path ./tests/deployment -Output Detailed -PassThru
    if ($result.Result -ne "Passed") { exit 1 }
'
```

To run the files in parallel without coverage:

```powershell
pwsh -NoProfile -Command '
    $config = New-PesterConfiguration
    $config.Run.Path = "./tests/deployment"
    $config.Run.Parallel = $true
    $config.Run.PassThru = $true
    $result = Invoke-Pester -Configuration $config
    if ($result.Result -ne "Passed") { exit 1 }
'
```

For the full offline gate, use the repository runner and coverage comparison:

```powershell
pwsh -NoProfile -File ./tests/Invoke-Tests.ps1
pwsh -NoProfile -File ./tests/Compare-Coverage.ps1 -CoverageReport ./coverage.xml
```

Coverage remains scoped to `src/artifacts/*.ps1`; enabling coverage makes Pester
run sequentially. The workflow tests execute its actual PowerShell step in an
isolated process with a recording lifecycle stub; they do not authenticate or
provision Azure resources.

### Authorized local and manual execution

Live execution incurs Azure charges. Obtain approval for the target configuration
and each live validation exercise before running these commands.

Authenticate with the approved identity to `AzureUSGovernment`, and inspect the
JSON returned by `az account show --subscription $env:AZURE_SUBSCRIPTION_ID
--output json`. Verify its subscription ID, `environmentName`, tenant, and enabled
state against the approved configuration. The lifecycle requires an existing
authenticated Azure CLI session and rejects an account/cloud mismatch.

From the repository root, run the same entrypoint used by GitHub Actions:

```powershell
pwsh -NoProfile -File ./tests/deployment/Invoke-DeploymentValidation.ps1 `
    -SubscriptionId $env:AZURE_SUBSCRIPTION_ID `
    -CloudEnvironment AzureUSGovernment `
    -Location usgovarizona `
    -ReportOutputPath (Join-Path ([IO.Path]::GetTempPath()) 'mlz-validation-report.json')
```

An omitted identifier generates a short run identifier. An explicit `-Identifier`
must be unique and contain lowercase letters/digits only, within the template's
length limit. The lifecycle refuses identifiers already used by baseline resource
groups. Optional `-EnvironmentAbbreviation` defaults to `dev`.

After the workflow is merged to `main` and its target configuration is approved,
trigger it from the GitHub Actions **deployment-validation** page or run:

```bash
gh workflow run deployment-validation.yml --repo Azure/missionlz --ref main
```

Manual inputs allow the approved region, environment abbreviation, an optional
identifier, and an optional `test_script_path`. Both scheduled and manual runs
deploy current `main`, not an arbitrary selected feature branch.

### Cleanup boundaries and functional test integration

The lifecycle captures resource-group and subscription-security baselines before
provisioning, and runs cleanup in `finally` after successful or failed deployment
attempts, including partial deployments without outputs.

- Delete resource groups only when absent from the baseline and matching the run's
  `rg-<identifier>-*` name or `identifier` tag.
- Delete the core template's subscription policy assignment and security contact
  only if they were created by the run. Preserve unrelated subscription resources
  and restore pre-existing core security configuration changed by deployment.
- Reset run-modified Defender pricing to `Free` when it was not already paid
  before the run. Preserve pre-existing paid plans; subscription pricing does not
  support the resource-scope pricing DELETE API.
- Continue other cleanup actions after a cleanup error and report the failure.
  Successful cleanup never changes a failed deployment or test into success.

The shared comprehensive assertions belong to
[#1310](https://github.com/Azure/missionlz/issues/1310), not this lifecycle.
Supply `-TestScriptPath` locally or `test_script_path` manually to run that script
after successful provisioning and before cleanup. It receives subscription IDs,
location, identifier, and environment abbreviation in a separate `pwsh` process.
The script must exit nonzero on failure. An unconfigured hook is `Skipped`, never
`Passed`; an explicitly requested missing or failing hook fails the run.

### Outcomes, evidence, and failure investigation

The Actions summary records the checked-out source revision and separate
deployment, testing, cleanup, and overall outcomes. The
`allinone-validation-report` artifact contains sanitized metadata, phase statuses,
and cleanup actions, and is uploaded even when the lifecycle fails. Missing
reports are reported as errors, including failures before the lifecycle starts.
Raw Azure CLI and functional-test output is withheld from public logs.

Use the private Azure subscription deployment history for detailed provisioning
errors. Keep credentials and customer network addressing out of artifacts,
committed files, and GitHub issue bodies. Record approved configuration, source
revision, run links, outcomes, and remaining verification gaps in #1309; do not
report mocked responses as live evidence.

Forced cancellation, runner loss, or a job timeout can prevent `finally` from
finishing. Do not cancel an active run as a cleanup mechanism. If interrupted,
inspect the run identifier and deployment history in the approved subscription,
compare against its pre-run state, and obtain authorization for recovery. Never
blindly delete matching names or downgrade existing paid Defender plans.
