# Tasks: [FEATURE NAME]

**ID**: [YYMM-NNN] | **Spec**: [link] | **Design**: [link] | **Implementation Plan**: [link or N/A]

## Format

```
- [ ] [ID] [P?] [Story?] Description with file path
```

- **[P]** = parallelizable (different files, no dependency on incomplete tasks)
- **[USn]** = user story reference (required in story phases, omitted in setup/polish)

## Verification Scope

- **Required automated checks**: [Unit/integration/contract/accessibility/etc.,
  or N/A with rationale]
- **Required manual/UAT scenarios**: [Scenario names mapped to USn acceptance
  criteria, or N/A]
- **Evidence expected before completion**: [Command output, screenshots,
  reviewer signoff, logs, metrics, or N/A]
- **Deferred / retired test items**: [Items intentionally not run and why, or N/A]

## Pre-Task Checklist (UI Features Only)

Complete before starting any implementation tasks:

- [ ] Reconciliation status is `Task-Ready` in `ux-figma-reconciliation.md`
- [ ] Every `QG-UX-*` gate has evidence or approved amendment rationale
- [ ] Final Figma frame/node IDs are locked and referenced
- [ ] i18n and token constraints are documented in the implementation pack
- [ ] No unresolved high-severity UX/accessibility conflicts remain

> Remove this section for non-UI features.

## Phase 1: Setup

- [ ] T001 Create project structure per design
- [ ] T002 Initialize project with dependencies

## Phase 2: Foundation

- [ ] T003 [Blocking prerequisite for all stories]
- [ ] T004 [P] [Another blocking prerequisite]

## Phase 3: [User Story 1 Title] (P1)

**Goal**: [What this story delivers]
**Independent test**: [How to verify in isolation]

- [ ] T005 [P] [US1] Create [Model] in src/models/[file]
- [ ] T006 [US1] Implement [Service] in src/services/[file]
- [ ] T007 [US1] Implement [endpoint/feature] in src/[file]

## Phase 4: [User Story 2 Title] (P2)

**Goal**: [What this story delivers]
**Independent test**: [How to verify in isolation]

- [ ] T008 [P] [US2] Create [Model] in src/models/[file]
- [ ] T009 [US2] Implement [Service] in src/services/[file]

## Phase N: Polish

- [ ] TXXX [P] Documentation updates
- [ ] TXXX Code cleanup and optimization

## QA/UAT Verification (When Required)

- [ ] TXXX [US1] Run required automated verification for [acceptance criterion] in [test path or command]
- [ ] TXXX [US1] Prepare or validate required test data for [scenario] in [path or environment]
- [ ] TXXX [US1] Execute manual/UAT scenario [name] and record evidence in [artifact or PR]
- [ ] TXXX Confirm QA review status, deferred test items, and deployment readiness evidence in implementation-plan.md or PR description

> Include this section only when required by the spec, risk profile, acceptance
> criteria, constitution gates, or Verification Strategy.

## UI/UX Verification (UI Features Only)

- [ ] TXXX [US1] Confirm the approved visual source or document that no prototype governs implementation
- [ ] TXXX [US1] Verify keyboard navigation and visible focus states on primary journey screens
- [ ] TXXX [US1] Validate loading, empty, and error states for critical user actions
- [ ] TXXX [P] [US1] Validate responsive behavior at agreed breakpoints
- [ ] TXXX [P] [US1] Validate reduced-motion and interaction feedback behavior
- [ ] TXXX [US1] Capture screenshot or recording evidence against the approved visual source
- [ ] TXXX [US1] Document intentional deviations from Figma/prototype output, if any

> Remove this section for non-UI features.

## Dependencies

- **Setup** → no dependencies, start immediately
- **Foundation** → depends on Setup; blocks all stories
- **Stories** → depend on Foundation; can run in parallel or sequential by priority
- **Polish** → depends on desired stories being complete
