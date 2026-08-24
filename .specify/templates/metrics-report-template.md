# Metrics Report

**Generated**: [YYYY-MM-DD HH:MM UTC]
**Project**: [Project name]
**Reporting Period**: [YYYY-MM-DD to YYYY-MM-DD]
**Repository**: [owner/name or local path]

---

## Executive Metrics Summary

[Two to four sentences summarizing delivery outcome health, measured values,
estimates, unavailable metrics, and the most important instrumentation gap.]

| Status | Count |
|--------|-------|
| Measured | [N] |
| Estimated | [N] |
| Unavailable | [N] |
| Not Applicable | [N] |
| High Confidence | [N] |

---

## Board-Level Outcome View

| Outcome | Metric | Status | Value | Confidence | Interpretation |
|---------|--------|--------|-------|------------|----------------|
| Speed | Cycle Time | [measured/estimated/unavailable/not_applicable] | [Value] | [high/medium/low/unavailable] | [Short interpretation] |
| Predictability | Delivery Predictability | [Status] | [Value] | [Confidence] | [Short interpretation] |
| Quality | PR Acceptance on First Review | [Status] | [Value] | [Confidence] | [Short interpretation] |
| Quality | Defect Escape Rate | [Status] | [Value] | [Confidence] | [Short interpretation] |
| Economics | Cost per Delivered Feature | [Status] | [Value] | [Confidence] | [Short interpretation] |

---

## Operating Metrics View

| Metric | Category | Status | Value | Sample Size | Formula |
|--------|----------|--------|-------|-------------|---------|
| Cycle Time | delivery_performance | [Status] | [Value] | [N] | [Formula] |
| Delivery Predictability | delivery_predictability | [Status] | [Value] | [N] | [Formula] |
| PR Acceptance Rate on First Review | code_quality | [Status] | [Value] | [N] | [Formula] |
| Defect Escape Rate | code_quality | [Status] | [Value] | [N] | [Formula] |
| Rework Rate | code_quality | [Status] | [Value] | [N] | [Formula] |
| Spec Adherence Rate | methodology_adoption | [Status] | [Value] | [N] | [Formula] |
| Traceability Coverage | traceability | [Status] | [Value] | [N] | [Formula] |
| Cost per Delivered Feature | engineering_economics | [Status] | [Value] | [N] | [Formula] |

---

## Adoption and Governance Indicators

| Indicator | Value | Evidence | Notes |
|-----------|-------|----------|-------|
| Specs with required lifecycle artifacts | [Value] | [Evidence] | [Notes] |
| Specs with branch or PR linkage | [Value] | [Evidence] | [Notes] |
| Specs with task/story traceability | [Value] | [Evidence] | [Notes] |
| Specs with source authority | [Value] | [Evidence] | [Notes] |

---

## Per-Metric Calculations

### [Metric Name]

| Field | Value |
|-------|-------|
| Metric ID | `[metric_id]` |
| Category | `[category]` |
| Scope | `[scope_level]` |
| Status | `[viability.status]` |
| Confidence | `[viability.confidence]` |
| Value | `[value.display]` |
| Formula | `[formula.expression]` |
| Inputs | `[formula.inputs]` |
| Evidence Sources | `[sources]` |
| Data Gaps | `[gaps]` |
| Recommended Instrumentation | `[instrumentation]` |

**Rationale**: [Why this status and confidence were assigned.]

**Limitations**: [Known limitations or "None".]

---

## Evidence Sources and Limitations

| Source | Coverage | Fields Used | Limitations |
|--------|----------|-------------|-------------|
| Repo state | [Coverage] | [Fields] | [Limitations] |
| Spec frontmatter | [Coverage] | [Fields] | [Limitations] |
| Git history | [Coverage] | [Fields] | [Limitations] |
| GitHub PRs | [Coverage] | [Fields] | [Limitations] |
| GitHub reviews | [Coverage] | [Fields] | [Limitations] |
| GitHub issues/labels | [Coverage] | [Fields] | [Limitations] |
| Previous metrics reports | [Coverage] | [Fields] | [Limitations] |
| Cost or hours inputs | [Coverage] | [Fields] | [Limitations] |

---

## Data Gaps

| Gap | Severity | Affected Metrics | Required Signal | Current Fallback |
|-----|----------|------------------|-----------------|------------------|
| [Gap] | [blocks_metric/lowers_confidence/limits_trend/optional_context] | [Metrics] | [Signal] | [Fallback] |

---

## Instrumentation Backlog

| Priority | Target | Action | Expected Effect |
|----------|--------|--------|-----------------|
| P1 | PR template | Require linked spec IDs and validation evidence. | Improves traceability and spec adherence confidence. |
| P1 | GitHub reviews | Query PR review events, churn, and landing time for spec-linked PRs. | Enables PR first-review acceptance and PR flow metrics. |
| P1 | Metrics collector | Treat merge to `main` as the default deployment timestamp. | Improves cycle time confidence. |
| P2 | GitHub labels | Add follow-on defect and severity labels. | Improves defect escape rate confidence. |
| P3 | Cost tracking | Add optional cost, hours, rate, or capacity inputs. | Enables cost per delivered feature. |

---

## Trend Notes

[Compare to previous metrics reports when available. If no previous metrics
report exists, state that this report establishes the baseline.]
