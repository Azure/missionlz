# Implementation Plan: IL5 RMF Resource Mapping Documentation

<!-- markdownlint-disable MD013 -->

**Branch**: `002-il5-rmf-resource-mapping` | **Date**: 2026-08-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-il5-rmf-resource-mapping/spec.md`

**Feature Issue**: [#1301](https://github.com/Azure/missionlz/issues/1301)
**User Stories**:

- [#1302](https://github.com/Azure/missionlz/issues/1302) — US1 mapping (completed)
- [#1303](https://github.com/Azure/missionlz/issues/1303) — US2 tactical guide (planned)

## Summary

Preserve the completed US1 deliverable, `docs/il5-rmf-resource-mapping.md`, which
inventories core Mission Landing Zone resources, classifies their capabilities, and
maps their security contributions to representative DoD IL5 RMF controls.

Add a second contributor-facing document, `docs/il5-rmf-tactical-guide.md`, for US2.
It will organize the mapping's parameter changes, proposed template changes, and
outside-MLZ work into practical steps. Parameter sections name the files to update.
Planned vNext sections state the current gap and link to the owning feature request;
engineering files and implementation steps remain in that issue. Outside-MLZ sections
name the owner, steps, and evidence. The guide does not implement infrastructure or make
mission or authorization decisions.

Repository source will establish MLZ behavior; DoD and NIST publications will establish
RMF and IL5 requirements; current Microsoft Azure Government guidance will establish
platform offering, isolation, shared-responsibility, service-scope, and configuration
facts. Both documents retain NIST SP 800-53 Revision 5 and the existing DoD IL5 source
baseline. Wider-MAG guidance will preserve its official scope and will not imply a
deployment option outside US Gov Arizona, Texas, or Virginia.

## Technical Context

**Language/Version**: GitHub-flavored Markdown; Bicep and generated ARM/JSON are
evidence only and are not modified.

**Primary Dependencies**: Completed `docs/il5-rmf-resource-mapping.md`; core
`src/mlz.bicep`, transitively reachable `src/modules/*.bicep`, generated `src/mlz.json`,
`src/mlz.uiDefinition.json`, and applicable deployment guides as file-surface evidence;
DoD CC SRG; DoDI 8510.01; NIST SP 800-37 Rev. 2; NIST SP 800-53 Revision 5; and current
Microsoft Azure Government IL5, isolation, shared-responsibility, audit-scope, Azure
Policy, Defender, Firewall, Monitor, and compute-availability guidance.

**Storage**: Version-controlled Markdown only. No runtime state or database.

**Testing**: Retain US1 validation. Compare the mapping's three action categories with
the guide, sample source paths, check for invented values and current/proposed ambiguity,
measure readability, run Markdown and link checks, and prove no infrastructure or
deployment artifact changed. Tests may be added when they provide useful repeatability.

**Target Platform**: GitHub repository documentation for contributors, mission owners,
assessors, and authorizing-organization reviewers.

**Project Type**: Documentation-only change to an existing Bicep infrastructure
repository.

**Performance Goals**: Retain the US1 three-minute capability lookup. Make each US2
change easy to follow without requiring readers to reconstruct the Bicep call path.

**Constraints**: Exclude `src/add-ons/`; do not change Bicep, generated ARM, deployment
parameters or examples, UI definitions, deployment behavior, or deployed resources;
tests are allowed when useful; do not claim MLZ deployment confers compliance or
authorization; distinguish
repository, mission, Microsoft/inherited, shared, and external responsibilities; do not
invent retention periods, PPSM rules, Defender plans, contacts, authentication methods,
recovery objectives, host selections, or AO decisions; time-bound dynamic service,
initiative, region, and SKU claims; pass Markdown and link validation with zero errors
and warnings.

**Scale/Scope**: US1 remains the completed mapping and navigation deliverable. US2 adds
one tactical document, one link from the mapping, and one repository-navigation link.
The mapping defines the work that the guide must cover.

## Constitution Check

*GATE: Passed before Phase 0 research and re-checked after Phase 1 design.*

| Principle | Assessment | Status |
| --- | --- | --- |
| I. Simplicity | US1 remains one mapping; US2 adds one practical guide organized into three action categories. | Pass |
| II. YAGNI | The second guide contains only actions already present in the mapping; add-ons, implementation, and a full authorization package remain out of scope. | Pass |
| III. Single Responsibility | Research captures evidence, the model defines concepts, the contract defines document shape, and the quickstart defines validation. | Pass |
| IV. Validation-Driven Infrastructure | No infrastructure behavior changes; US2 validates category coverage, sampled file paths, sources, readability, Markdown, and links. | Pass |
| Generated Artifact Sync | Proposed changes name generated-artifact checks, but this documentation feature does not edit Bicep or regenerate `src/mlz.json`. | Pass (N/A) |
| Platform and Add-On Constraints | Inventory starts at `src/mlz.bicep`, follows only `src/modules/`, and excludes `src/add-ons/`. | Pass |
| Security and SCCA/SACA | The plan documents contributions and gaps without weakening controls or changing deployed resources. | Pass |
| Diagnostics and Auditing | Existing diagnostics are documented, including retention and Log Analytics public-access gaps; no logging is removed. | Pass |
| GitHub Issue Discipline | Parent Feature #1301 and native User Story sub-issues #1302 and #1303 are recorded; US1 completion is preserved and US2 remains separately traceable. | Pass |

**Post-design result**: No violations. Dynamic compliance facts and tactical design
decisions remain explicit validation gates, not assumed values.

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
|-- il5-rmf-resource-mapping.md   # Completed US1; add a link to the tactical guide
`-- il5-rmf-tactical-guide.md     # New US2 ordered action and evidence guide

README.md                         # Add one tactical-guide discoverability link

src/mlz.bicep                     # Evidence only; unchanged
src/mlz.json                      # Generated evidence only; unchanged
src/mlz.uiDefinition.json         # Evidence only; unchanged
src/modules/                      # Evidence only; unchanged
src/add-ons/                      # Excluded; unchanged
```

**Structure Decision**: Keep the completed mapping as the summary and put procedural
detail in a separate tactical guide. Link the two documents. Do not create a
machine-readable catalog or implementation files.

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
- US2 file-level paths for existing parameter changes and proposed Log Analytics and
  mission-selected Dedicated Host or isolated-VM-size template changes.
- US2 owner, handoff, dependency, verification, and evidence needs for outside-MLZ work.
- Source discrepancies that the guide must state or validate: executable
  `deployDefender=true` versus stale false-default text; the multi-parameter AD DS path;
  Bastion not provisioning jumpboxes; and duplicate built-in `Allow-KV-TCP` rule names.

**Output**: [research.md](research.md), with no unresolved planning questions. Dynamic
or mission-owned facts remain named publication or deployment checks.

## Phase 1: Design and Contracts

- [data-model.md](data-model.md) retains the US1 entities. The tactical guide uses the
  five-part presentation contract instead of adding a tactical data-model schema.
- [contracts/document-contract.md](contracts/document-contract.md) retains the mapping
  contract and adds a short tactical-guide content contract.
- [quickstart.md](quickstart.md) retains US1 validation and adds US2 category coverage,
  source sampling, readability, Markdown/link, and no-source-change validation.
- The repository agent-context script updates `.github/copilot-instructions.md` after
  design artifacts are complete.

## Phase 2: Task Planning Preview

US1/#1302 tasks and its delivered mapping remain completed. `/speckit.tasks` will add
US2/#1303 implementation tasks later:

1. Freeze the tactical baseline and list the mapping actions by category.
2. Draft parameter, proposed-template, and outside-MLZ sections using files, owners,
  practical steps, verification, and evidence.
3. State the Defender, AD DS, Bastion, and duplicate `Allow-KV-TCP` discrepancies as
  current facts or explicit validation checks, without correcting source or stale docs.
4. Add the two documentation links and run every US2 quickstart validation scenario.

This planning workflow does not create or edit either `docs/` page, modify `README.md`,
or change Bicep, generated artifacts, parameters, UI definitions, or resources.

## Complexity Tracking

No Constitution Check violations. No entries are required.

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| *(none)* | N/A | N/A |
