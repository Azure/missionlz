# Quickstart: Running Tests, Coverage & the Ratchet Locally

**Feature**: 001-test-coverage-ratchet | **Date**: 2026-07-06

This is a **validation guide** proving the feature works end-to-end. It mirrors what CI does, so a
contributor can reproduce the CI coverage result on their own machine (FR-005, SC-007). Implementation
details for the tests, gate script, and workflows live in `tasks.md` and the source files themselves.

> Prerequisites: [PowerShell 7.4+](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
> (`pwsh`) and the Azure CLI (`az`, already required for Bicep builds).

---

## 1. Install the tools (one-time)

```powershell
pwsh -Command "Install-Module Pester -RequiredVersion 6.0.0 -Scope CurrentUser -Force -SkipPublisherCheck"
```

## 2. Run the PowerShell tests + coverage (US1)

From the repository root:

```powershell
pwsh ./tests/Invoke-Tests.ps1
```

**Expected outcome**:

- Pester runs the behavioral tests for `New-ADDSForest.ps1`, `New-KeyVaultKey.ps1`, and
  `Remove-VirtualMachine.ps1`, reporting pass/fail per script.
- A JaCoCo coverage report (`coverage.xml`) is written.
- A single line-coverage percentage `> 0%` is printed to the console.

## 3. Run the ratchet gate (US2)

```powershell
pwsh ./tests/Compare-Coverage.ps1 -CoverageReport ./coverage.xml
```

**Expected outcome** (see [contracts/ratchet-cli.md](contracts/ratchet-cli.md) for full behavior):

- If measured coverage `>=` the value in `tests/coverage-baseline.json` → prints a pass line, exits `0`.
- If measured coverage `<` baseline → prints a regression line, exits `1` (this is what blocks a PR).
- Equal to the baseline → **pass** (FR-018).

## 4. Ratchet the baseline upward (deliberate, US2)

Only when you have genuinely improved coverage:

```powershell
pwsh ./tests/Compare-Coverage.ps1 -CoverageReport ./coverage.xml -UpdateBaseline -Note "why you raised it"
```

**Expected outcome**: `tests/coverage-baseline.json` is rewritten with the higher percentage and your
note. Commit this file as a visible, reviewable change. The script refuses to lower the baseline.

> **Bicep rule validation (US3)** is deferred to a follow-up PR — see `docs/testing.md`. This quickstart
> will gain a PSRule step once that work lands.

---

## What CI does (for parity)

| Workflow | Trigger | Runs | Gate |
|----------|---------|------|------|
| `pester-coverage.yml` | PR to `main` | Steps 2 + 3 above | **Required** — regression fails the PR (FR-007–FR-009) |
| `super-linter.yml` | PR to `main` | (unchanged) | Existing gate |
| `validate-build-bicep.yml` | PR to `main` | (unchanged) | Existing gate |

The measured coverage percentage is published to the CI run summary (FR-004). The ratchet check must be
configured as a **required status check** in branch protection so it cannot be bypassed (see
`docs/testing.md`, produced in US4).

---

## Success signals

- ✅ Coverage percentage `> 0` prints locally and in the CI summary (SC-001).
- ✅ `tests/coverage-baseline.json` exists and its history is in git (SC-002).
- ✅ A coverage-lowering change fails step 3 / the PR (SC-003); an at-or-above change passes (SC-004).
