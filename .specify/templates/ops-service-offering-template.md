# Ops Continuity Service Offering

Use this template when a proposal, account plan, or follow-on opportunity needs a tiered operations, support, advisory, and enhancements option set. This is guidance and reusable structure only. Do not include rates, prices, margins, or final commercial terms unless the user supplies approved values.

| Field | Value |
| --- | --- |
| **Client / Account** | [Client name] |
| **Solution / Platform** | [Supported solution, product, or workstream] |
| **Date** | [YYYY-MM-DD] |
| **Source Context** | [SOW, proposal, meeting, ticket history, or TBD] |
| **Recommended Tier** | Base / Standard / Premium / Decision needed |
| **Commercial Model Signal** | Managed capacity / Time and materials / FFP / Outcome-driven / Unknown |
| **Offshore Mode** | Yes / No / Partial / Unknown |
| **HubSpot Status** | Draft summary / Ready to paste / Needs account owner review |

---

## Source and Confidence Summary

| Signal | Source | Confidence | Notes / Gaps |
| --- | --- | --- | --- |
| Support scope | [Source] | High / Medium / Low | [Incidents, requests, advisory, enhancements, onboarding, platform ops] |
| Response posture | [Source] | High / Medium / Low | [Business hours, extended, priority, TBD] |
| Ticketing channel | [Source] | High / Medium / Low | [ServiceNow, Jira, Azure DevOps, GitHub, Teams, email, TBD] |
| Enhancement appetite | [Source] | High / Medium / Low | [Bug fixes only, governed enhancements, roadmap capacity, TBD] |
| Offshore eligibility | [Source] | High / Medium / Low | [Allowed, prohibited, partial, TBD] |
| Data/compliance constraints | [Source] | High / Medium / Low | [Restrictions that affect support handling] |

---

## Work Taxonomy

| Category | Included Examples | Intake Requirement | Boundary / Exit |
| --- | --- | --- | --- |
| Incident | [Production outage, degraded job, data issue] | [Priority, impact, environment, timestamp, logs] | Restore service; new capability is out of incident scope |
| Service request | [Access, config, routine operational task] | [Request type, approval, target date] | Repeated requests may become automation or backlog |
| Advisory question | [SME reachback, architecture guidance] | [Question, context, decision date] | Extended analysis becomes enhancement or new engagement |
| Enhancement request | [Feature change, report, workflow, model/prompt change] | [Outcome, users, acceptance, priority] | Material work becomes new spec, change order, or engagement |
| New engagement candidate | [Roadmap initiative, new platform, new compliance scope] | [Business outcome, sponsor, funding path] | Route to discovery/proposal/SOW |

---

## Tier Options

| Tier | Scope | Target Response Posture | Channels | Staffing Approach | Reporting |
| --- | --- | --- | --- | --- | --- |
| Base | [Limited support scope and intake] | [Business-hours acknowledgment / planned triage windows] | [Named queue plus scheduled checkpoint] | [Fractional owner with SME reachback] | [Monthly summary or checkpoint] |
| Standard | [Production support, requests, bug fixes, governed enhancements] | [Business-hours support with escalation path] | [Client ticketing queue plus agreed notification path] | [Core support pod plus SME escalation; offshore lane if permitted] | [Monthly service report and backlog review] |
| Premium | [Business-critical support, onboarding, proactive health, enhancement lane] | [Priority or extended response posture] | [Ticket queue, escalation path, incident bridge, governance cadence] | [Named lead, support pod, specialist bench, optional offshore execution lane] | [Weekly/monthly report plus QBR-style review] |

### Tier Boundary Notes

- **Incidents**: [What each tier does and does not include]
- **Service requests**: [Request types and approval path]
- **Advisory**: [Reachback cadence and limits]
- **Enhancements**: [Capacity, NTE, backlog, estimate, and change thresholds]
- **Monitoring / alerts**: [Signal baseline and alert ownership]
- **Exclusions**: [24x7, SLA penalties, client Tier 1, connector implementation, platform ownership, or other exclusions]

---

## Recommended Tier

**Recommendation**: [Base / Standard / Premium]

**Rationale**:

- [Source-backed reason 1]
- [Source-backed reason 2]
- [Known risk or constraint]

**Decision needed before SOW/change order**:

- [Support hours/timezone]
- [Ticketing system and queue]
- [Client service owner and escalation owner]
- [Enhancement capacity threshold]
- [Offshore eligibility]
- [Data/compliance constraints]

---

## Offshore Delivery Mode

| Mode | Applies? | Support Handling |
| --- | --- | --- |
| Yes | Yes / No / Unknown | [Offshore can support triage, fixes, enhancement development, test evidence, reporting prep] |
| No | Yes / No / Unknown | [Onshore-only handling for all scoped work] |
| Partial | Yes / No / Unknown | [Onshore client-facing/restricted work; offshore documented execution or sanitized analysis] |

State exactly what offshore staff can access: tickets, code, logs, non-production systems, production data, customer meetings, or sanitized artifacts.

---

## Automation and Efficiency Narrative

[Explain how this package uses signal baselines, runbooks, repeatable triage, automation candidates, and AI-assisted summarization/analysis where allowed. Avoid basing the story only on infrastructure counts, log source counts, or manual monitoring coverage.]

Automation candidates:

- [Repeated request or incident pattern]
- [Runbook or self-service opportunity]
- [Alert tuning or dashboard improvement]
- [Ticket summary, clustering, or reporting assist where policy permits]

---

## Scale Up / Scale Down Rules

| Trigger | Recommended Action |
| --- | --- |
| Ticket volume or incident severity exceeds tier assumptions for [period] | Review tier, capacity, response posture, and escalation path |
| Enhancement demand consumes material capacity | Move to enhancement lane, change order, new spec, or new engagement |
| Support demand drops below tier assumption | Scale down with notice or shift to advisory retainer |
| New system, user group, integration, compliance obligation, or data domain enters scope | New spec, change order, or new engagement |
| Repeated incidents share root cause | Create root-cause fix, automation, runbook, alert tuning, or backlog item |

---

## HubSpot-Ready Follow-On Summary

### Deal / Lead Description

```
AIS recommends a [Base/Standard/Premium] Ops Continuity Package for [client/solution] to provide [incident/request/advisory/enhancement] support after delivery. The package establishes a named intake path, support taxonomy, tiered response posture, enhancement backlog workflow, reporting cadence, and project-to-ops handoff checklist. Pricing and final commercial terms remain pending business review.
```

### Recommended Tier Rationale

```
Recommended tier: [Tier]. Rationale: [production criticality/change demand/support channel/offshore eligibility/onboarding volume]. This tier fits because [source-backed reasons]. Open decisions: [timezone, ticketing, client owner, enhancement threshold, offshore mode, compliance/data constraints].
```

### Next Step

```
Confirm authoritative ticketing channel, support hours/timezone, client escalation owner, offshore eligibility, enhancement capacity threshold, and reporting cadence. After confirmation, convert the package into an account-specific ops playbook and SOW/change-order language.
```

---

## Open Questions

| # | Question | What It Blocks | Owner |
| --- | --- | --- | --- |
| 1 | [Question] | [Tier, staffing, response posture, SOW language, or HubSpot summary] | AIS / Client |
