<!--
  Project Plan Template

  When generating the project plan via /ais.setup.plan, this single template
  is split into numbered files under specs/.project-plan/:

    00-index.md          — Auto-generated index linking to all files below
    01-charter.md        — Alignment Brief through Timeline (sections: Alignment Brief, Overview, Success Criteria, Stakeholders, Timeline)
    02-risks-and-decisions.md — Risks & Decisions
    03-context-sources.md    — Context Sources + Change Log

  Spec catalog and phases are no longer static files — spec information lives
  in each spec's spec.md frontmatter. Reports derive status from the repo.

  Section markers below (<!-- FILE: NN-name.md -->) indicate the split points.
-->

<!-- FILE: 01-charter.md -->
# Project Plan: [PROJECT NAME]

**Client**: [CLIENT] | **Version**: 1.0 | **Created**: [DATE] | **Updated**: [DATE]
**Status**: Draft

## Alignment Brief

**Objective**: [2-3 sentences — what this project is trying to accomplish right now]

**Primary Users / Stakeholders**:
- **[Role / persona]**: [Why this person or group matters to the project]

**Key Scenarios**:
- [Short scenario capturing a primary situation the project must support]
- [Short scenario capturing another important moment]

**Guiding Principles**:
- [Decision-making principle or tradeoff for the project]
- [Decision-making principle or tradeoff]

## Overview

**Problem**: [2-3 sentences — business problem being solved]

**Vision**: [2-3 sentences — what success looks like]

**In scope**:
- [Deliverable]

**Out of scope**:
- [Explicitly excluded item] — [reason or future project]

**Stakeholders**:

| Stakeholder | Role | Needs |
|-------------|------|-------|
| | | |

**Timeline**:

| Milestone | Target | Source | Description |
|-----------|--------|--------|-------------|
| | [date or TBD] | [document] | |

## Success Criteria

| # | Criterion | Target | How We'll Know |
|---|-----------|--------|----------------|
| SC-1 | | | |

<!-- FILE: 02-risks-and-decisions.md -->
## Risks & Decisions

| ID | Type | Description | Impact | Status |
|----|------|-------------|--------|--------|
| R-1 | Risk | | High/Med/Low | Open |
| OD-1 | Decision | | | Pending |

<!-- FILE: 03-context-sources.md -->
## Context Sources

| File | Authority | Party | Ingested | Contributed |
|------|-----------|-------|----------|-------------|
| | T? | Client/AIS | [DATE] | |

## Change Log

| Date | Change | Author |
|------|--------|--------|
| [DATE] | Project plan created | |
