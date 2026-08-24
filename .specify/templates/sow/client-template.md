# Statement of Work - Client SOW

> Core scope template for direct client SOWs. Do not generate master agreement
> boilerplate, legal terms, or signature blocks.
>
> **AIS-only authoring artifact**: Internal fields, source/status columns, spec
> mappings, readiness controls, green-sheet details, QA/QC items, and delivery
> commands support AIS planning. Do not copy them into client-deliverable prose.
> Apply `Skills/ais-sow-docx/references/writing-guidance.md` to all narrative
> that will appear in the client DOCX.

| Field | Value |
|-------|-------|
| **Client** | [Client name] |
| **Date** | [YYYY-MM-DD] |
| **Version** | 1.0 |
| **AIS Contact** | [Name, title] |
| **Client Contact** | [Name, title] |
| **Proposal** | [Link to proposal.md or source artifact] |
| **Agreement Family** | Client SOW |
| **Contract Form** | FFP / Time and materials / Retainer / Unknown |
| **Delivery Organization** | AIS / Microsoft Solution Center / Unknown |
| **Delivery Pattern** | Fixed deliverables / Outcome-driven / Managed capacity / Staff augmentation / Unknown |
| **Document Type** | Original SOW / Unknown |
| **Engagement Funding** | Customer-funded / Microsoft-funded / Microsoft-program-funded / Unknown |
| **Period of Performance** | [Start date] through [End date] - Contractual / Proposed / TBD |
| **MSA / Contract Review** | Reviewed / Pending / N/A |

---

## Background and Objectives

[Describe the client situation, business problem, and desired outcomes in the
same delivery-focused tone as prior AIS SOWs.]

---

## Strategic Approach

[Describe the delivery approach, phase/gate logic, and why this structure fits
the client's objectives. Omit this section when it does not add useful scope
context.]

---

## Microsoft Funding Integration

[Use only when applicable. Describe Microsoft funding, offset assumptions,
funding validation, and client responsibility for any uncovered cost. Omit when
not relevant.]

---

## Scope of Engagement

### In Scope

Use workstreams when the SOW covers parallel service areas; use deliverables
when the SOW is advisory, readiness, or phase-gated. Keep the structure that
best matches the source material.

#### Workstreams

| Workstream | Scope | Key Outputs | Acceptance Criteria | Spec |
|------------|-------|-------------|---------------------|------|
| [Workstream name] | [What AIS will perform] | [Outputs] | [How client accepts] | [Spec name] |

#### Deliverables

| # | Deliverable | Description | Acceptance Criteria | Spec |
|---|-------------|-------------|---------------------|------|
| D1 | [Deliverable name] | [What AIS will deliver] | [How client accepts it] | [Spec name] |

### Out of Scope

- [Explicitly excluded item with rationale]
- [Excluded item]

### Assumptions and Guardrails

- [Scope assumption about client responsibilities]
- [Assumption about access, environments, data, or dependencies]
- [Assumption about change management or phase-gate decisions]
- [Assumption about funding/program constraints, staffing, or commercial review]

---

## Project Management

[Describe governance cadence, status reporting, backlog or issue tracking,
stakeholder engagement, and escalation path at the level needed to support
delivery.]

---

## Post-Delivery Operations and Enhancement Support

*Include this section when support, operations, advisory reachback,
enhancements, onboarding, or a managed retainer are in scope. Omit when the
SOW is delivery-only.*

| Element | Commitment / Decision | Source / Status |
|---------|-----------------------|-----------------|
| Support tier | Base / Standard / Premium / TBD | [Source] |
| Coverage window | [Business hours, timezone, holidays, extended coverage, or TBD] | [Source] |
| Authoritative channel | [ServiceNow, Jira, Azure DevOps, GitHub, Teams, email, or TBD] | [Source] |
| Incident handling | [Restoration, escalation, root-cause summary, or exclusions] | [Source] |
| Service request handling | [Included request types and approval path] | [Source] |
| Advisory handling | [Office-hours, scheduled reachback, named SME, or excluded] | [Source] |
| Enhancement handling | [Backlog capacity, NTE guardrail, estimate-only, or excluded] | [Source] |
| Offshore mode | Yes / No / Partial / TBD | [Source] |
| Reporting cadence | [Weekly, monthly, quarterly, or TBD] | [Source] |

### Support Taxonomy

| Category | SOW Treatment |
|----------|---------------|
| Incident | [Production-impacting interruption or degradation within supported components] |
| Service request | [Access, configuration, deployment help, data refresh, onboarding, or documented runbook task] |
| Advisory question | [SME reachback, architecture guidance, governance question, or operational decision support] |
| Enhancement request | [New or changed behavior routed through backlog and capacity/change rules] |
| New engagement candidate | [Material new scope routed to discovery, new spec, change order, or new engagement] |

Enhancements must become a new spec, change order, or new engagement when they
add new users, integrations, data domains, environments, compliance obligations,
production dependencies, or material delivery effort beyond the selected
support tier.

---

## Project Execution Phase Details

### Phase [#] - [Phase Name]

[Describe the phase purpose, activities, and expected outcome.]

#### Client Provisions

| Provision | Needed By | Impact If Delayed |
|-----------|-----------|-------------------|
| [Access, data, stakeholder, environment, or decision] | [Date/milestone] | [Impact] |

#### Deliverables

