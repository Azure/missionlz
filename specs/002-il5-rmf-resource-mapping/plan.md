# Implementation Plan: IL5 RMF Resource Mapping Documentation

**Branch**: `002-il5-rmf-resource-mapping` | **Date**: 2026-08-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-il5-rmf-resource-mapping/spec.md`

**Feature Issue**: [#1301](https://github.com/Azure/missionlz/issues/1301)
**User Story**: [#1302](https://github.com/Azure/missionlz/issues/1302)

## Summary

Create one document under `docs/` that inventories core Mission Landing Zone resources
reachable from `src/mlz.bicep`, groups them into security capabilities, classifies each
as Default, Optional, or Absent, and maps each security contribution to representative
DoD IL5 RMF controls.

Repository source will establish MLZ behavior; DoD and NIST publications will establish
RMF and IL5 requirements; current Microsoft Azure Government guidance will establish
platform offering, isolation, shared-responsibility, service-scope, and configuration
facts. The document will identify exact settings and core-template gaps without changing
infrastructure and will place an authorization limitation before the mapping.

## Technical Context

**Language/Version**: GitHub-flavored Markdown; Bicep source is evidence only and is not
modified.

**Primary Dependencies**: Core `src/mlz.bicep` and transitively reachable
`src/modules/*.bicep`; DoD CC SRG; DoDI 8510.01; NIST SP 800-37 Rev. 2 and one declared
NIST SP 800-53 release; current Microsoft Azure Government IL5, isolation, shared
responsibility, audit-scope, Azure Policy, Defender, Firewall, Monitor, and compute
availability guidance.

**Storage**: Version-controlled Markdown only. No runtime state or database.

**Testing**: Markdown diagnostics and the repository's currently available validation;
completeness review against the reachable core Bicep graph; citation sampling;
structured classification and timed-lookup inspection; authorization-language scan;
link validation where tooling is available. Planned coverage-ratchet work is not
represented as established `main` behavior.

**Target Platform**: GitHub repository documentation for contributors, mission owners,
assessors, and authorizing-organization reviewers.

**Project Type**: Documentation-only change to an existing Bicep infrastructure
repository.

**Performance Goals**: A reader unfamiliar with the repository can find a selected
capability's state, representative RMF relationship, and required action within three
minutes.

**Constraints**: Exclude `src/add-ons/`; do not change Bicep, generated ARM, deployment
behavior, or parameters; do not claim MLZ deployment confers compliance or authorization;
distinguish repository, mission, Microsoft/inherited, shared, and external
responsibilities; time-bound dynamic service, initiative, region, and SKU claims; pass
Markdown validation with zero errors and warnings.

**Scale/Scope**: Seven top-level core modules plus their reachable local module graph;
one new document under `docs/` and one navigation link. Related resource declarations
are grouped by security purpose while retaining source and resource discoverability.

## Constitution Check

*GATE: Passed before Phase 0 research and re-checked after Phase 1 design.*

| Principle | Assessment | Status |
| --- | --- | --- |
| I. Simplicity | One documentation page, one source hierarchy, one mapping schema, and one navigation link. | Pass |
| II. YAGNI | Covers only core resources and the approved IL5 RMF use case; add-ons and a full authorization package remain out of scope. | Pass |
| III. Single Responsibility | Research captures evidence, the model defines concepts, the contract defines document shape, and the quickstart defines validation. | Pass |
| IV. Validation-Driven Infrastructure | No infrastructure behavior changes; validation reflects the repository's current CI maturity and covers Markdown, graph completeness, citations, classifications, and claim language. | Pass |
| Generated Artifact Sync | No Bicep source or parameter changes, so generated artifacts remain untouched. | Pass (N/A) |
| Platform and Add-On Constraints | Inventory starts at `src/mlz.bicep`, follows only `src/modules/`, and excludes `src/add-ons/`. | Pass |
| Security and SCCA/SACA | The plan documents contributions and gaps without weakening controls or changing deployed resources. | Pass |
| Diagnostics and Auditing | Existing diagnostics are documented, including retention and Log Analytics public-access gaps; no logging is removed. | Pass |
| GitHub Issue Discipline | Parent Feature #1301 and User Story #1302 are recorded in the spec and plan. | Pass |

**Post-design result**: No violations. Dynamic compliance facts remain behind
publication-time verification gates.

## Project Structure

### Planning Artifacts

```text
specs/002-il5-rmf-resource-mapping/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   `-- document-contract.md
|-- checklists/
|   `-- requirements.md
`-- tasks.md                 # Created later by /speckit.tasks
```

### Repository Files Affected During Implementation

```text
docs/
`-- il5-rmf-resource-mapping.md   # New mapping document

README.md                         # Add one discoverability link

src/mlz.bicep                     # Evidence only; unchanged
src/modules/                      # Evidence only; unchanged
src/add-ons/                      # Excluded; unchanged
```

**Structure Decision**: Keep one searchable mapping page and keep planning evidence in
this feature directory. Do not create a machine-readable compliance catalog because no
current requirement consumes one and it would imply more precision than representative
mapping supports.

## Phase 0: Research

See [research.md](research.md). It records:

- Authoritative DoD, NIST, and Microsoft sources and access caveats.
- Core-only recursive resource inventory methodology.
- Contribution-first representative-control mapping methodology.
- Shared-responsibility and no-authorization language.
- Required settings and gaps for policy, Defender, Firewall, retention, Log Analytics,
  NSG/PPSM, compute isolation, and capabilities absent from core MLZ.
- Publication-time verification for dynamic initiative, service-scope, region, and SKU
  facts.

**Output**: [research.md](research.md), with no unresolved planning questions.

## Phase 1: Design and Contracts

- [data-model.md](data-model.md) defines Core MLZ Capability, Capability State, RMF
  Relationship, Required IL5 Action, Responsibility Boundary, Authoritative Source, and
  Review Baseline.
- [contracts/document-contract.md](contracts/document-contract.md) defines required
  sections, row fields, controlled vocabulary, citation rules, and release gates.
- [quickstart.md](quickstart.md) defines validation for inventory completeness,
  classification, settings, sources, authorization language, and Markdown.
- The repository agent-context script updates `.github/copilot-instructions.md` after
  design artifacts are complete.

## Phase 2: Task Planning Preview

`/speckit.tasks` will define implementation tasks later:

1. Freeze source baselines and reconcile every reachable created core resource to one
   capability row.
2. Draft scope, terminology, shared responsibility, and the pre-table authorization
   limitation.
3. Build mapping rows with state, contribution, representative controls, required action,
   ownership, evidence, and citations.
4. Add the README link and run the quickstart validation scenarios.

This planning workflow does not create the final `docs/` page or modify `README.md`.

## Complexity Tracking

No Constitution Check violations. No entries are required.

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| *(none)* | N/A | N/A |
