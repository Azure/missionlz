---
description: "Dependency-ordered task list for the test coverage measurement and no-regression ratchet feature"
---

# Tasks: Automated Test Coverage Measurement and No-Regression Coverage Ratchet

**Input**: Design documents from `/specs/001-test-coverage-ratchet/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/ratchet-cli.md](contracts/ratchet-cli.md), [contracts/coverage-baseline.schema.json](contracts/coverage-baseline.schema.json), [quickstart.md](quickstart.md)

**Feature Issue**: [#1292](https://github.com/Azure/missionlz/issues/1292) (parent Feature)

**Branch**: `001-test-coverage-ratchet` (already checked out — do not create/switch)

**Tests**: This feature *is* a testing harness. The Pester tests in US1 are the primary deliverable, not optional. Per the reviewed scope decision, US1 achieves coverage with **zero edits to the production `src/artifacts/*.ps1` scripts** — each test invokes its script under mocks (dot-source / `&`) rather than refactoring it. TDD ordering (Red → Green) still applies: author the failing tests first, then make them pass by completing the test harness and mocks only.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story the task belongs to (US1–US4)
- Every task lists exact file paths.

## Issue Map

| Story | Priority | Issue | Slice |
|-------|----------|-------|-------|
| US1 | P1 | [#1293](https://github.com/Azure/missionlz/issues/1293) | Measure PowerShell artifact coverage in CI |
| US2 | P2 | [#1295](https://github.com/Azure/missionlz/issues/1295) | No-regression ratchet gate |
| US3 | P3 | [#1294](https://github.com/Azure/missionlz/issues/1294) | PSRule Bicep rule validation |
| US4 | P4 | [#1296](https://github.com/Azure/missionlz/issues/1296) | Contributor documentation |

## Path Conventions

New top-level `tests/` directory at the repo root holds all Pester tests, the entry point, the gate
script, and the baseline. PSRule config lives at the repo root (`ps-rule.yaml`, `.ps-rule/`). One
CI concern per workflow file under `.github/workflows/`, mirroring the existing `super-linter.yml`
and `validate-build-bicep.yml`. **Neither `src/mlz.json` nor the `src/artifacts/*.ps1` scripts may be modified by this feature** — coverage is obtained by invoking the scripts under mocks, not by editing them.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the test root and keep generated coverage artifacts out of version control.

- [X] T001 [P] Create the `tests/` and `tests/artifacts/` directory structure at the repository root per [plan.md](plan.md) Project Structure.
- [X] T002 [P] Add generated coverage/test outputs (`coverage.xml`, `testResults.xml`) to the repo-root `.gitignore` so ephemeral measurement artifacts are never committed (only `tests/coverage-baseline.json` is version-controlled).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the single shared measurement seam — the JaCoCo `coverage.xml` contract — that US1 produces and US2 consumes. This is the only true cross-story dependency.

**⚠️ CRITICAL**: US1 and US2 both depend on the coverage-report shape defined here. US3 and US4 are independent of this phase.

- [X] T003 Create `tests/Invoke-Tests.ps1` as the local/CI entry point: build a Pester 6 `New-PesterConfiguration` (config + authoring API is unchanged from v5) with `Run.Path = tests/artifacts`, `CodeCoverage.Enabled = $true`, `CodeCoverage.Path = src/artifacts/*.ps1`, and `CodeCoverage.OutputFormat = 'JaCoCo'` (still the v6 default) writing `coverage.xml` at the repo root; invoke `Invoke-Pester` and print the single line-coverage percentage. Ships with the config only (no tests yet) so it is runnable and defines the `coverage.xml` contract both US1 and US2 rely on.
- [X] T004 Document the pinned tool versions the runners install (Pester `6.0.0`, PSRule.Rules.Azure `1.x`) as a comment header block in `tests/Invoke-Tests.ps1`, matching the install commands in [quickstart.md](quickstart.md) for local/CI parity (FR-005).

**Checkpoint**: `pwsh ./tests/Invoke-Tests.ps1` runs and emits an (empty-scope) `coverage.xml`; the report contract is fixed. Story work can begin.

---

## Phase 3: User Story 1 - Measure PowerShell artifact test coverage in CI (Priority: P1) 🎯 MVP — [#1293](https://github.com/Azure/missionlz/issues/1293)

**Goal**: Stand up the first real Pester harness for `src/artifacts/*.ps1`, add ≥1 genuine behavioral test per script (mocking IMDS/`Invoke-RestMethod` so it runs offline with no secrets), measure line coverage, and publish a non-zero percentage in the CI run summary.

**Independent Test**: Run `pwsh ./tests/Invoke-Tests.ps1` (locally and in the new CI job) with no other story present. Confirm each script's tests execute, at least one real behavioral assertion per script passes, a coverage percentage `> 0%` is computed, and it is surfaced in the CI run summary.

### Tests for User Story 1 (write FIRST, ensure they FAIL, then implement to green) ⚠️

- [X] T005 [P] [US1] Write behavioral Pester tests in `tests/artifacts/New-KeyVaultKey.Tests.ps1`: mock `Invoke-RestMethod` (IMDS token + Key Vault create + DES PUT) and assert the trailing-slash `$ResourceManagerUriFixed` normalization, the rotation-policy `expiryTime = 'P{KeyExpirationInDays}D'` and rotate `timeAfterCreate = 'P{KeyExpirationInDays-7}D'` body, and that the DES PUT only fires when `-Type virtualMachine`. Invoke the real script via dot-source / `&` under these mocks — **no edits to the script**; define PowerShell command stubs in the test for any cmdlet absent on the runner so it is mockable.
- [X] T006 [P] [US1] Write behavioral Pester tests in `tests/artifacts/Remove-VirtualMachine.Tests.ps1`: mock `Invoke-RestMethod` and `Start-Sleep` (offline, no 30s wait) and assert the trailing-slash URI fix plus the DELETE call to `$ResourceManagerUriFixed + $VirtualMachineResourceId + '?forceDeletion=true&api-version=...'`. Invoke the real script under these mocks — **no edits to the script**; stub any absent cmdlet in the test.
- [X] T007 [P] [US1] Write behavioral Pester tests in `tests/artifacts/New-ADDSForest.Tests.ps1`: mock external cmdlets so the script runs offline and assert at least one real observable behavior (e.g. the ADDS forest/parameter handling), not a trivially-true assertion. Invoke the real script under these mocks — **no edits to the script**; define command stubs in the test for cmdlets absent on the runner. Note: `New-ADDSForest.ps1` calls `Install-ADDSForest` (ADDSDeployment module, absent on `ubuntu-latest`) — use a stub-and-invoke pattern (define the stub in the test, then `&` the script); thin but genuine line coverage of this script is acceptable per the honest-baseline goal (FR-002).

### Implementation for User Story 1

- [X] T008 [P] [US1] Make T005 pass green with **zero edits** to `src/artifacts/New-KeyVaultKey.ps1`: finalize the test so it invokes the script under the `Invoke-RestMethod`/IMDS mocks and Pester records its line coverage; any required command stubs live in the test only. **Do not modify the script, `src/artifacts/*`, or `src/mlz.*`.**
- [X] T009 [P] [US1] Make T006 pass green with **zero edits** to `src/artifacts/Remove-VirtualMachine.ps1`: invoke the script under mocked `Invoke-RestMethod` and `Start-Sleep` so its lines are covered; stubs live in the test only. **No production-script edits.**
- [X] T010 [P] [US1] Make T007 pass green with **zero edits** to `src/artifacts/New-ADDSForest.ps1`: invoke the script under mocked external cmdlets (stubbed in the test as needed) so its lines are covered. **No production-script edits.**
- [X] T011 [US1] Finalize `tests/Invoke-Tests.ps1` so it runs the three test files, produces `coverage.xml`, prints coverage `> 0%`, and appends the percentage to `$GITHUB_STEP_SUMMARY` when running in CI (FR-004) — depends on T003, T005–T010.
- [X] T012 [US1] Add `.github/workflows/pester-coverage.yml`: PR-to-`main` + push-to-`main` + `workflow_dispatch` trigger on `ubuntu-latest`, checkout, `Install-Module Pester -RequiredVersion 6.0.0 -Force -SkipPublisherCheck` (pinned to match local for parity), run `pwsh ./tests/Invoke-Tests.ps1`, upload `coverage.xml`, and publish the percentage to the run summary. Coverage is measured on both PRs and pushes to `main` (research edge-case: non-PR events); do not remove or weaken existing workflows.

**Checkpoint**: US1 is independently functional — CI publishes a real, non-zero coverage percentage on every PR (SC-001). This is the shippable MVP.

---

## Phase 4: User Story 2 - Enforce a no-regression coverage ratchet gate in CI (Priority: P2) — [#1295](https://github.com/Azure/missionlz/issues/1295)

**Goal**: Record an initial version-controlled baseline, add a required, non-bypassable CI gate comparing each PR's measured coverage against the baseline (fail below, pass at-or-above), and provide a deliberate upward-only ratchet procedure.

**Independent Test**: With a recorded baseline, one PR at/above baseline passes the gate and one below baseline fails and blocks merge; following the documented `-UpdateBaseline` procedure raises the floor and the higher floor is then enforced.

### Tests for User Story 2 (write FIRST, ensure they FAIL, then implement to green) ⚠️

- [ ] T013 [P] [US2] Write Pester tests in `tests/Compare-Coverage.Tests.ps1` covering every contract row of [contracts/ratchet-cli.md](contracts/ratchet-cli.md): measured ≥ baseline ⇒ exit 0 (pass, equal-is-pass FR-018); measured < baseline ⇒ exit 1 (regression FR-008); missing/unparseable report or `totalLines == 0` ⇒ exit 1 (no-data, distinct from 0% — FR-017); absent baseline ⇒ writes file, exit 0 (baseline-initialized FR-016); `-UpdateBaseline` with measured > baseline ⇒ raises + exit 0; `-UpdateBaseline` with measured ≤ baseline ⇒ refused exit 1. Use small fixture JaCoCo XML files, no network.

### Implementation for User Story 2

- [ ] T014 [US2] Implement `tests/Compare-Coverage.ps1` per [contracts/ratchet-cli.md](contracts/ratchet-cli.md): params `-CoverageReport`, `-BaselinePath` (default `tests/coverage-baseline.json`), `-UpdateBaseline`, `-Note`; parse JaCoCo XML → percentage at 2 dp; exit codes/messages exactly as contracted; append result to `$GITHUB_STEP_SUMMARY` — make T013 pass green (depends on T013).
- [ ] T015 [US2] Generate the initial real baseline by running `tests/Invoke-Tests.ps1` then `tests/Compare-Coverage.ps1 -UpdateBaseline -Note "initial baseline"`, producing `tests/coverage-baseline.json` conforming to [contracts/coverage-baseline.schema.json](contracts/coverage-baseline.schema.json) with the genuine non-zero measured `coveragePercent`, `scope = "src/artifacts/*.ps1"`, and `updated` date (FR-006, SC-002). Depends on US1 producing a real percentage.
- [ ] T016 [US2] Wire the ratchet gate into `.github/workflows/pester-coverage.yml`: after coverage runs, execute `pwsh ./tests/Compare-Coverage.ps1 -CoverageReport ./coverage.xml` as a step whose non-zero exit fails the job (FR-007–FR-009). Depends on T012, T014, T015.
- [ ] T017 [US2] Ensure the gate is non-bypassable by construction: verify no flag lets a regression exit 0 and that lowering the baseline requires an explicit edit to `tests/coverage-baseline.json` (FR-009, FR-011, SC-005). Add an assertion/edge test to `tests/Compare-Coverage.Tests.ps1` proving a passing-tests-but-lower-coverage report still exits 1.
- [ ] T018 [US2] Add the schema reference so the baseline stays valid: include a `$schema`-style pointer or a header note in `tests/coverage-baseline.json` (or a validation step) tying it to [contracts/coverage-baseline.schema.json](contracts/coverage-baseline.schema.json).
- [ ] T019 [US2] Capture the branch-protection requirement (make `pester-coverage` a required status check) as a note in `.github/workflows/pester-coverage.yml` and flag it for the US4 docs so the gate cannot be silently bypassed (SC-005) — the actual repo-settings change is a maintainer action recorded here.

**Checkpoint**: US1 + US2 both work — coverage is measured *and* a real gate blocks any regression while allowing deliberate upward ratchets (SC-003–SC-006).

---

## Phase 5: User Story 3 - Rule-based validation testing for Bicep templates in CI (Priority: P3) — [#1294](https://github.com/Azure/missionlz/issues/1294)

**Goal**: Add PSRule for Azure rule-based validation of the `src/` Bicep templates in a separate CI job that complements — never replaces — `az bicep build` and super-linter.

**Independent Test**: Run PSRule against the current templates locally and in CI with no US1/US2 present; confirm it evaluates templates against a defined rule set and reports actionable pass/fail results, while the existing build and lint gates still run.

### Implementation for User Story 3

- [ ] T020 [P] [US3] Create `ps-rule.yaml` at the repo root configuring PSRule for Azure: `input.pathIgnore`/`include.module: PSRule.Rules.Azure`, input path `src/`, and any output options for readable results (FR-012).
- [ ] T021 [P] [US3] Create `.ps-rule/` config (e.g. `.ps-rule/ps-rule.yaml` or a baseline/exclusion file) holding documented, reviewable rule/file exclusions for untestable-by-design templates — explicit, never silent (data-model Bicep Validation Rule Set).
- [ ] T022 [US3] Add `.github/workflows/psrule-bicep.yml`: PR-to-`main` + push-to-`main` + `workflow_dispatch` on `ubuntu-latest`, `Install-Module PSRule.Rules.Azure`, run `Invoke-PSRule -InputPath ./src/ -Module PSRule.Rules.Azure` (or the `microsoft/ps-rule` action), and surface per-rule results in the run (FR-012). Depends on T020, T021.
- [ ] T023 [US3] Verify the new job is additive: confirm `super-linter.yml` and `validate-build-bicep.yml` remain unchanged and still run on the same PRs (FR-013, SC-008). No edits to those files; **`src/mlz.json` untouched** (PSRule only reads templates).
- [ ] T024 [US3] Confirm local/CI parity for the documented command `Invoke-PSRule -InputPath ./src/ -Module PSRule.Rules.Azure -Format File` from [quickstart.md](quickstart.md) produces the same rule results as CI (FR-004 parity intent).

**Checkpoint**: All three CI concerns run on a PR — coverage+ratchet, PSRule, and the untouched build+lint gates.

---

## Phase 6: User Story 4 - Document the testing and coverage policy for contributors (Priority: P4) — [#1296](https://github.com/Azure/missionlz/issues/1296)

**Goal**: Give contributors self-service docs for running tests locally, how coverage is measured/reported, how the ratchet gate behaves, and how to raise the baseline — linked from the contributing guide.

**Independent Test**: A contributor unfamiliar with the feature follows only `docs/testing.md` to run the tests, produce a coverage number, understand the ratchet, and finds it linked from `CONTRIBUTING.md`.

### Implementation for User Story 4

- [ ] T025 [US4] Create `docs/testing.md` documenting: local install (Pester/PSRule), `pwsh ./tests/Invoke-Tests.ps1`, reading the coverage percentage, the ratchet gate behavior + exit codes (summarizing [contracts/ratchet-cli.md](contracts/ratchet-cli.md)), the deliberate `-UpdateBaseline` ratchet procedure, and the PSRule command — mirroring [quickstart.md](quickstart.md) (FR-014).
- [ ] T026 [US4] Document in `docs/testing.md` that `pester-coverage` must be configured as a required status check (branch protection) so the gate is non-bypassable, referencing the note added in T019 (FR-009, SC-005).
- [ ] T027 [US4] Add a link to `docs/testing.md` from `CONTRIBUTING.md` (FR-015, SC-009).

**Checkpoint**: The full policy is measured, enforced, validated, and documented — feature complete.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation across stories.

- [ ] T028 Run the full [quickstart.md](quickstart.md) end-to-end (steps 2–5) and confirm every success signal: coverage `> 0` locally and in CI summary, baseline in git, a lowering change fails the gate, an at-or-above change passes, PSRule results appear (SC-001–SC-009).
- [ ] T029 [P] Confirm no secrets and no live network calls: all Pester tests mock `Invoke-RestMethod`/IMDS and run offline; no hardcoded environment URLs introduced (constitution Security; Assumptions).
- [ ] T030 Final constitution check: `src/mlz.json` and other generated artifacts are unmodified (`git status` clean for `src/mlz.*`), existing gates unchanged, and the baseline value is real and non-zero.

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup. Defines the `coverage.xml` contract that **blocks US1 and US2** (not US3/US4).
- **US1 (Phase 3)**: Depends on Foundational. The MVP; produces the real percentage US2 baselines.
- **US2 (Phase 4)**: Depends on Foundational + US1 (needs a real measured percentage to baseline and gate).
- **US3 (Phase 5)**: Depends only on Setup — independent of US1/US2; can run in parallel with them.
- **US4 (Phase 6)**: Documents US1–US3; best done after them (soft dependency — content stabilizes once mechanisms exist).
- **Polish (Phase 7)**: Depends on all desired stories being complete.

### Story independence

- **US3 (#1294)** is fully independent (no `tests/` dependency) and can be delivered any time after Setup.
- **US1 (#1293)** is the standalone MVP.
- **US2 (#1295)** is the only story with a hard dependency on another story (US1's real percentage).
- **US4 (#1296)** is documentation and depends on nothing structurally, but reads best last.

### Within each story

- Tests are written and made to FAIL before the harness/mocks that turn them green (US1 T005–T007 before T008–T010; US2 T013 before T014). US1 reaches green with test-only changes — no production-script edits.
- Entry point/config before CI wiring (T011 before T012; T014/T015 before T016).

---

## Parallel Opportunities

Tasks marked **[P]** touch different files with no incomplete-task dependency:

- **Setup**: T001, T002 in parallel.
- **US1 tests**: T005, T006, T007 in parallel (three separate test files).
- **US1 green tasks**: T008, T009, T010 in parallel (three separate test files) — each after its own failing test exists; none edits a production script.
- **US3 config**: T020, T021 in parallel (`ps-rule.yaml` vs `.ps-rule/`).
- **Cross-story**: Once Setup completes, **US3 (Phase 5) can proceed in parallel with US1+US2** since it shares no files with `tests/`.
- **Polish**: T029 in parallel with T028/T030.

### Parallel example — US1

```text
# After Foundational (T003, T004):
Launch T005, T006, T007 together (author all three failing test files):
  - tests/artifacts/New-KeyVaultKey.Tests.ps1
  - tests/artifacts/Remove-VirtualMachine.Tests.ps1
  - tests/artifacts/New-ADDSForest.Tests.ps1
# Verify Red, then launch T008, T009, T010 together to reach Green (test-only changes; no script edits).
```

---

## Implementation Strategy

- **MVP first**: Deliver **US1 (#1293)** alone — it produces the first-ever real, non-zero coverage number in CI and is independently shippable.
- **Then enforce**: Add **US2 (#1295)** to convert the number into a non-bypassable policy (the core reason the feature exists).
- **Broaden in parallel**: **US3 (#1294)** can be built alongside US1/US2 (independent files) and merged whenever ready.
- **Document last**: **US4 (#1296)** captures the finished behavior for contributors.

## Constitution Guardrails (apply to every task)

- Tests come before/with the code they cover; verify Red before Green.
- The recorded baseline (T015) MUST be a genuine, non-zero measurement — never a hand-picked number.
- The ratchet gate MUST be non-bypassable (T016, T017, T019, T026).
- **No changes to `src/mlz.json`**, other generated artifacts, or the `src/artifacts/*.ps1` scripts (T008–T010, T023, T030) — coverage comes from invoking scripts under mocks, not editing them.
- All PowerShell tests mock `Invoke-RestMethod`/IMDS and run offline with no secrets (T029).
