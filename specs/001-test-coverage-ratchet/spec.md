# Feature Specification: Automated Test Coverage Measurement and No-Regression Coverage Ratchet

**Feature Branch**: `001-test-coverage-ratchet`

**Feature Issue**: [#1292](https://github.com/Azure/missionlz/issues/1292) — Establish automated test coverage measurement and a no-regression coverage ratchet

**Created**: 2026-07-06

**Status**: Draft

**Input**: User description: "Establish automated test coverage measurement and a no-regression coverage ratchet for Mission Landing Zone. MLZ currently has no automated tests and no coverage measurement. Begin measuring automated test coverage, publish the number in CI, record an initial baseline, and add a CI gate that fails any change lowering coverage below the recorded baseline. The baseline starts low and ratchets upward over time; the enforced floor never drops. 100% coverage is the long-term target, not a day-one requirement."

## User Scenarios & Testing *(mandatory)*

<!--
  User stories are prioritized user journeys. Each is independently testable and, on its
  own, delivers a viable slice of the coverage-measurement foundation.
  Each story maps to an existing GitHub User Story issue (sub-issue of Feature #1292).
-->

### User Story 1 - Measure PowerShell artifact test coverage in CI (Priority: P1)

**Maps to issue**: [#1293](https://github.com/Azure/missionlz/issues/1293)

A maintainer wants to know how much of the repository's PowerShell automation is exercised by
automated tests. Today there are no tests at all, so the "real" coverage number is unknown and
assumed to be zero. This story stands up a test harness for the PowerShell artifacts under
`src/artifacts/` (`New-ADDSForest.ps1`, `New-KeyVaultKey.ps1`, `Remove-VirtualMachine.ps1`),
adds at least one genuine behavioral test per script, measures line coverage during
CI, and publishes the resulting percentage so it is visible on every run.

**Why this priority**: This is the minimum viable product for the whole feature. Without a real,
non-zero, automatically-produced coverage number there is nothing to baseline, publish, or ratchet.
It is the foundation every other story builds on, and it delivers value on its own by giving
maintainers their first-ever objective measurement of test coverage.

**Independent Test**: Run the test suite in CI (and locally) against the three PowerShell scripts
with no other story implemented. Confirm the tests execute, at least one real behavioral assertion
per script passes, a coverage percentage greater than zero is computed, and that percentage is
surfaced in the CI run output/summary.

**Acceptance Scenarios**:

1. **Given** the PowerShell test harness and tests exist, **When** CI runs on a pull request,
   **Then** the tests execute and the run reports pass/fail results for each script.
2. **Given** the tests pass, **When** coverage is measured, **Then** a single coverage percentage
   for the PowerShell artifacts is computed and is strictly greater than 0%.
3. **Given** a completed CI run, **When** a maintainer opens the run, **Then** the coverage
   percentage is visible in the run's output or summary without needing to download artifacts.
4. **Given** each of the three scripts, **When** its test runs, **Then** at least one test asserts
   real observable behavior of that script (not a placeholder or trivially-true assertion).
5. **Given** a contributor working locally, **When** they run the documented local test command,
   **Then** they get the same pass/fail and coverage result CI produces.

---

### User Story 2 - Enforce a no-regression coverage ratchet gate in CI (Priority: P2)

**Maps to issue**: [#1295](https://github.com/Azure/missionlz/issues/1295)

A maintainer wants assurance that coverage can only ever hold steady or improve, never silently
decline. This story records an initial coverage baseline in the repository, adds a required CI gate
that compares each pull request's measured coverage against that recorded baseline, fails the check
when coverage drops below the baseline, and provides a documented, deliberate way to ratchet the
baseline upward as coverage improves. The gate cannot be silently bypassed.

**Why this priority**: This is the enforcement mechanism that turns a measured number into a policy.
It directly implements the constitution's non-negotiable "no regression on coverage %" ratchet. It
depends on a real coverage number existing (US1), so it follows US1, but it is the core reason the
feature exists.

**Independent Test**: With a recorded baseline in place, open one pull request whose changes keep
coverage at or above the baseline (expect the gate to pass) and another whose changes drop coverage
below the baseline (expect the gate to fail and block merge). Then follow the documented ratchet
procedure to raise the baseline and confirm the new, higher floor is enforced.

**Acceptance Scenarios**:

1. **Given** no baseline exists yet, **When** this story is implemented, **Then** an initial
   coverage baseline value is recorded in a version-controlled location in the repository.
2. **Given** a recorded baseline, **When** a pull request's measured coverage is greater than or
   equal to the baseline, **Then** the coverage gate passes.
3. **Given** a recorded baseline, **When** a pull request's measured coverage is below the baseline,
   **Then** the coverage gate fails and the pull request is blocked from merging.
4. **Given** the coverage gate, **When** a contributor attempts to merge a coverage-lowering change,
   **Then** there is no informational-only or opt-out path that lets the change merge without
   restoring coverage.
5. **Given** coverage has improved above the current baseline, **When** a maintainer follows the
   documented ratchet procedure, **Then** the recorded baseline is raised to the new higher value
   and the higher floor is subsequently enforced.
6. **Given** a recorded baseline, **When** any change attempts to lower the recorded baseline value
   itself, **Then** that change is visible in review as a deliberate baseline edit (not an incidental
   side effect) and is subject to review rejection.

---

### User Story 3 - Rule-based validation testing for Bicep templates in CI (Priority: P3)

**Maps to issue**: [#1294](https://github.com/Azure/missionlz/issues/1294)

A maintainer wants automated, rule-based checks that catch misconfigurations and best-practice
violations in the Bicep templates beyond what compilation and linting already catch. This story adds
rule-based validation testing for the Bicep templates in CI. It complements — and does not replace —
the existing `az bicep build` compilation and super-linter checks, and it contributes to the overall
measured validation posture the ratchet protects.

**Why this priority**: This broadens automated validation from PowerShell into the primary
infrastructure language, materially improving confidence in template changes. It is valuable but
follows the measurement foundation (US1) and the enforcement gate (US2), because the ratchet policy
must be established before additional validation surfaces are folded into it.

**Independent Test**: Run the Bicep rule-based validation against the current templates in CI and
confirm it evaluates the templates against a defined rule set and reports pass/fail results, without
requiring US1 or US2 to be present.

**Acceptance Scenarios**:

1. **Given** the Bicep templates in `src/`, **When** CI runs, **Then** a rule-based validation step
   evaluates the templates against a defined set of rules and reports pass/fail results.
2. **Given** a template that violates a configured rule, **When** validation runs, **Then** the
   violation is reported with enough detail to locate and understand it.
3. **Given** the existing `az bicep build` and super-linter checks, **When** the new validation is
   added, **Then** the existing checks continue to run and are not removed or weakened.
4. **Given** a contributor working locally, **When** they run the documented local validation
   command, **Then** they get the same rule-based results CI produces.

---

### User Story 4 - Document the testing and coverage policy for contributors (Priority: P4)

**Maps to issue**: [#1296](https://github.com/Azure/missionlz/issues/1296)

A contributor wants to understand how to run tests locally, how coverage is measured, and how the
ratchet works before they open a pull request. This story adds contributor-facing documentation
covering local test execution, how coverage is calculated and reported, how the no-regression gate
behaves, and how to ratchet the baseline upward — and links it from the contributing guide.

**Why this priority**: Documentation makes the new policy usable and self-service for contributors,
reducing failed CI runs and back-and-forth. It naturally follows the mechanisms it describes (US1–US3)
because it documents their behavior.

**Independent Test**: A contributor unfamiliar with the feature follows only the new documentation and
is able to run the tests locally, produce a coverage number, understand what the ratchet gate does,
and find the documentation linked from the contributing guide.

**Acceptance Scenarios**:

1. **Given** the new documentation, **When** a contributor reads it, **Then** they can find the exact
   commands to run the tests locally.
2. **Given** the new documentation, **When** a contributor reads it, **Then** they understand how
   coverage is measured and reported.
3. **Given** the new documentation, **When** a contributor reads it, **Then** they understand how the
   no-regression ratchet gate behaves and how to raise the baseline.
4. **Given** the contributing guide, **When** a contributor reads it, **Then** it links to the new
   testing and coverage documentation.

---

### Edge Cases

- **First run / no prior baseline**: When no baseline has ever been recorded, US2's gate must have a
  defined behavior (record the initial baseline rather than fail spuriously).
- **Coverage tool reports zero or no data**: If the coverage tool produces no measurable data (e.g., a
  misconfiguration causes zero files to be measured), the gate must not misinterpret "no data" as a
  legitimate 0% pass or as an accidental improvement.
- **Rounding at the boundary**: Coverage exactly equal to the baseline must pass; the comparison rule
  for "equal to baseline" must be unambiguous (equal is a pass).
- **Tests pass but coverage drops**: A pull request whose tests all pass but that adds untested code
  (lowering the percentage) must still be blocked by the ratchet gate.
- **Coverage improves but contributor forgets to ratchet**: Improving coverage without raising the
  baseline must be allowed (it still passes); ratcheting is a deliberate, documented action, not an
  automatic side effect that could mask later regressions.
- **New untestable-by-design file added**: Adding a file that legitimately cannot be covered must have a
  defined, reviewable path (e.g., documented exclusion) rather than forcing a coverage drop.
- **CI runs on non-PR events**: The measurement and gate behavior on pushes to `main` vs. pull requests
  must be defined so the baseline source of truth stays consistent.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST execute automated tests for the PowerShell artifacts under
  `src/artifacts/` (`New-ADDSForest.ps1`, `New-KeyVaultKey.ps1`, `Remove-VirtualMachine.ps1`) as part
  of CI on pull requests.
- **FR-002**: The system MUST include at least one real behavioral test per PowerShell script such
  that the recorded baseline coverage is a genuine, non-zero measurement.
- **FR-003**: The system MUST compute a single, well-defined coverage percentage for the measured
  scope during each CI run.
- **FR-004**: The system MUST publish the computed coverage percentage in the CI run so a maintainer
  can read it without downloading artifacts.
- **FR-005**: The system MUST allow a contributor to run the same tests and produce the same coverage
  result locally using documented commands (local/CI parity).
- **FR-006**: The system MUST record an initial coverage baseline value in a version-controlled
  location in the repository.
- **FR-007**: The system MUST provide a required CI gate that compares each pull request's measured
  coverage against the recorded baseline.
- **FR-008**: The coverage gate MUST pass when measured coverage is greater than or equal to the
  recorded baseline, and MUST fail when measured coverage is below the recorded baseline.
- **FR-009**: The coverage gate MUST NOT be silently bypassable — it MUST NOT be reducible to an
  informational-only check or provide an opt-out that allows a coverage-lowering change to merge.
- **FR-010**: The system MUST provide a documented, deliberate procedure for ratcheting the recorded
  baseline upward as coverage improves.
- **FR-011**: The recorded baseline MUST only move upward through the documented ratchet procedure; any
  change that lowers the recorded baseline value MUST be an explicit, reviewable edit subject to
  rejection in review.
- **FR-012**: The system MUST perform rule-based validation of the Bicep templates in `src/` during CI,
  evaluating them against a defined rule set and reporting pass/fail results with actionable detail.
- **FR-013**: The Bicep rule-based validation MUST complement, and MUST NOT remove or weaken, the
  existing `az bicep build` compilation check and the existing super-linter checks.
- **FR-014**: The system MUST provide contributor documentation covering: how to run the tests locally,
  how coverage is measured and reported, how the no-regression ratchet gate behaves, and how to raise
  the baseline.
- **FR-015**: The contributing guide MUST link to the new testing and coverage documentation.
- **FR-016**: The system MUST define behavior for the first run when no baseline exists yet (record the
  initial baseline rather than fail spuriously).
- **FR-017**: The system MUST treat "no coverage data produced" distinctly from a legitimate 0% or an
  accidental improvement, and MUST NOT let a measurement failure pass the gate.
- **FR-018**: Coverage exactly equal to the recorded baseline MUST be treated as a pass (unambiguous
  boundary handling).

### Key Entities *(include if feature involves data)*

- **Coverage Measurement**: The single coverage percentage produced by a CI run for the measured scope
  (initially the PowerShell artifacts). Key attributes: percentage value, the scope it was measured
  over, and the CI run that produced it.
- **Coverage Baseline**: The recorded, enforced coverage floor stored in the repository. Key attributes:
  the current baseline percentage and its version-controlled history. Relationship: each CI run's
  Coverage Measurement is compared against the current Coverage Baseline by the ratchet gate.
- **Ratchet Gate**: The required CI check that evaluates a Coverage Measurement against the Coverage
  Baseline and produces a pass/fail result that gates merge.
- **Bicep Validation Rule Set**: The defined set of rules the Bicep templates are evaluated against.
  Key attributes: the rules applied and the pass/fail results per template.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every pull request CI run reports an automated test coverage percentage that is greater
  than zero and readable directly in the run summary.
- **SC-002**: An initial coverage baseline is recorded in the repository and visible in version control
  history.
- **SC-003**: 100% of pull requests that lower measured coverage below the recorded baseline are blocked
  from merging by the required coverage gate.
- **SC-004**: 100% of pull requests that keep measured coverage at or above the recorded baseline pass
  the coverage gate on that basis.
- **SC-005**: There is no configuration path by which a coverage-lowering pull request can merge without
  restoring coverage (the gate cannot be silently bypassed).
- **SC-006**: The recorded coverage baseline never decreases over the project's history except through an
  explicit, reviewed baseline edit.
- **SC-007**: A contributor can, using only the documented local commands, reproduce the CI coverage
  result on their own machine.
- **SC-008**: Every pull request CI run reports rule-based validation results for the Bicep templates in
  addition to the pre-existing build and lint checks.
- **SC-009**: A contributor unfamiliar with the feature can, following only the linked documentation, run
  the tests, obtain a coverage number, and explain how the ratchet works.

## Assumptions

- **Users are contributors and maintainers**: The "users" of this feature are people contributing to and
  maintaining the MissionLZ repository, not deployers of the landing zone.
- **Starting coverage is effectively zero**: The repository has no automated tests today, so the first
  recorded baseline will be a low, honest number produced by the minimal tests added in US1.
- **Tool selection is a planning decision**: The specific tools are deliberately left to the planning
  phase. PowerShell testing/coverage is assumed to use a Pester-style harness with code-coverage
  measurement; Bicep rule-based validation is assumed to use one of PSRule for Azure, ARM-TTK, or native
  Bicep test files. The spec does not mandate which.
- **CI platform is GitHub Actions**: New checks are added to the existing GitHub Actions CI alongside the
  existing `super-linter` and `validate-build-bicep` workflows.
- **Baseline lives in the repository**: The enforced baseline is stored in a version-controlled file in
  the repo (exact location/format decided in planning), so its history is auditable.
- **Measured scope grows over time**: The initial measured scope is the PowerShell artifacts; the ratchet
  policy and measurement can expand to additional surfaces in later work without changing the
  no-regression principle.
- **Required-check enforcement is available**: Branch protection / required-status-check configuration is
  available so the coverage gate can be made non-bypassable.

## Out of Scope

- Achieving any specific coverage percentage in this feature (e.g., there is no goal of reaching 50% or
  100% here; only measuring, baselining, publishing, and enforcing no-regression).
- Rewriting or refactoring the existing `src/artifacts/*.ps1` scripts for testability. This feature makes
  **zero edits** to those production scripts — coverage is obtained by invoking them under mocks (test-only
  files are added; the scripts themselves are not modified).
- Replacing or removing the existing `az bicep build` compilation check or the existing super-linter
  checks.
- Adding a Bicep coverage percentage folded into the ratchet (US3 adds rule-based validation, not a Bicep
  coverage percentage); expanding the measured scope is future work.
