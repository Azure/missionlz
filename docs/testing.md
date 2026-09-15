# Testing and Coverage

Mission Landing Zone measures automated test coverage for its PowerShell artifacts
and enforces a **no-regression coverage ratchet**: coverage may hold steady or
improve, but a change that lowers it fails CI. The long-term goal is 100% coverage;
the enforced floor starts where the code is today and only ever moves up.

This guide covers how to run the tests locally, how coverage is measured, how the
ratchet gate behaves, and how to raise the baseline.

## Prerequisites

- **PowerShell 7.4+** (`pwsh`) or **Windows PowerShell 5.1**.
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
