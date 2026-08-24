# Statement of Work - Microsoft End Customer Investment Funds (ECIF)

> Core scope template for Microsoft ECIF Supplier Agreement-style work.
> Do not generate Microsoft legal boilerplate or standard agreement terms.
>
> **AIS-only authoring artifact**: Internal classification evidence, source
> columns, delivery spec mappings, readiness states, and delivery commands
> support AIS planning. Do not copy them into client-deliverable prose. Apply
> `Skills/ais-sow-docx/references/writing-guidance.md` to all narrative that
> will appear in the client DOCX.

| Field | Value |
|-------|-------|
| **Customer** | [Customer organization] |
| **Microsoft Agreement / Request** | [CAS / REQ / agreement ID / TBD] |
| **Supplier** | Applied Information Sciences / [Legal entity if source-stated] |
| **AIS Contact** | [Name, title] |
| **Microsoft Contact** | [Name, title / TBD] |
| **Customer Contact** | [Name, title / TBD] |
| **Engagement Funding** | Microsoft-funded / Microsoft-program-funded / Unknown |
| **Period of Performance** | [Start date] through [End date] - Contractual / Proposed / TBD |
| **Commercial Review** | Approved / Pending / N/A |
| **Classification Evidence** | [Files/sections proving ECIF structure] |

---

## Customer Information and Description of Services

[Describe the customer context, business objectives, and the services AIS will
perform. Keep the language delivery-focused and tied to the customer outcomes
or Microsoft-funded program objective.]

### Services Summary

| Service Area | Description | Customer Outcome | Source |
|--------------|-------------|------------------|--------|
| [Service area] | [Services AIS will perform] | [Outcome supported] | [Source file/section] |

### Delivery Spec Mapping

| Spec | Purpose | SOW Service / Milestone | Acceptance Evidence |
|------|---------|-------------------------|---------------------|
| [Spec name] | [What this spec delivers] | [Milestone/service mapping] | [Artifact or proof] |

---

## Performance and Milestone Schedule

Use ECIF milestone structure when source material requires Microsoft
milestone acceptance and payment support. Amount and hours values are always
withheld from generated SOW artifacts and use `TBD - Commercial Review`.

| Milestone | Brief Description of Services | Amount | Hours | Due On or Before | Proof of Execution / Acceptance Artifact |
|-----------|-------------------------------|--------|-------|------------------|------------------------------------------|
| M1 - [Name] | [Services completed for this milestone] | TBD - Commercial Review | TBD - Commercial Review | [Date or TBD] | [Customer acceptance, deliverable, report, or evidence] |
| M2 - [Name] | [Services completed for this milestone] | TBD - Commercial Review | TBD - Commercial Review | [Date or TBD] | [Evidence] |

### Milestone Detail

#### M1 - [Milestone Name]

[One paragraph describing the milestone scope and expected result.]

| Element | Description |
|---------|-------------|
| Included Services | [Specific services AIS will perform] |
| Deliverables | [Artifacts, workshops, deployed components, reports, or handoff items] |
| Acceptance Evidence | [Customer acceptance or proof-of-execution artifact] |
| Customer Dependencies | [Access, reviewers, data, environment, decisions] |
| Exclusions | [What is not included in this milestone] |

---

## Proof of Execution and Payment Support

| Requirement | Owner | Evidence / Artifact | Status |
|-------------|-------|---------------------|--------|
| Customer acceptance for each completed milestone | [Customer / AIS / Microsoft] | [Artifact] | Known / TBD |
| Proof of execution package | [AIS owner] | [Summary, screenshots, deliverables, signoff, or other source-stated proof] | Known / TBD |
| Invoice milestone mapping | [Business owner] | [External commercial artifact] | Approved / Pending / N/A |

Payment terms, invoice timing, Microsoft policies, and agreement clauses belong
in the official Microsoft agreement workflow. Reference approved external
commercial artifacts only; do not invent payment language.

---

## Responsibilities and Assumptions

### AIS Responsibilities

- [Actionable AIS responsibility tied to milestone delivery]
- [Actionable AIS responsibility tied to proof of execution]

### Customer Responsibilities

- [Access, stakeholder, approval, data, or environment dependency]
- [Reviewer or acceptance responsibility with date or milestone]

### Microsoft / Program Dependencies

- [Funding window, approval, evidence, or program dependency]
- [Unknown program dependency or `N/A`]

---

## Out of Scope

- [Explicitly excluded item]
- [Excluded legal/commercial/legal-boilerplate work, if applicable]

---

## SOW Readiness and Open Items

| Item | Source / Owner | Status | Notes |
|------|----------------|--------|-------|
| ECIF agreement family confirmed | [Source] | Confirmed / TBD | [Evidence] |
| Milestone amount/hour review | [External commercial owner] | Pending / N/A | Values remain outside AIS-spec artifacts |
| Proof-of-execution requirements known | [Source / Microsoft owner] | Known / TBD | [Notes] |
| Customer acceptance process known | [Source / customer owner] | Known / TBD | [Notes] |
| Period of performance and milestone dates source-stated | [Source] | Known / TBD | [Notes] |

---

## Change Management

[Describe how scope, milestones, acceptance evidence, or source-stated dates
will be adjusted. Commercial or agreement changes require the appropriate
Microsoft/customer approval path and are not silently changed in delivery
artifacts.]

---

## Delivery Methodology

1. `/ais.setup.plan` reads this SOW as a T1 source after signature and creates
   delivery spec directories.
2. Each milestone and service area maps to at least one delivery spec.
3. Progress is tracked through delivery specs and reported via
   `/ais.report.status`.
4. New source material or approved changes route through `/ais.maintain.clarify`.
