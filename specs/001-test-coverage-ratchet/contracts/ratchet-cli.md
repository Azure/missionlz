# Contract: `Compare-Coverage.ps1` (Ratchet Gate CLI)

**Feature**: 001-test-coverage-ratchet | **Date**: 2026-07-06

This is the interface contract for the ratchet gate script. Implementation lives at
`tests/Compare-Coverage.ps1`. The contract is what the CI workflow and contributors depend on; the
internal implementation may change as long as this contract holds.

---

## Purpose

Compare a measured coverage percentage against the committed baseline
(`tests/coverage-baseline.json`) and produce a pass/fail result that gates merge. Optionally ratchet
the baseline upward.

## Invocation

```powershell
# Gate mode (default) — used by CI on every pull request
./tests/Compare-Coverage.ps1 `
    -CoverageReport ./coverage.xml `           # JaCoCo XML produced by Pester
    -BaselinePath   ./tests/coverage-baseline.json

# Ratchet mode — deliberate, documented baseline raise
./tests/Compare-Coverage.ps1 `
    -CoverageReport ./coverage.xml `
    -BaselinePath   ./tests/coverage-baseline.json `
    -UpdateBaseline `
    -Note "ratchet after adding New-KeyVaultKey tests"
```

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-CoverageReport` | string (path) | yes | — | Path to the Pester JaCoCo XML coverage report. |
| `-BaselinePath` | string (path) | no | `tests/coverage-baseline.json` | Path to the baseline JSON file. |
| `-UpdateBaseline` | switch | no | off | When set, raises the baseline to the measured value (ratchet). Refuses to lower. |
| `-Note` | string | no | empty | Note recorded in the baseline when `-UpdateBaseline` is used. |

## Behavior & Outputs

The script prints a single-line human-readable result and (in CI) appends the measured percentage to
`$GITHUB_STEP_SUMMARY` so it is visible without downloading artifacts (FR-004).

### Exit codes

| Exit | Meaning | Condition |
|------|---------|-----------|
| `0` | **pass** | Measured coverage `>=` baseline (equal is a pass — FR-018). |
| `0` | **baseline-initialized** | Baseline file did not exist; the script wrote it from the measured value (FR-016). |
| `0` | **ratcheted** | `-UpdateBaseline` set and measured `>` current baseline; baseline raised and written. |
| `1` | **fail (regression)** | Measured coverage `<` baseline (FR-008). Blocks merge. |
| `1` | **fail (no data)** | Coverage report missing, unparseable, or `totalLines == 0` (FR-017). Distinct from a 0% pass. |
| `1` | **refused** | `-UpdateBaseline` set but measured `<=` current baseline (cannot lower/ no-op raise). |

### Comparison rules

- Percentages compared at **2 decimal places**; `measured >= baseline` ⇒ pass.
- "No coverage data" is never interpreted as `0%` pass or as an improvement.
- The gate result is independent of test pass/fail: even if all tests pass, added untested code that
  lowers the percentage exits `1`.

## Guarantees (contract invariants)

- **Non-bypassable**: the script exits non-zero on regression; it exposes no flag that lets a
  regression exit `0`. Bypass is only possible by editing the committed baseline downward, which is a
  visible, reviewable change (FR-009, FR-011, SC-005).
- **Deterministic**: same coverage report + same baseline ⇒ same exit code and message.
- **Local/CI parity**: identical behavior when run locally on `pwsh` and in the CI job (FR-005).

## Consumed by

- `.github/workflows/pester-coverage.yml` — runs the gate on pull requests (required status check).
- Contributors locally, per `docs/testing.md`.
