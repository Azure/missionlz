# Phase 1 Data Model: Test Coverage Measurement & Ratchet

**Feature**: 001-test-coverage-ratchet | **Date**: 2026-07-06

This feature has no runtime database. The "entities" from the spec are configuration/data structures
used by CI and the ratchet gate. They are defined here so the schema and relationships are explicit.

---

## Entity: Coverage Baseline

The recorded, enforced coverage floor. Stored as `tests/coverage-baseline.json` (single source of truth,
version-controlled). See the JSON schema in
[contracts/coverage-baseline.schema.json](contracts/coverage-baseline.schema.json).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `coveragePercent` | number (0–100, 2 dp) | yes | The enforced floor. Measured coverage must be ≥ this value. |
| `scope` | string | yes | What was measured, e.g. `"src/artifacts/*.ps1"`. Documents what the number covers. |
| `updated` | string (ISO-8601 date) | yes | Date the baseline was last ratcheted. |
| `note` | string | no | Short reason for the last change (e.g. `"initial baseline"`, `"ratchet after adding New-KeyVaultKey tests"`). |

**Rules**:

- `coveragePercent` MUST only increase across commits, except an explicit, reviewed downward edit
  (FR-011). CI does not auto-lower it.
- On first run when the file is absent, the gate records the initial value rather than failing (FR-016).
- Precision fixed at 2 decimal places so boundary comparison is unambiguous (FR-018).

---

## Entity: Coverage Measurement

The percentage produced by a single CI (or local) run. Ephemeral — derived from the Pester JaCoCo XML
report, not stored long-term.

| Field | Type | Description |
|-------|------|-------------|
| `coveragePercent` | number (0–100, 2 dp) | covered lines ÷ total measurable lines × 100. |
| `coveredLines` | integer | Lines executed by tests. |
| `totalLines` | integer | Total measurable lines in scope. |
| `scope` | string | Files measured (matches baseline `scope`). |
| `runId` | string | The CI run that produced it (GitHub `run_id`), for traceability. |

**Rules**:

- If `totalLines == 0` or the JaCoCo report is missing, the measurement is **invalid** → the gate fails
  with a "no coverage data" error (FR-017), distinct from a legitimate 0%.
- Published to the CI run summary so it is readable without downloading artifacts (FR-004).

**Relationship**: Each Coverage Measurement is compared against the current Coverage Baseline by the
Ratchet Gate.

---

## Entity: Ratchet Gate Result

The pass/fail outcome of comparing a Measurement to the Baseline. Represented by the exit code and
summary output of `tests/Compare-Coverage.ps1` (see
[contracts/ratchet-cli.md](contracts/ratchet-cli.md)).

| Field | Type | Description |
|-------|------|-------------|
| `status` | enum `pass` \| `fail` \| `baseline-initialized` | Gate outcome. |
| `measured` | number | The measured coverage percent. |
| `baseline` | number | The baseline compared against. |
| `reason` | string | Human-readable explanation (e.g. `"measured 42.10% >= baseline 42.10%"`, `"no coverage data produced"`). |

**State transitions**:

```text
missing baseline ── run ──▶ baseline-initialized (write file, exit 0)
measured >= baseline ─────▶ pass  (exit 0)
measured <  baseline ─────▶ fail  (exit 1, blocks merge)
no/invalid data ──────────▶ fail  (exit 1, "no coverage data")
```

---

## Entity: Bicep Validation Rule Set

The set of rules PSRule for Azure evaluates the `src/` Bicep templates against. Configured via
`ps-rule.yaml` and `.ps-rule/` (input paths, enabled rule modules, documented exclusions).

| Field | Type | Description |
|-------|------|-------------|
| `module` | string | Rule module applied, e.g. `PSRule.Rules.Azure`. |
| `inputPath` | string | Templates evaluated, e.g. `src/`. |
| `exclusions` | list | Documented, reviewable rule/file exclusions (untestable-by-design path). |
| `results` | list of `{rule, target, outcome}` | Per-rule pass/fail per resource (FR-012). |

**Rules**:

- Additive only — does not remove or weaken `az bicep build` or super-linter (FR-013).
- Exclusions are explicit and reviewable, never silent (edge case: untestable-by-design).

---

## Notes

No PII, no secrets, no persistent user data. All entities are either committed config
(`coverage-baseline.json`, `ps-rule.yaml`) or ephemeral CI output (measurement, gate result, rule
results).
