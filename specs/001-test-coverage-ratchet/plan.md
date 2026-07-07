# Implementation Plan: Automated Test Coverage Measurement and No-Regression Coverage Ratchet

**Branch**: `001-test-coverage-ratchet` | **Date**: 2026-07-06 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-test-coverage-ratchet/spec.md`

**Feature Issue**: [#1292](https://github.com/Azure/missionlz/issues/1292) — parent Feature. User Stories: [#1293](https://github.com/Azure/missionlz/issues/1293) (P1), [#1295](https://github.com/Azure/missionlz/issues/1295) (P2), [#1294](https://github.com/Azure/missionlz/issues/1294) (P3), [#1296](https://github.com/Azure/missionlz/issues/1296) (P4).

## Summary

Mission Landing Zone has no automated tests and no coverage measurement today. This feature stands up
the first real test harness, measures coverage in CI, records a version-controlled baseline, and adds
a **non-bypassable no-regression coverage ratchet gate** that fails any pull request lowering coverage
below the recorded floor. The floor only ratchets upward via a deliberate, documented step.

Technical approach (minimal moving parts, per constitution Principles I & II):

- **PowerShell coverage (US1)**: [Pester 5](https://pester.dev) executes behavioral tests against the
  three scripts in `src/artifacts/`, using Pester's built-in code-coverage feature to emit a JaCoCo XML
  report and a single line-coverage percentage.
- **Ratchet gate (US2)**: A small PowerShell script (`tests/Compare-Coverage.ps1`) reads the measured
  percentage and the committed baseline (`tests/coverage-baseline.json`), fails the CI job when measured
  < baseline, and offers a documented `-UpdateBaseline` path to ratchet the floor up. The check is made
  required via branch protection so it cannot be silently bypassed.
- **Bicep rule validation (US3)**: [PSRule for Azure](https://azure.github.io/PSRule.Rules.Azure/)
  evaluates the Bicep/compiled ARM against Azure best-practice rules in a separate CI job, complementing
  (never replacing) the existing `az bicep build` and `super-linter` gates.
- **Documentation (US4)**: `docs/testing.md` documents local test/coverage commands and the ratchet
  procedure, linked from `CONTRIBUTING.md`.

## Technical Context

**Language/Version**: PowerShell 7.4+ (`pwsh`, PowerShell Core) for tests, gate script, and PSRule; Bash + YAML for GitHub Actions glue; Bicep (source under `src/`) as the validated artifact.

**Primary Dependencies**: Pester `5.x` (test + code coverage), PSRule.Rules.Azure `1.x` (Bicep/ARM rule validation), Azure CLI (`az bicep`, already used by CI). All available on `ubuntu-latest` GitHub-hosted runners.

**Storage**: Version-controlled files only — `tests/coverage-baseline.json` (the enforced floor). No database or external state.

**Testing**: Pester 5 with `CodeCoverage.Enabled = $true` emitting JaCoCo XML; percentage derived as covered ÷ total measurable lines over `src/artifacts/*.ps1`.

**Target Platform**: GitHub Actions `ubuntu-latest` (CI) and contributor workstations (macOS/Linux/Windows with `pwsh`) for local parity.

**Project Type**: Infrastructure/tooling addition to an existing Bicep IaC repository — no application runtime. New tests + CI + docs only; no changes to deployed infrastructure behavior.

**Performance Goals**: Coverage + ratchet job SHOULD complete in < 3 minutes; PSRule job SHOULD complete in < 5 minutes. Neither blocks the existing build/lint gates.

**Constraints**: Must not remove, weaken, or make informational the existing `super-linter` and `validate-build-bicep` gates (constitution DevOps → CI Gates; FR-013). Must not introduce hardcoded environment URLs. Baseline must be human-auditable in git history. Local/CI parity required (FR-005).

**Scale/Scope**: Initial measured scope is exactly three scripts (`New-ADDSForest.ps1`, `New-KeyVaultKey.ps1`, `Remove-VirtualMachine.ps1`, ~247 lines total). PSRule scope is the `src/` Bicep template set. Measured scope is designed to grow later without changing the no-regression policy.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Assessment | Status |
|-----------|------------|--------|
| **I. Simplicity** | One test framework (Pester), one rule validator (PSRule), one baseline file, one gate script. No bespoke coverage database or service. | ✅ Pass |
| **II. YAGNI** | Measures only the three existing scripts; no speculative multi-language harness, no coverage dashboard, no baseline history engine beyond git. | ✅ Pass |
| **III. Single Responsibility** | Separate concerns in separate files: measurement (Pester config), enforcement (`Compare-Coverage.ps1`), rule validation (PSRule), docs. One CI workflow per concern, mirroring existing `super-linter.yml` / `validate-build-bicep.yml`. | ✅ Pass |
| **IV. Validation-Driven Infrastructure (NON-NEGOTIABLE)** | This feature *implements* the constitution's Coverage Ratchet: measured + reported in CI, no-regression gate, upward-only floor. Existing build/lint gates preserved. Adds a test harness where none existed (explicitly encouraged). | ✅ Pass — directly fulfills |
| **Generated Artifact Sync (NON-NEGOTIABLE)** | No Bicep source changes, so `src/mlz.json` is untouched. PSRule reads the existing compiled ARM / Bicep; it does not regenerate it. | ✅ Pass (N/A) |
| **CI Gates non-bypassable** | New ratchet check is a real failing job, made required via branch protection — not informational (FR-009, SC-005). Existing gates unchanged. | ✅ Pass |
| **Security** | No secrets introduced; PowerShell tests mock the IMDS token endpoint rather than calling it. No new network endpoints or role assignments. | ✅ Pass |
| **DevOps → GitHub Issue Discipline** | Parent Feature #1292 + User Story sub-issues #1293–#1296 already exist and are linked; spec records #1292. | ✅ Pass |

**Result**: No violations. Complexity Tracking table below is intentionally empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-test-coverage-ratchet/
├── plan.md              # This file
├── research.md          # Phase 0: tool-choice rationale
├── data-model.md        # Phase 1: baseline + measurement entity shapes
├── quickstart.md        # Phase 1: run tests & coverage locally
├── contracts/
│   ├── coverage-baseline.schema.json   # JSON schema for the baseline file
│   └── ratchet-cli.md                  # Compare-Coverage.ps1 CLI contract
├── checklists/          # (pre-existing)
└── tasks.md             # Phase 2 (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

New and modified files this feature will introduce (created during implementation, not in this plan):

```text
tests/                                   # NEW — repository test root
├── artifacts/
│   ├── New-ADDSForest.Tests.ps1         # Pester behavioral tests (US1)
│   ├── New-KeyVaultKey.Tests.ps1        # Pester behavioral tests (US1)
│   └── Remove-VirtualMachine.Tests.ps1  # Pester behavioral tests (US1)
├── Invoke-Tests.ps1                     # Local/CI entry point: runs Pester + emits coverage (US1)
├── Compare-Coverage.ps1                 # Ratchet gate: measured vs baseline; -UpdateBaseline (US2)
└── coverage-baseline.json               # Version-controlled enforced floor (US2)

ps-rule.yaml                             # NEW — PSRule for Azure options/config (US3)
.ps-rule/                                # NEW — PSRule input path config / baseline (US3)

.github/workflows/
├── pester-coverage.yml                  # NEW — runs Pester, publishes %, runs ratchet gate (US1+US2)
├── psrule-bicep.yml                     # NEW — runs PSRule for Azure on src/ Bicep (US3)
├── super-linter.yml                     # UNCHANGED
└── validate-build-bicep.yml             # UNCHANGED

docs/
└── testing.md                           # NEW — local commands, coverage, ratchet procedure (US4)

CONTRIBUTING.md                          # MODIFIED — link to docs/testing.md (US4)
```

**Structure Decision**: A new top-level `tests/` directory holds all Pester tests, the local/CI entry
point, the ratchet gate script, and the baseline file — keeping test assets discoverable and separate
from deployable `src/`. PSRule configuration lives at the repo root (`ps-rule.yaml`) per PSRule
convention. CI follows the existing repo pattern of **one concern per workflow file**: `pester-coverage.yml`
owns measurement + the ratchet gate; `psrule-bicep.yml` owns Bicep rule validation. This mirrors
`super-linter.yml` and `validate-build-bicep.yml` and satisfies SRP without adding a monolithic
"test everything" workflow.

## Phase 0: Research

See [research.md](research.md). All tool-selection unknowns are resolved there:

- **PowerShell testing + coverage** → Pester 5 with built-in JaCoCo code coverage (vs. hand-rolled coverage).
- **Bicep rule validation** → PSRule for Azure (vs. ARM-TTK, vs. native `az bicep test`), with rationale.
- **Baseline storage/format** → single version-controlled `tests/coverage-baseline.json` (vs. git tag, vs. external service).
- **Non-bypassable gate** → failing CI job + branch protection required check (vs. informational annotation).
- **Testing param-only scripts** → mock `Invoke-RestMethod`/IMDS and invoke each script under mocks (stubs in test files only) for genuine coverage with **zero edits to `src/artifacts/*.ps1`**.

**Output**: No remaining `[NEEDS CLARIFICATION]`.

## Phase 1: Design & Contracts

- **Data model** → [data-model.md](data-model.md): shapes of the Coverage Baseline file, the Coverage
  Measurement, the Ratchet Gate result, and the Bicep Validation Rule Set.
- **Contracts** → [contracts/coverage-baseline.schema.json](contracts/coverage-baseline.schema.json)
  (baseline file JSON schema) and [contracts/ratchet-cli.md](contracts/ratchet-cli.md)
  (`Compare-Coverage.ps1` invocation, inputs, outputs, exit codes, edge-case behavior).
- **Quickstart** → [quickstart.md](quickstart.md): install Pester/PSRule locally, run tests, read the
  coverage number, run the ratchet check, and perform a deliberate baseline ratchet — matching CI.
- **Agent context** → the `<!-- SPECKIT -->` reference in `.github/copilot-instructions.md` is updated
  to point at this plan.

**Output**: research.md, data-model.md, contracts/*, quickstart.md, updated agent context.

## Phase 2: Task Planning (preview — produced by `/speckit.tasks`, not here)

`/speckit.tasks` will decompose this into per-User-Story task sets, ordered P1 → P4:

1. **US1 (P1, #1293)**: scaffold `tests/`, write ≥1 behavioral Pester test per script (mocking IMDS),
   enable JaCoCo coverage, create `Invoke-Tests.ps1`, add `pester-coverage.yml` job that publishes the %
   to the run summary.
2. **US2 (P2, #1295)**: create initial `tests/coverage-baseline.json` from the first measured %, add
   `Compare-Coverage.ps1` with equal-is-pass and no-data-fails semantics, wire the ratchet gate into
   `pester-coverage.yml`, document making it a required check.
3. **US3 (P3, #1294)**: add `ps-rule.yaml` + `.ps-rule/`, add `psrule-bicep.yml` running PSRule for Azure
   over `src/`, ensure existing gates still run.
4. **US4 (P4, #1296)**: write `docs/testing.md`, link it from `CONTRIBUTING.md`.

## Complexity Tracking

> No Constitution Check violations. No entries required.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| _(none)_  | —          | —                                    |
