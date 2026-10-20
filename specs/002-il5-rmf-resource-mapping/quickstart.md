# Quickstart: Validate the IL5 RMF Mapping and Tactical Guide

<!-- markdownlint-disable MD013 -->

**Feature**: `002-il5-rmf-resource-mapping` | **Date**: 2026-08-25

This guide retains validation for the completed US1 mapping and defines US2 validation
for the planned `docs/il5-rmf-tactical-guide.md`. It does not implement or edit either
document.

## Prerequisites

- Checkout branch `002-il5-rmf-resource-mapping`.
- Use the MLZ commit stated in the document's Review Baseline.
- Obtain the current official CC SRG and DoDI 8510.01 PDFs.
- Access current Microsoft Learn pages and the target Azure Government tenant when
  validating dynamic initiative or availability claims.
- Install Node.js only if running `markdownlint-cli2` locally.
- Use commit `113fb08211bffe603b20c44668df6a756ae80821` as the US2 tactical source
  baseline unless the final guide records and justifies a later reviewed commit.

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
grep -R -n "hostGroups\|hostGroup\|virtualMachineSize" src/mlz.bicep src/modules --include='*.bicep'
```

**Expected outcome**:

- Policy requires `deployPolicy=true` and `policy='IL5'`, plus live ID verification.
- Defender changes from Free to Standard with customer-selected plans.
- Firewall IDPS and threat intelligence move from Alert to Deny after tuning.
- Retention is customer-derived, not a universal IL5 value.
- Log Analytics public access and complete Dedicated Host placement are identified as
  template gaps.
- All four NSG arrays are tied to customer-approved PPSM data flows.
- Each finding is classified as a parameter change, template change, external
  implementation, or deployment-time verification.

## 4. Verify Regional and Dynamic Claims

On the review date, check each mapped service in current IL5 PA audit scope and verify
initiative ID `f9a961fa-3241-4b20-adc4-bbf8ad9d7197` in Azure Government. For US Gov
Arizona, Texas, or Virginia, verify the Dedicated Host family, quota, and support for
every MLZ standalone VM. Confirm the document directs new deployments to US Gov Arizona,
Texas, or Virginia.

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

Inspect the `README.md` diff to confirm that the only changes are the correctly
formatted IL5 RMF mapping and tactical-guide navigation links, then open both links and
verify they resolve. Default local
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

## 9. Check Mapping Coverage

List the parameter changes, proposed template changes, and outside-MLZ actions in the
mapping. Check them against the matching sections in the tactical guide.

**Expected outcome**: Every mapped action is covered and the guide adds no unsupported
requirement. Related actions may share a section when the individual steps remain clear.

## 10. Sample Source Traces and Current/Proposed Language

Sample at least one parameter, proposed-template, and outside-MLZ section. Follow its
mapping and repository citations. For parameter changes, confirm the names, values,
dependencies, and input locations used in the steps.

Include targeted samples for:

- `deployDefender` executable default `true` versus stale false-default text.
- The `deployIdentity` and `deployActiveDirectoryDomainServices` multi-parameter path
  and all required AD DS inputs.
- Bastion host deployment versus separately enabled jumpbox VMs.

**Expected outcome**: Current statements match the reviewed source. Proposed statements
use future/proposal language. Discrepancies are reported as facts or validation checks,
not silently fixed, and no proposed behavior is presented as implemented.

## 11. Validate Files and Steps

For every parameter section, verify the parameter names, required values or decisions,
dependencies, and input locations. For each template limitation, verify its
customer actions and expected result.

```bash
rg -n "^param |module |publicNetworkAccessFor|hostGroups|properties\.host" src docs/deployment-guides
```

**Expected outcome**: Parameter paths are accurate. The Log Analytics and Dedicated
Host sections do not present missing template settings as available.
The AD DS section covers its required companion parameters and identity-tier dependency.

## 12. Validate Section Completeness

Inspect each section against [the document contract](contracts/document-contract.md).

**Expected outcome**:

- Every section provides executable steps and verification or evidence. Input
  locations and owners are identified where needed.
- Defaults and limitations needed for an action appear in the steps. No standalone
  current-state blocks, repeated change summaries, or module call-chain narration remain.
- Each required customer input names an owner and a concrete consumer: a parameter,
  service setting, test threshold, or evidence artifact. No undefined approval gate
  is presented as an Azure deployment action.
- Parameter sections identify the exact file that receives the deployment value when
  one exists.
- Template-limitation sections contain no internal engineering plans or repository
  issue links.
- Outside-MLZ sections identify the accountable owner and evidence to retain.

## 13. Check Values, Baselines, and Region Language

Search the tactical guide for numeric durations, PPSM rules, Defender plan selections,
contact addresses, authentication choices, recovery objectives, host selections, quota,
and authorization decisions. For each value, verify it is directly authoritative or is
recorded as a decision point with an owner, inputs, and validation evidence.

**Expected outcome**: No universal customer-specific or dynamically discovered value is
invented. NIST SP 800-53 Revision 5 and the mapping's DoD IL5 baseline remain consistent.
Wider-MAG guidance names US Gov Arizona, Texas, or Virginia and preserves the official
service and feature scope.

## 14. Validate Readability

Use `textstat` 0.7.13 with `en_US` for both documents. Report Flesch-Kincaid,
Gunning Fog, Coleman-Liau, Automated Readability Index, and SMOG grade estimates.

- Grade body paragraphs and list items in each document.
- Also grade the mapping with its descriptive table cells included: resources and
  current behavior, security purpose, required change, and term definitions.
- Exclude headings, navigation, the references section, `Files` paragraphs, technical
  metadata, control-code/source/owner columns, inline code, code blocks, and link URLs.
- Keep ordinary technical names and the original sentence punctuation. Strip checklist
  markers and repeated field labels.

**Expected outcome**: Flesch-Kincaid grade level is 11 or lower. Exact technical names,
values, paths, and evidence requirements remain intact. Report the other estimates,
including any that exceed the target.

## 15. Validate Markdown, Links, and the Documentation-Only Boundary

```bash
npx --yes markdownlint-cli2 docs/il5-rmf-resource-mapping.md docs/il5-rmf-tactical-guide.md
git diff --name-only 113fb08211bffe603b20c44668df6a756ae80821...HEAD -- src
```

Run the repository's link checker or equivalent repeatable link validation against both
documents and their README navigation. Open the mapping-to-guide and guide-to-mapping
links. Record authenticated or dynamic-link caveats without replacing authoritative
sources.

**Expected outcome**: Markdown and link checks report zero errors or warnings; all
navigation and cross-document links resolve; and the `git diff` command prints nothing.
No Bicep, generated ARM/JSON, parameter/example, UI-definition, or deployed-resource
change is part of US2. Tests are allowed when useful and must validate only this
documentation feature.

## US2 Success Criteria

- Every mapping action is covered and no unsupported requirement is introduced.
- 100% sampled claims trace to the mapping, reviewed source, and appropriate external
  authority.
- Parameter sections name exact parameters and files; template-limitation sections
  state required actions; outside-MLZ sections name owners and evidence.
- Zero invented customer-specific, AO-owned, or dynamically discovered values.
- Grade 11 or lower explanatory prose, zero Markdown/link findings, and zero `src/`,
  generated, parameter, or UI changes.
