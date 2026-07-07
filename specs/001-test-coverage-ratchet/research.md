# Phase 0 Research: Test Coverage Measurement & Ratchet

**Feature**: 001-test-coverage-ratchet | **Date**: 2026-07-06

This document records the tool-selection decisions for the feature. Each decision follows the
constitution's Simplicity (I) and YAGNI (II) principles: prefer the fewest moving parts that satisfy
a present-day requirement.

---

## Decision 1 — PowerShell testing & coverage framework

**Decision**: Use **Pester 5** with its built-in code-coverage feature (`CodeCoverage.Enabled = $true`,
JaCoCo XML output) to test and measure `src/artifacts/*.ps1`.

**Rationale**:

- Pester is the de-facto standard PowerShell test framework and is explicitly named as the PowerShell
  test harness in the constitution (Principle IV → Automated Tests).
- Its coverage feature emits a **single, well-defined line-coverage percentage** and a machine-readable
  JaCoCo XML report (covered/total lines), satisfying FR-003 directly with no custom tooling.
- Pre-installed / trivially installable on `ubuntu-latest` via `Install-Module Pester -Force`; runs
  identically on a contributor's `pwsh`, giving local/CI parity (FR-005).
- `Mock` supports intercepting `Invoke-RestMethod` so tests never touch the live Azure IMDS endpoint.

**Alternatives considered**:

- *Hand-rolled coverage (parse AST / count executed lines)*: rejected — reinvents what Pester provides,
  more code to maintain, violates Simplicity.
- *No coverage, tests only*: rejected — the feature's entire purpose is a measured, ratcheted percentage.

---

## Decision 2 — Bicep rule-based validation

**Decision**: Use **PSRule for Azure (`PSRule.Rules.Azure`)** as the rule-based validator, run over the
`src/` Bicep templates / compiled ARM in a dedicated CI job.

**Rationale**:

- PSRule for Azure ships a large, maintained rule set aligned to the Azure Well-Architected Framework
  and Azure best practices — exactly the "misconfiguration and best-practice" checks US3 asks for
  (FR-012), well beyond what compilation and linting catch.
- It natively expands Bicep (`az bicep`) and evaluates the resulting resources, so it integrates with
  the existing `az bicep`-based CI without a separate compilation path.
- It is PowerShell-based, reusing the same `pwsh` runtime already introduced for Pester — no new
  language runtime, honoring Simplicity.
- Reports per-rule pass/fail with actionable detail (rule name, resource, guidance link), satisfying
  FR-012's "enough detail to locate and understand" requirement.
- It is **additive**: it does not touch or replace `az bicep build` or super-linter (FR-013).

**Alternatives considered**:

- *ARM-TTK (Azure Resource Manager Template Toolkit)*: capable, but operates on ARM JSON, has a smaller
  and more generic rule set, and the existing `super-linter` config comment explicitly notes ARM-TTK is
  not enabled. PSRule for Azure offers richer, Azure-specific rules with active maintenance. Rejected as
  the primary choice; noted as a viable alternative.
- *Native `az bicep test` / Bicep `test` files*: still maturing, requires authoring bespoke test files
  per template rather than applying a curated rule set, and provides thinner best-practice coverage.
  Rejected for now; can complement PSRule later without changing the ratchet policy.

---

## Decision 3 — Baseline storage & format

**Decision**: Store the enforced coverage floor as a single, version-controlled JSON file:
`tests/coverage-baseline.json`, containing at minimum the baseline percentage, the measured scope, and
a short note/timestamp of the last ratchet.

**Rationale**:

- A committed file gives an **auditable git history** of every baseline change (FR-006, SC-002, SC-006)
  and makes any lowering edit visible in review (FR-011, edge case: deliberate baseline edit).
- JSON is trivially read/written by the PowerShell gate script and by humans; no parser dependency.
- One file, one source of truth — Simplicity. No external database, API, or service to operate.

**Alternatives considered**:

- *Git tag / release metadata*: harder to diff and review, easy to mutate without an obvious code change.
  Rejected.
