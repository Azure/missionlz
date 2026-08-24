---
id: "YYMM-NNN"
title: "Feature Name"
status: "draft"              # draft | defining | planning | ready | in-dev | complete | blocked
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
system-generated: true       # created by framework vs human-authored
owner: ""                    # accountable owner = source-control provider username; empty = unassigned; see docs/reference/frontmatter.md
parent: ""                   # parent spec ID for sub-specs, empty for top-level
priority: ""                 # P1 | P2 | P3 | backlog
effort: ""                   # S | M | L | XL
dependencies: []             # spec IDs this depends on
source-authority: ""         # T1-T6 tier of primary source
phase: 1                     # project phase this belongs to
tags: []                     # free-form grouping tags
---

# Spec: [FEATURE NAME]

## Alignment Brief

**Objective**

[What this spec is trying to accomplish right now, relative to the broader project]

**Primary Users / Actors**

- **[Actor or persona]**: [Why this person or system matters for this slice]

**Key Scenarios**

- [Short scenario that anchors design and review conversations]
- [Short scenario]

**Guiding Principles**

- [Decision-making principle or tradeoff for this slice]
- [Decision-making principle or tradeoff]

## Overview

[What this feature does and why it matters — 2-3 sentences]

## UX Applicability

- **UI Surface**: [Yes/No]
- **Primary Interfaces**: [Web, Mobile, Desktop, Email, CLI, API-only, etc.]
- **Design/Prototype Inputs**: [Approved Figma/design-system/prototype links or N/A]
- **Why**: [Brief rationale]

> Remove this section if the feature is clearly non-UI (e.g., API-only,
> infrastructure-only, internal automation without end-user interaction).

## QA/UAT Readiness

- **Acceptance Owner / Reviewer**: [Role, team, client stakeholder, or TBD]
- **UAT Scope**: [Required / Not required] — [brief rationale]
- **UAT Scenario Inventory**:
  - [Scenario name mapped to USn acceptance criteria, or N/A]
- **Test Data Assumptions**: [Seed data, fixtures, permissions, tenants, or N/A]
- **Manual / Exploratory Focus**: [Judgment-heavy behavior, edge workflows,
  release confidence checks, or N/A]
- **Traceability Notes**: [How requirements, acceptance criteria, and evidence
  should connect; note gaps if unknown]

> Keep this section as a planning skeleton. Do not turn `spec.md` into full
> manual test scripts or implementation-specific test cases.

## User Stories

### US1: [Title] (P1)

[Description of this user journey in plain language]

**Why P1**: [Value and priority rationale]

**Acceptance**:
1. Given [context], when [action], then [result]
2. Given [context], when [action], then [result]

---

### US2: [Title] (P2)

[Description]

**Why P2**: [Value and priority rationale]

**Acceptance**:
1. Given [context], when [action], then [result]

---

## Requirements

### Functional

- **FR-001**: [Specific, testable requirement]
- **FR-002**: [Specific, testable requirement]

### UX & Accessibility (UI Features Only)

- **FR-UX-001**: [Keyboard and focus behavior requirement]
- **FR-UX-002**: [Responsive/layout requirement]
- **FR-UX-003**: [Loading/empty/error feedback requirement]
- **FR-UX-004**: [Design-system or approved prototype adherence requirement]

> Remove this subsection for non-UI features.

### Key Entities

- **[Entity]**: [What it represents, key attributes, relationships]

## Edge Cases

- [Boundary condition or error scenario]
- [Boundary condition or error scenario]

## Success Criteria

- **SC-001**: [Measurable, technology-agnostic outcome]
- **SC-002**: [Measurable, technology-agnostic outcome]

### UX Outcomes (UI Features Only)

- **SC-UX-001**: [Measurable usability/accessibility outcome]
- **SC-UX-002**: [Measurable responsive or task-completion outcome]
- **SC-UX-003**: [Evidence that implementation matches approved visual source]

> Remove this subsection for non-UI features.

## Assumptions

- [Reasonable default or inference made during spec creation]

## Clarifications

<!-- Appended by /ais.maintain.clarify sessions -->
