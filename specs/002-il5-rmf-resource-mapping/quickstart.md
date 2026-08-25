# Quickstart: Validate the IL5 RMF Resource Mapping

**Feature**: `002-il5-rmf-resource-mapping` | **Date**: 2026-08-24

This guide defines end-to-end validation for the documentation implementation. It does
not implement the future `docs/il5-rmf-resource-mapping.md`.

## Prerequisites

- Checkout branch `002-il5-rmf-resource-mapping`.
- Use the MLZ commit stated in the document's Review Baseline.
- Obtain the current official CC SRG and DoDI 8510.01 PDFs.
- Access current Microsoft Learn pages and the target Azure Government tenant when
  validating dynamic initiative or availability claims.
- Install Node.js only if running `markdownlint-cli2` locally.

## 1. Verify the Scope Boundary

From the repository root:

```bash
grep -n "^module " src/mlz.bicep
grep -R -n "^module \|^resource " src/modules --include='*.bicep'
```

Build a recursive checklist from `src/mlz.bicep`. For each reachable module, record
every created resource and reconcile it to exactly one mapping row.

**Expected outcome**: Every reachable created resource appears once; unreferenced and
existing resources are not treated as created inventory; no `src/add-ons/` path appears.

## 2. Verify Capability States

Select one row labeled Default, Optional, and Absent. Follow its source and apply
[the document contract](contracts/document-contract.md).

**Expected outcome**: A structured inspection produces one unambiguous state; Optional
rows name the enabling parameter; Absent rows cite absence evidence; insufficient
defaults retain their deployment state and identify IL5 profile changes separately.

## 3. Verify Required Settings and Gaps

```bash
grep -n "deployPolicy\|param policy\|defenderSkuTier\|deployDefenderPlans" src/mlz.bicep
grep -n "firewallIntrusionDetectionMode\|firewallThreatIntelMode" src/mlz.bicep
grep -n "RetentionInDays\|NetworkSecurityGroupRules" src/mlz.bicep
grep -n "publicNetworkAccessFor" src/modules/log-analytics-workspace.bicep
grep -R -n "hostGroups\|hostGroup" src/mlz.bicep src/modules --include='*.bicep'
```

**Expected outcome**:

- Policy requires `deployPolicy=true` and `policy='IL5'`, plus live ID verification.
- Defender changes from Free to Standard with mission-selected plans.
- Firewall IDPS and threat intelligence move from Alert to Deny after tuning.
- Retention is mission-derived, not a universal IL5 value.
- Log Analytics public access and Dedicated Host are identified as template gaps.
- All four NSG arrays are tied to mission-approved PPSM data flows.
- Each finding is classified as a parameter change, template change, external
  implementation, or deployment-time verification.

## 4. Verify Regional and Dynamic Claims

On the review date, check each mapped service in current IL5 PA audit scope and verify
initiative ID `f9a961fa-3241-4b20-adc4-bbf8ad9d7197` in Azure Government. For US Gov
Arizona, Texas, or Virginia, verify Dedicated Host availability, quota, and support.
Confirm the document recommends wider MAG and does not direct new deployments to US DoD
Central or East.

**Expected outcome**: No SKU, initiative, service-scope, or regional claim is presented
as timeless.

## 5. Verify RMF Relationships and Sources

Sample networking, monitoring, encryption, policy/Defender, and compute capabilities.
Confirm that contribution precedes control IDs, controls match the declared NIST
release, limitations are explicit, and every sampled citation resolves.

**Expected outcome**: No Azure Policy list is copied as complete coverage; repository
claims resolve to the reviewed commit; external claims resolve to versioned or dated
DoD, NIST, or Microsoft sources.

## 6. Verify Authorization Language

```bash
grep -n -i "compliant\|compliance\|authorize\|authorization\|satisfy\|implement" \
  docs/il5-rmf-resource-mapping.md
```

**Expected outcome**: The full limitation appears before or adjacent to the first table;
no sentence says deployment grants compliance, a PA, or an ATO; control language uses
contribution/evidence framing; Policy and Defender are partial evidence inputs.

## 7. Run the Timed Structured Inspection

Using only the completed document, locate and record answers to these questions:

1. Is Defender deployed by default, and what changes for an IL5 profile?
2. Is the IL5 policy initiative enabled by default?
3. Does Log Analytics require a parameter change or a template change?
4. What compute-isolation action applies in US Gov regions?

**Expected outcome**: The capability state, RMF relationship, action type, and required
action for each question are discoverable within three minutes. Independent-reviewer
validation is deferred until the documentation review process matures.

## 8. Validate Markdown and Navigation

```bash
npx --yes markdownlint-cli2 docs/il5-rmf-resource-mapping.md
```

Inspect the `README.md` diff to confirm that the only change is one correctly formatted
navigation link, then open the link and verify it resolves. Default local
`markdownlint-cli2` settings are not repository-equivalent for the pre-existing README,
so do not reformat unrelated README content. The pull request must pass the validation
workflows currently established on `main`. Do not describe pending coverage-ratchet
work as existing repository behavior.

**Expected outcome**: Zero Markdown errors or warnings, valid navigation, and sampled
external links resolve or carry an explicit access caveat.

## Success Criteria

- 100% reachable core-resource reconciliation and 0 add-on resources.
- 100% mapping rows satisfy the document contract.
- Structured inspection produces unambiguous sampled states and required actions.
- Timed lookup questions are answered within three minutes.
- Sampled claims are traceable to authoritative evidence.
- Authorization caveat is prominent and prohibited claims are absent.
- Markdown validation passes with zero errors and warnings.
