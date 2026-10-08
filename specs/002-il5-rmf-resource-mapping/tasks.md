---
description: "Dependency-ordered task list for the IL5 RMF resource mapping documentation feature"
---

<!-- markdownlint-disable MD013 -->

# Tasks: IL5 RMF Resource Mapping Documentation

**Input**: Design documents from `/specs/002-il5-rmf-resource-mapping/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/document-contract.md](contracts/document-contract.md), [quickstart.md](quickstart.md)

**Feature Issue**: [#1301](https://github.com/Azure/missionlz/issues/1301) — Document MLZ relationships to IL5 RMF

**User Story Issues**:

- [#1302](https://github.com/Azure/missionlz/issues/1302) — Review MLZ resource-to-IL5 RMF mapping (completed native sub-issue of #1301)
- [#1303](https://github.com/Azure/missionlz/issues/1303) — Document tactical changes required for an IL5 MLZ deployment (planned native sub-issue of #1301)

**Branch**: `002-il5-rmf-resource-mapping` (already checked out; do not create or switch branches)

**Scope**: Preserve the completed `docs/il5-rmf-resource-mapping.md`, add the US2 tactical guide at `docs/il5-rmf-tactical-guide.md`, and add only the mapping-to-guide and `README.md` discoverability links required by FR-018. Treat `src/mlz.bicep`, reachable `src/modules/*.bicep`, `src/mlz.json`, `src/mlz.uiDefinition.json`, and deployment guides as read-only evidence. Do not implement or modify Bicep, generated ARM, deployment behavior, parameters, UI definitions, deployed resources, or anything under `src/add-ons/`. Tests are allowed when useful.

**Tests**: Validation is documentation-focused and required by the specification: retain US1 validation, then perform US2 category coverage, source sampling, section completeness, current-versus-proposed and invented-value review, readability, Markdown/link diagnostics, and a no-infrastructure-diff proof. Infrastructure build, test, what-if, deployment, and operational checks are documented for future template implementations; they are not executed as implemented changes in this documentation-only story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches independent evidence sources and has no dependency on an incomplete task.
- **[Story]**: Maps the task to US1 / #1302 or US2 / #1303.
- Every task names the exact file or path it reads, creates, or updates.

## Issue Map

| Story | Priority | Issue | Parent Feature | Slice |
| --- | --- | --- | --- | --- |
| US1 | P1 | [#1302](https://github.com/Azure/missionlz/issues/1302) | [#1301](https://github.com/Azure/missionlz/issues/1301) | Review MLZ resource-to-IL5 RMF mapping |
| US2 | P2 | [#1303](https://github.com/Azure/missionlz/issues/1303) | [#1301](https://github.com/Azure/missionlz/issues/1301) | Document tactical changes required for an IL5 MLZ deployment |

All completed Phase 1–4 checkboxes remain historical work under User Story #1302. All new Phase 5 implementation and validation checkboxes belong under User Story #1303. Preserve both native sub-issue relationships to #1301; do not create replacement issues or task issues.

---

## Phase 1: Setup (Scope and Traceability)

**Purpose**: Confirm the approved issue hierarchy, branch, deliverables, and immutable infrastructure boundary before research verification begins.

- [x] T001 Confirm the branch, exact Feature #1301 and User Story #1302 titles and native parent relationship, one-document scope, required `README.md` navigation link, and no-infrastructure-change constraints against `specs/002-il5-rmf-resource-mapping/spec.md` and `specs/002-il5-rmf-resource-mapping/plan.md`.

**Checkpoint**: Scope and issue traceability match the approved specification; no new issue, implementation file, or infrastructure change has been introduced.

---

## Phase 2: Foundational (Blocking Evidence Gates)

**Purpose**: Establish verified repository and authoritative-source evidence before any mapping prose is drafted.

**CRITICAL**: T002–T004 block all US1 implementation tasks. Do not write mapping conclusions before both the core graph and external baselines are verified.

- [x] T002 Verify that reviewed MLZ commit `168474463215f99620531bfdeb47039bf7bd250a` and the review-date/cloud baseline in `specs/002-il5-rmf-resource-mapping/research.md` are available and applicable to `src/mlz.bicep`; record any later implementation revision explicitly in `docs/il5-rmf-resource-mapping.md` rather than silently mixing revisions.
- [x] T003 [P] Build a recursive core-only reconciliation checklist from module declarations
  in `src/mlz.bicep` through reachable local modules in `src/modules/`; enumerate every
  created resource exactly once by capability, retain source-file discoverability,
  exclude `existing` declarations and unreachable modules, and prove that no path under
  `src/add-ons/` or generated `src/mlz.json` supplies inventory truth.
- [x] T004 [P] Verify the authoritative-source register and publication metadata in
  `specs/002-il5-rmf-resource-mapping/research.md`: record the current CC SRG
  revision/date, DoDI 8510.01 publication/change date, one NIST SP 800-53
  revision/release, current Microsoft guidance review dates, Azure Government initiative
  ID availability, IL5 PA service scope, and regional isolation facts for later citation
  in `docs/il5-rmf-resource-mapping.md`; where an official source blocks verification,
  record its locator, review date, access limitation, and required mission-owner check
  instead of inferring metadata.

**Checkpoint**: The complete created-resource inventory, exclusions, review baseline, and authoritative external baselines are independently reviewable and ready to support the document.

---

## Phase 3: User Story 1 - Evaluate MLZ Support for an IL5 Authorization Package (Priority: P1) MVP — [#1302](https://github.com/Azure/missionlz/issues/1302)

**Goal**: Deliver one contributor-maintained reference that lets a mission owner or assessor identify every core MLZ capability's Default, Optional, or Absent state; security contribution; representative RMF relationships; exact IL5 action; responsibility boundary; validation evidence; and authoritative sources without implying compliance or authorization.

**Independent Test**: Using only `docs/il5-rmf-resource-mapping.md` and its citations, a reviewer can select any in-scope core capability, determine its current state and source-backed behavior, understand its representative RMF contribution, identify the exact required setting/template/external action and owner, and encounter the authorization limitation before the first mapping table.

### Implementation and Validation for User Story 1

- [x] T005 [US1] Create `docs/il5-rmf-resource-mapping.md` with the contract-required
  title/status, audience, purpose, and reviewed baseline fields for MLZ commit, review
  date, Azure Government cloud/regions, CC SRG and DoDI 8510.01 source status, and the
  single selected NIST SP 800-53 release.
- [x] T006 [US1] Add scope, assumptions, exclusions, controlled `Default`/`Optional`/`Absent` terminology, required-action types, responsibility labels, and shared-responsibility boundaries to `docs/il5-rmf-resource-mapping.md`; explicitly exclude `src/add-ons/`, unreachable modules, generated artifacts, examples, mission applications, and complete authorization-package deliverables.
- [x] T007 [US1] Place the prominent authorization and compliance limitation before or directly adjacent to the first table in `docs/il5-rmf-resource-mapping.md`, covering MLZ's component role, the scoped Azure PA, incomplete RMF coverage, required assessment/AO decisions, all five responsibility boundaries, and Policy/Defender output as evidence inputs rather than authorization decisions.
- [x] T008 [US1] Add the complete core capability inventory and mapping matrix to
  `docs/il5-rmf-resource-mapping.md` from the T003 checklist, grouping resources once by
  security purpose while retaining every associated created resource type and repository
  source link; give every row exactly one state, exact current condition/default/absence
  evidence, security contribution, representative RMF family/control IDs or explicit
  non-applicability reason, validation/evidence, responsibility, required action type,
  and supporting citations.
- [x] T009 [US1] Document exact existing-setting actions in
  `docs/il5-rmf-resource-mapping.md`: `deployPolicy=true` with `policy='IL5'` and live
  initiative verification; Defender Standard with mission-selected plans; Firewall
  Premium with tuned IDPS and threat-intelligence `Deny`; mission-derived
  workspace/flow-log retention; PPSM-derived rules for all four NSG arrays; and a
  mission/AO choice between Azure Dedicated Host and isolated VM sizes covering every
  persistent and temporary MLZ VM in wider MAG: US Gov Arizona, Texas, or Virginia.
- [x] T010 [US1] Document exact core-template gaps and external responsibilities in
  `docs/il5-rmf-resource-mapping.md`: configurable disabling of Log Analytics public
  ingestion/query with validated private paths; complete Dedicated Host placement;
  backup and recovery; identity governance; and operational SSP, authorization
  evidence, PPSM registration, vulnerability management, incident response, data
  classification, endpoint protection, and application controls without naming add-ons
  as substitutes.
- [x] T011 [US1] Complete the authoritative references, inline source locators, claim ownership, validation guidance, maintenance process, and re-review triggers in `docs/il5-rmf-resource-mapping.md`; time-bound initiative, PA scope, service, region, quota, and host-family claims to the stated review date.
- [x] T012 [US1] Add one discoverability link to `docs/il5-rmf-resource-mapping.md` in the existing documentation navigation in `README.md` as required by FR-001, preserving the surrounding repository navigation style.
- [x] T013 [US1] Execute the scope and inventory validation in `specs/002-il5-rmf-resource-mapping/quickstart.md` against `src/mlz.bicep`, reachable `src/modules/*.bicep`, and `docs/il5-rmf-resource-mapping.md`; reconcile 100% of reachable created core resources exactly once and confirm zero add-on, unreachable, `existing`, example, fixture, or generated-resource entries.
- [x] T014 [US1] Execute the row-contract and structured inspection gates from
  `specs/002-il5-rmf-resource-mapping/contracts/document-contract.md` and
  `specs/002-il5-rmf-resource-mapping/quickstart.md` against
  `docs/il5-rmf-resource-mapping.md`: validate every row field, sample
  Default/Optional/Absent conclusions for ambiguity, and trace sampled MLZ and IL5/RMF
  claims to repository and authoritative NIST, DoD/DISA/CNSS, or Microsoft evidence as
  applicable.
- [x] T015 [US1] Scan `docs/il5-rmf-resource-mapping.md` for prohibited compliance/authorization language and timeless dynamic claims per `specs/002-il5-rmf-resource-mapping/quickstart.md`; confirm contribution/evidence wording, exact action ownership, the pre-table limitation, and no universal retention, PPSM, Defender-plan, or VM-SKU prescription.
- [x] T016 [US1] Reconcile every Decision 4 finding in `specs/002-il5-rmf-resource-mapping/research.md` to a matrix row or cross-cutting section in `docs/il5-rmf-resource-mapping.md` and verify each is classified as a parameter change, template change, external implementation, or deployment-time verification.
- [x] T017 [US1] Perform the timed structured inspection in `specs/002-il5-rmf-resource-mapping/quickstart.md` and record that all four lookup questions are answerable from `docs/il5-rmf-resource-mapping.md` within three minutes; defer independent-reviewer validation until the documentation review process matures.
- [x] T018 [US1] Run `npx --yes markdownlint-cli2 docs/il5-rmf-resource-mapping.md`, inspect the `README.md` diff for only the required correctly formatted navigation link, validate that target and sampled external links, and resolve all findings in changed content before relying on repository-equivalent CI validation.
- [x] T019 [US1] Perform the final Constitution Check against
  `.specify/memory/constitution.md`, `specs/002-il5-rmf-resource-mapping/plan.md`, and the
  final git diff: confirm one new `docs/il5-rmf-resource-mapping.md` document plus only
  the required `README.md` link, zero changes under `src/`, no Bicep or generated ARM/UI
  artifact changes, no add-on scope, current validation maturity is described accurately,
  no CI gate is weakened, complete #1301/#1302 traceability, and zero Markdown warnings.

**Checkpoint**: US1 / #1302 is independently complete when all T005–T019 checkboxes are satisfied and the document passes every acceptance scenario and release gate.

---

## Phase 4: Canonical Issue Synchronization

**Purpose**: Record the verified final state in the canonical User Story after all implementation and validation tasks are complete.

- [x] T020 Synchronize the complete granular T001-T020 checklist and final completion states to canonical User Story issue #1302 after T019 passes, preserving its native parent relationship to Feature #1301 and marking T020 complete as the final synchronization action.

---

## Phase 5: User Story 2 - Plan Tactical Changes for an IL5 MLZ Deployment (Priority: P2) — [#1303](https://github.com/Azure/missionlz/issues/1303)

**Goal**: Deliver `docs/il5-rmf-tactical-guide.md` as the ordered, evidence-based planning counterpart to every action in `docs/il5-rmf-resource-mapping.md`, with exact parameter and proposed-template file surfaces, outside-MLZ ownership and handoffs, and no implemented infrastructure change.

**Independent Test**: Compare the parameter changes, proposed template changes, and outside-MLZ actions in `docs/il5-rmf-resource-mapping.md` with `docs/il5-rmf-tactical-guide.md`; confirm every mapped change has the required files or owner, practical steps, and completion check, with no unsupported requirement or implemented-infrastructure claim.

### Baseline and Guide Structure

- [x] T021 [US2] Confirm Feature #1301 and User Story #1303 traceability, record `113fb08211bffe603b20c44668df6a756ae80821` or a justified later commit as the reviewed source baseline, list the mapping actions under the three required categories, and confirm the documentation-only boundary using `specs/002-il5-rmf-resource-mapping/spec.md`, `specs/002-il5-rmf-resource-mapping/plan.md`, `specs/002-il5-rmf-resource-mapping/research.md`, and `docs/il5-rmf-resource-mapping.md`.
- [x] T022 [US2] Create `docs/il5-rmf-tactical-guide.md` in the section order required by `specs/002-il5-rmf-resource-mapping/contracts/document-contract.md`, including the prominent no-infrastructure-change limitation, audience and scope, reviewed baseline, usage guidance, current-versus-proposed rules, predeployment decisions, the three action categories, maintenance triggers, and authoritative references.

### Required Action Categories

- [x] T023 [US2] Draft the parameter-change sections in `docs/il5-rmf-tactical-guide.md`, grouping related PPSM/NSG, Firewall, logging and Sentinel, Defender, Azure Policy, Bastion, and AD DS work where useful; for every parameter include its name, executable current default, required value or decision and owner, declaration and consumer files, deployment input file when present or its confirmed absence, ordered checklist steps, a non-secret example where useful, and deployment verification.

- [x] T024 [US2] Add customer-facing planned-vNext sections for Log Analytics public
  ingestion/query and Dedicated Host placement in
  `docs/il5-rmf-tactical-guide.md`; state each current limitation, customer action, and
  expected result, link to feature requests #1304 and #1305, and keep engineering files,
  implementation steps, compatibility decisions, build instructions, and code tests in
  those issues.

- [x] T025 [US2] Draft the outside-MLZ sections in `docs/il5-rmf-tactical-guide.md`, grouping related log lifecycle and recovery, key governance, VM operations, administration and identity governance, backup and recovery, PPSM registration, vulnerability management, incident response, data classification, application controls, and SSP/assessment/risk/authorization work; for each section identify the accountable owner, ordered checklist steps, expected result, MLZ handoff when applicable, and evidence to retain without prescribing mission-owned values, products, or authorizing decisions.
- [x] T026 [US2] Integrate shared predeployment decisions and source-backed findings into `docs/il5-rmf-tactical-guide.md`: order target-region, IL5 PA/service/initiative/SKU/quota checks before dependent work; retain NIST SP 800-53 Revision 5 and the mapping's DoD IL5 baseline; name only US Gov Arizona, Texas, and Virginia for new deployments; and state the `deployDefender` default discrepancy, complete AD DS input path, Bastion-versus-jumpbox behavior, and duplicate `Allow-KV-TCP` names as current facts or checks without repairing source files.

### Navigation and Release Validation

- [x] T027 [US2] Add the forward link from `docs/il5-rmf-resource-mapping.md` to `docs/il5-rmf-tactical-guide.md`, the back link in `docs/il5-rmf-tactical-guide.md`, and one matching navigation link in `README.md`, preserving existing navigation styles.
- [x] T028 [US2] Perform category coverage and section-completeness validation from sections 9, 11, and 12 of `specs/002-il5-rmf-resource-mapping/quickstart.md`; confirm every mapped parameter, proposed-template, and outside-MLZ action is covered with the category-required fields, related grouping remains clear, and no unsupported requirement appears in `docs/il5-rmf-tactical-guide.md`.
- [x] T029 [US2] Perform source sampling and language validation from sections 10 and 13 of `specs/002-il5-rmf-resource-mapping/quickstart.md` against `docs/il5-rmf-tactical-guide.md`, `src/mlz.bicep`, reachable `src/modules/*.bicep`, `src/mlz.uiDefinition.json`, `src/mlz.json`, and `docs/deployment-guides/`; sample all three categories plus the four required discrepancy findings, verify exact file surfaces and baselines, and confirm current/proposed behavior is distinct with no invented mission, dynamic, regional-lifecycle, compliance, or authorization claim.
- [x] T030 [US2] Validate grade-11-or-lower explanatory prose, checklist readability, repository Markdown, internal navigation, and sampled external links using sections 14 and 15 of `specs/002-il5-rmf-resource-mapping/quickstart.md` against `docs/il5-rmf-tactical-guide.md`, `docs/il5-rmf-resource-mapping.md`, and `README.md`; resolve all errors and warnings only in those planned documentation files.
- [x] T031 [US2] Prove the documentation-only infrastructure boundary and complete the Constitution Check using the full git diff, `.specify/memory/constitution.md`, and `specs/002-il5-rmf-resource-mapping/plan.md`; confirm zero changes to `src/`, generated ARM/JSON, parameter/example files, UI definitions, add-ons, workflows, deployment behavior, or deployed resources, and confirm any added tests validate only this documentation feature.
- [x] T032 [US2] Synchronize T021-T032 and their final completion states from `specs/002-il5-rmf-resource-mapping/tasks.md` to canonical User Story issue #1303 after T031 passes, preserve its native parent relationship to Feature #1301, and link `docs/il5-rmf-tactical-guide.md`.

**Checkpoint**: US2 / #1303 is independently complete when T021-T032 are satisfied, all three mapping action categories are covered without invented work, the guide passes source, readability, Markdown, and link validation, and the diff proves no infrastructure artifact changed.

---

## Dependencies and Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately and establishes scope and issue traceability.
- **Phase 2 (Foundational)**: Depends on T001 and blocks all document drafting.
- **Phase 3 (US1 / #1302)**: Depends on T002–T004. T005–T011 build the document in contract order; T012 follows creation of the navigation target; T013–T019 validate the completed story and perform the final Constitution Check.
- **Phase 4 (Canonical Issue Synchronization)**: T020 depends on all implementation and validation tasks, including T019.
- **Phase 5 (US2 / #1303)**: Depends on completed US1 T001-T020 and the action inventory in `docs/il5-rmf-resource-mapping.md`. T021-T022 establish the baseline and guide structure; T023-T026 draft the three practical categories and shared findings; T027 adds navigation; T028-T031 run release validation; T032 synchronizes canonical issue #1303.

### User Story Dependencies

- **US1 / #1302 (P1)**: Completed mapping MVP and authoritative action inventory for US2.
- **US2 / #1303 (P2)**: Depends on completed US1 / #1302 but remains independently testable as a tactical planning and evidence guide; it does not depend on implementing any described parameter or template change.

### Within User Story 1

1. Create the document and reviewed baseline (T005).
2. Establish scope, terminology, responsibility, and the mandatory limitation before mapping content (T006–T007).
3. Build the complete inventory/matrix and explicit existing-setting/template-gap content (T008–T010).
4. Finish sources, maintenance guidance, and the required repository navigation link (T011–T012).
5. Run completeness, contract, source, language, timed lookup, link, and Markdown validation (T013–T018).
6. Run the final constitution and diff check (T019).
7. Synchronize final completion states to canonical issue #1302 (T020).

### Within User Story 2

1. Confirm #1303, the reviewed source baseline, the three mapping categories, and the documentation-only boundary (T021).
2. Create the guide structure and shared rules before drafting procedures (T022).
3. Draft parameter changes, proposed template changes, and outside-MLZ work in that order (T023-T025).
4. Integrate shared predeployment decisions, baselines, and source discrepancies (T026).
5. Add cross-document and repository navigation after the guide target exists (T027).
6. Validate category coverage before source sampling, then run readability, Markdown/link, and infrastructure-boundary checks (T028-T031).
7. Synchronize canonical issue #1303 only after every release gate passes (T032).

---

## Parallel Opportunities

- After T002 fixes the reviewed repository baseline, T003 can reconcile the local Bicep graph while T004 verifies independent DoD, NIST, Microsoft, Azure Government, initiative, audit-scope, region, and SKU sources.
- Document implementation tasks T005–T011 intentionally remain sequential because they update one file and later sections depend on the settled baseline, scope, terminology, limitation, and row schema.
- Validation tasks are ordered after the complete document. The structured and timed
  inspections are the current release gates; independent-reviewer validation is
  deferred until the documentation review process matures.
- Evidence for the three US2 categories may be collected in parallel after T022, but T023-T026 are not marked `[P]` because they update the same `docs/il5-rmf-tactical-guide.md` file and are integrated in practical dependency order.
- US2 release checks T028-T031 remain sequential: coverage settles the guide content before source sampling, readability and link checks, and the final diff/Constitution gate.

### Parallel Example: Foundational Verification

```text
After T002:
  Reviewer A: T003 — reconcile src/mlz.bicep and reachable src/modules/*.bicep.
  Reviewer B: T004 — verify DoD, NIST, Microsoft, and dynamic Azure sources.
Join before T005; unresolved evidence blocks document drafting.
```

### Parallel Example: US2 Evidence Collection

```text
After T022, reviewers may collect evidence in parallel without editing the guide:
  Reviewer A: parameter defaults, declaration, consumer, and deployment input surfaces for T023.
  Reviewer B: Log Analytics and Dedicated Host implementation and validation surfaces
  for T024.
  Reviewer C: owners, steps, results, handoffs, and evidence for T025.
Integrate findings into docs/il5-rmf-tactical-guide.md in T023-T026 order.
```

---

## Implementation Strategy

### MVP First

1. Complete T001–T004 to lock scope, source baselines, and the complete core inventory.
2. Complete T005–T012 in dependency order to deliver US1 / #1302.
3. Complete T013–T018 to prove the story independently against its contract and quickstart.
4. Complete T019 to perform the final Constitution Check.
5. Complete T020 to synchronize canonical issue #1302; this is the completed US1 MVP boundary.

### Incremental Delivery

1. Preserve completed US1 / #1302 as the independently usable mapping MVP.
2. Complete T021-T027 to deliver the baseline, practical three-category guide, shared decisions, and navigation for US2 / #1303.
3. Complete T028-T031 to validate US2 independently and prove the change remains documentation-only.
4. Complete T032 to synchronize canonical issue #1303; stop without implementing any proposed infrastructure work.

### Delivery Boundary

- The MVP remains completed User Story 1 / #1302; User Story 2 / #1303 is the next independently reviewable documentation increment.
- Related mapping actions may share a tactical section when each action remains clear; shared decisions and dynamic checks should be stated once.
- Findings that call for future MLZ parameter, module, or generated-artifact changes are documented only; implementing them requires a separate specification, issue hierarchy, branch, and validation plan.

## Constitution Guardrails

- Keep every implementation and story-validation checkbox under US1 / #1302 and preserve its native sub-issue relationship to Feature #1301.
- Keep every T021-T032 implementation and story-validation checkbox under US2 / #1303 and preserve its native sub-issue relationship to Feature #1301.
- Treat Bicep as read-only evidence and `src/mlz.json` as a generated artifact, never as mapping source truth.
- Do not modify `src/`, deployment parameters, generated ARM/UI artifacts, workflows, or add-ons.
- Do not claim that MLZ, Azure Policy, Defender, a resource, or a green posture result confers compliance, implements a complete control, grants a PA/ATO, or replaces assessment.
- Do not publish dynamic initiative, service-scope, region, quota, host-family, or SKU claims without a verification date and current authoritative locator.
- Markdown and repository linting must finish with zero errors and zero warnings.