| Deliverable | Summary | Due | Acceptance |
|-------------|---------|-----|------------|
| [Deliverable name] | [Summary] | [Date or milestone] | [Acceptance evidence] |

---

## Period of Performance and Program Approach

| Field | Value | Source | Status |
|-------|-------|--------|--------|
| Start Date | [Date or TBD] | [SOW/RFP/client approval] | Contractual / Proposed / TBD |
| End Date | [Date or TBD] | [SOW/RFP/client approval] | Contractual / Proposed / TBD |
| Delivery Calendar | [Weeks, sprints, waves, blackout dates, or funding window] | [Source] | [Status] |
| Acceptance / Warranty Availability | [Window or TBD] | [MSA/SOW/source] | Covered / Gap / N/A |

Do not derive period of performance from estimated effort. Use source-stated
dates or mark them TBD.

---

## SOW Readiness Checklist

| Item | Source / Owner | Status | Notes |
|------|----------------|--------|-------|
| MSA or master contract reviewed for conflicting terms | [Source / owner] | Reviewed / Pending / N/A | [IP, quality, warranty, acceptance, or other conflicts] |
| Acceptance period and acceptance process identified | [Source / owner] | Known / TBD | [Number of business days, approver, evidence] |
| Warranty/support window identified | [Source / owner] | Known / TBD | [Support availability after delivery, if required] |
| Period of performance covers delivery plus required acceptance/warranty availability | [Source / owner] | Covered / Gap / TBD | [Adjustment needed, if any] |
| Non-negotiable milestones or funding dates reflected | [Source / owner] | Reflected / TBD / N/A | [Program/client milestone constraints] |
| External commercial review completed | [Business owner] | Complete / Pending / N/A | [Rates, pricing, payment terms handled outside AIS-spec] |

---

## Commercial Model

Insert the selected commercial-model stub here. If the model is unknown, include
a short "Commercial Model Decision Needed" subsection with the conflicting or
missing signals and carry it as a QC item.

---

## Team and Responsibilities

### AIS Team

| Role | Responsibility | Allocation | Weekly Hours | Phase / Weeks | Total Hours |
|------|----------------|------------|--------------|---------------|-------------|
| [Role] | [What they do] | [100% / 50% / 20% / 10% / Unknown] | [40 / 20 / 8 / 4 / Unknown] | [Phase/weeks or Unknown] | [Hours or Unknown] |

### Client Team

| Role | Responsibility | Availability |
|------|----------------|--------------|
| [Role] | [What AIS needs from them] | [Expected availability] |

### Green-Sheet Summary

| Role | Phase / Milestone | Weeks | Allocation | Weekly Hours | Total Hours | Source / Status |
|------|-------------------|-------|------------|--------------|-------------|-----------------|
| [Role] | [Phase/Milestone or Unknown] | [# or Unknown] | [100% / 50% / 20% / 10% / Unknown] | [40 / 20 / 8 / 4 / Unknown] | [Hours or Unknown] | [Source / assumption / Unknown] |
| **Total** | | | | | **[Hours or Unknown]** | |

Staffing allocation is separate from elapsed duration. Full-time equals 40
hours/week; percentage allocation converts to weekly hours. Use `Unknown` for
unsupported staffing hours or totals.

---

## Compliance Commitments

| Requirement / Clause | Source | Commitment / Response | Evidence or Owner | Status |
|----------------------|--------|-----------------------|-------------------|--------|
| [Compliance requirement] | [RFP/SOW section] | [What AIS commits to or what remains open] | [Evidence/owner] | Committed / Gap / N/A / Pending |

---

## Risks

| ID | Risk | Likelihood | Impact | Mitigation | Owner |
|----|------|------------|--------|------------|-------|
| R-001 | [Risk] | Medium | High | [Mitigation] | AIS / Client |

---

## Change Management

[Process for handling scope changes, additional requirements, or
reprioritization during the engagement.]

- Change requests require written documentation.
- AIS provides an impact assessment for effort, timeline, and external
  commercial review within [N] business days.
- Changes to spec scope require mutual agreement.
- Changes to contractual deliverables, period of performance, funding terms,
  external commercial terms, or compliance commitments require SOW amendment or
  signed change order.
- Delivery execution updates from new context route through
  `/ais.maintain.clarify`.

---

## Clarifying Questions

### QA - Resolved Assumptions

| # | Question | Resolution | Resolved Date |
|---|----------|------------|---------------|
| 1 | [Previously open question] | [How it was resolved] | [Date] |

### QC - Pending Client Items

| # | Question | What It Blocks | Target Date |
|---|----------|----------------|-------------|
| 1 | [Still-open question] | [Impact] | [When needed] |

---

## Acceptance and Completion

[Describe how deliverables are submitted, reviewed, accepted, or revised.
Include source-stated acceptance periods only; otherwise mark TBD. Completion
requires accepted deliverables, resolved phase-gate decisions, or mutually
approved change handling for remaining items.]

---

## Delivery Methodology

1. `/ais.setup.plan` reads this SOW as a T1 source after signature and creates
   delivery spec directories.
2. Each SOW deliverable maps to at least one delivery spec with a YYMM-NNN
   identifier.
3. Progress is tracked through delivery specs and reported via
   `/ais.report.status`.
4. New source material or approved changes route through `/ais.maintain.clarify`.