- *External coverage service (e.g., Codecov)*: adds a third-party dependency, network coupling, and a
  bypass surface (service outage or token). The constitution wants a non-bypassable, self-contained gate.
  Rejected as unnecessary for a repo whose measured scope is three scripts.
- *Plain text file (single number)*: workable, but JSON lets us record scope + note now (cheap) which
  aids the "no-data vs. 0%" and "scope grew" edge cases. Chosen JSON.

---

## Decision 4 — Making the gate non-bypassable

**Decision**: Implement the ratchet as a **real CI job that exits non-zero** on regression, then require
that check via **GitHub branch protection** on `main`. Document the required-check setup in `docs/testing.md`.

**Rationale**:

- FR-009 / SC-005 require the gate cannot be reduced to informational or opted out of. A failing job that
  is a *required* status check blocks merge and cannot be silently skipped.
- Mirrors how the constitution treats `super-linter` and `validate-build-bicep` as non-bypassable gates.
- Branch-protection configuration is a maintainer action (documented), not code — keeping the mechanism
  simple and standard.

**Alternatives considered**:

- *Annotation / comment only*: explicitly forbidden by FR-009. Rejected.
- *`continue-on-error: true` step*: makes the gate informational. Rejected.

---

## Decision 5 — Testing param-only scripts (zero-edit, mock-based)

**Decision**: Test the scripts by **mocking `Invoke-RestMethod`** (and `Start-Sleep`) and invoking the
script (dot-source / `&`) under a Pester harness, with any cmdlets absent on the runner stubbed **in the
test files only**; assert on observable behavior such as the **resource-manager-URI trailing-slash fix**,
the request method/URI/headers passed to the mocked call, and the constructed request body. The whole
script is executed under mocks so Pester records genuine line coverage (FR-002) with **zero edits to the
production `src/artifacts/*.ps1` scripts**.

**Rationale**:

- The three scripts call the Azure IMDS token endpoint (`169.254.169.254`) and the ARM API; mocking
  `Invoke-RestMethod` lets tests run offline in CI with no credentials and no network (Security: no
  secrets, no live endpoints).
- Asserting the URI-fix logic and the exact REST call arguments gives **real, observable behavioral
  coverage** per script (FR-002, US1 acceptance scenario 4), producing an honest non-zero baseline.
- **Zero production-script edits** (reviewed scope decision): the scripts are tested as-is by invoking
  them under mocks; needed command stubs live in the test files only. No helper extraction or refactor
  of `src/artifacts/*.ps1` is performed (constitution Out of Scope forbids gratuitous refactor; this
  feature takes it to zero).

**Alternatives considered**:

- *Integration tests against real Azure*: needs credentials, network, and a live VM/Key Vault; slow,
  flaky, not runnable locally or in PR CI. Rejected.
- *Refactor every script into fully unit-testable modules first*: larger blast radius than the feature
  needs; deferred. The mock-based approach yields a genuine baseline now.

---

## Edge-case resolutions (from spec)

| Edge case | Resolution |
|-----------|------------|
| First run / no baseline | `Compare-Coverage.ps1` treats a missing baseline as "record initial baseline" (write + pass), never a spurious fail (FR-016). |
| Coverage tool reports no data | Zero measurable lines / missing JaCoCo report → gate **fails** with a distinct "no coverage data" error, not a 0% pass or accidental improvement (FR-017). |
| Rounding at boundary | Comparison is `measured >= baseline` on a fixed decimal precision (2 dp); equal is a **pass** (FR-018). |
| Tests pass but coverage drops | Gate compares the percentage independently of test pass/fail; added untested code lowers % and **fails** the ratchet. |
| Improved but not ratcheted | `measured > baseline` **passes**; ratcheting the floor is a separate, deliberate `-UpdateBaseline` action. |
| Untestable-by-design file | Documented exclusion via PSRule/Pester path config, reviewed like any code change — never a silent coverage drop. |
| Non-PR events (push to main) | Coverage is measured on both; the **committed baseline file on `main`** remains the single source of truth. The gate blocks on PRs. |

---

## Outcome

All `[NEEDS CLARIFICATION]` items from Technical Context are resolved. No open questions remain for
Phase 1.
