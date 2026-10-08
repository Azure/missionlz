# Contract: IL5 RMF Resource Mapping Document

<!-- markdownlint-disable MD013 -->

**Feature**: `002-il5-rmf-resource-mapping` | **Date**: 2026-08-25

This contract defines the future `docs/il5-rmf-resource-mapping.md`. It does not contain
the final mapping content.

The US1 mapping is now complete. Its contract remains below as historical design and
as the source of required changes for the US2 guide.

## Required Section Order

1. Title and document status.
2. Audience, purpose, and reviewed baseline.
3. Scope and exclusions, explicitly excluding `src/add-ons/`.
4. Terminology and state definitions.
5. Shared-responsibility model.
6. Prominent authorization and compliance limitation.
7. Consolidated IL5 considerations.
8. Core capability mapping.
9. Validation, maintenance, and re-review triggers.
10. Authoritative references.

The authorization limitation appears before or directly adjacent to the first mapping
table.

The consolidated IL5 considerations give readers the deployment-level decisions before
the resource details. They include the reason that single VMs in Microsoft Azure
Government (MAG) regions US Gov Arizona, Texas, and Virginia require Azure Dedicated
Host: those regions serve DoD customers and approved non-DoD State, Local, Tribal, and
Federal Civilian (FedCiv) government customers. Wider MAG is the recommended target.
The recommendation follows Microsoft guidance to use US Gov regions for the latest
cloud innovations and additional services.

## Mapping Row Contract

The document may combine related fields to keep the table readable. Every row must
contain the following information:

| Field | Plain-language content rule |
| --- | --- |
| Capability | A short name that a non-specialist can understand. |
| State | Exactly `Default`, `Optional`, or `Absent`. |
| Resources and current behavior | Created resources, source links, important defaults, and absence evidence when the state is `Absent`. |
| Security purpose | What the capability does in plain language. |
| RMF | Representative NIST SP 800-53 Revision 5 control IDs. |
| IL5 change | The exact setting, template change, outside action, deployment check, or statement that no MLZ change is needed. |
| Owner and check | Who acts and the shortest useful description of how to check the result. |

The document defines necessary abbreviations once and avoids repeating the authorization
caveat or the full IL5 action list after the matrix.

## Controlled Vocabulary

**Capability State**: `Default`, `Optional`, `Absent`.

**Responsibility**: `MLZ repository`, `Mission/customer`, `Microsoft/inherited`,
`Shared`, `External/organizational`.

**Required Action**: `No MLZ change`, `Parameter change`, `Template change`,
`External implementation`, `Deployment-time verification`.

## Required Cross-Cutting Findings

- `deployPolicy=true` and `policy='IL5'`, with live initiative-ID verification.
- Defender is a Default capability; for the IL5 deployment profile, select Standard and
  the workload protection plans required by the mission architecture.
- Firewall Premium with IDPS and threat intelligence Deny/prevention modes.
- Mission-derived audit and flow-log retention.
- Disabled Log Analytics public ingestion and query with validated private access.
- PPSM-derived NSG rules for hub, operations, shared-services, and identity tiers.
- Dedicated Host placement for MLZ single VMs in wider MAG: US Gov Arizona, Texas, and
  Virginia.
- Closed-list capabilities absent from core MLZ: Dedicated Host placement, backup and
  recovery, identity governance, and operational procedures that infrastructure cannot
  implement.

## Citation Contract

1. Bicep defaults, conditions, resources, and absences cite reviewed source.
2. Control definitions and RMF terminology cite NIST with revision/date and section
  where accessible.
3. IL5 applicability, tailoring, and authorization context cite DoD/DISA/CNSS.
4. Azure behavior, offering, PA scope, and settings cite current Microsoft guidance.
5. Azure Policy cannot be the sole source for complete control implementation.
6. Dynamic initiative, audit-scope, region, and SKU claims include a review date.

## Authorization Limitation Contract

The limitation states that MLZ is one component in an authorization boundary; deployment
does not confer IL5 compliance or authorization, satisfy every RMF requirement, or
replace assessment; an Azure PA applies only to its scoped cloud service offering;
customer, inherited, shared, repository, and external responsibilities remain; and Azure
Policy and Defender output are evidence inputs rather than authorization decisions.

## Prohibited Claims

The document fails review if it states or implies:

- "MLZ is IL5 compliant."
- "Deploying MLZ grants an ATO or PA."
- "This resource satisfies or implements the control."
- "A green Azure Policy result proves overall compliance."
- One universal retention period, PPSM rule set, Defender plan set, or VM SKU applies to
  every IL5 mission.

## Release Gates

- Every reachable created core resource appears exactly once; no add-on appears.
- Every Decision 4 finding in `research.md` maps to a row or cross-cutting section and is
  classified as a parameter change, template change, external implementation, or
  deployment-time verification.
- Every row satisfies the mapping row contract.
- A structured inspection reaches unambiguous sampled state and required-action
  conclusions; independent reviewer validation is a later maturity step.
- A timed structured inspection answers the defined lookup questions within three
  minutes using the document alone.
- Sampled claims resolve to repository and authoritative external sources.
- The authorization limitation passes this contract.
- Markdown and link validation complete with zero errors or warnings.

---

## Contract: IL5 RMF Tactical Guide

This distinct contract defines the planned `docs/il5-rmf-tactical-guide.md` for
US2/[#1303](https://github.com/Azure/missionlz/issues/1303). The guide converts the
completed mapping's actions into practical steps. It does not implement parameters,
templates, deployment artifacts, UI definitions, or Azure resources.

### Tactical Guide Required Section Order

1. Title and prominent documentation-only boundary.
2. Audience, purpose, scope, and exclusions.
3. How to use the guide and the three action categories.
4. Current-versus-proposed language and shared-responsibility rules.
5. Predeployment decisions and checks.
6. Existing parameter-change steps.
7. Planned vNext features with links to their feature requests.
8. Outside-MLZ steps.
9. Maintenance triggers and authoritative references.

The no-infrastructure-change boundary appears before any procedure.

### Common Section Pattern

Each change section uses this short pattern:

| Part | Content rule |
| --- | --- |
| Change | What must change and why. |
| Files or owner | Exact files for MLZ work, or the responsible party for outside work. |
| Current state | What MLZ does at the reviewed commit. |
| Steps | Ordered checklist steps detailed enough to follow. |
| Verify | What to check and what evidence to retain. |

Within those five parts, parameter sections name the exact parameter, default, required
value or decision, declaration and consumer files, and deployment input file when one
exists. Planned vNext sections name the change, feature request, current limitation,
customer action, and expected result. Engineering files, implementation steps,
compatibility decisions, build instructions, and code tests belong in the feature
request, not this customer-facing guide. Outside-MLZ sections name the owner, steps,
expected result, and evidence. Related work may share a section when that makes the
instructions easier to follow.

The Log Analytics section links to #1304. The Dedicated Host section links to #1305.
Neither section may imply implementation or repeat its issue's engineering plan. The
guide does not prescribe one universal product, retention period, PPSM rule set,
authentication method, recovery objective, or AO decision.

### Required Cross-Cutting Tactical Findings

The guide must state or require validation of these facts; it must not fix them:

- `deployDefender` executes with default `true`, while its parameter description and
  command-line guide contain stale false-default text; the guide uses executable source
  as current behavior and flags the discrepancy.
- AD DS requires the identity tier plus the AD DS flag and companion domain,
  credential, safe-mode, image, size, network, and downstream module path; stale AD DS
  guide defaults or incomplete inputs are not silently normalized.
- Bastion creates a Bastion host, subnet/NSG path, public IP, and diagnostics when
  enabled; it does not enable the separately controlled Linux or Windows jumpboxes.
- The built-in Firewall collection currently contains two rules named
  `Allow-KV-TCP`; replacement and effective-rule validation must account for the
  duplicate without changing it in this feature.
- Wider-MAG guidance names US Gov Arizona, Texas, and Virginia and preserves Microsoft's
  official service and feature availability scope.
- All RMF relationships use NIST SP 800-53 Revision 5 and the DoD IL5 baseline retained
  from the mapping.

### Source and Language Contract

Repository source establishes current MLZ behavior. The mapping establishes the changes
that the guide must cover. NIST establishes RMF terminology and Revision 5 controls;
DoD/DISA/CNSS establishes IL5 and authorization context; Microsoft establishes Azure
behavior and wider-MAG guidance. Proposed behavior must use future or proposal language
and must never be described as deployed, available, or current.

Explanatory prose targets Flesch-Kincaid grade 11 or lower. Sentences use direct verbs,
define abbreviations, and avoid unnecessary compliance jargon.

### Tactical Guide Release Gates

- Every parameter, template, and outside-MLZ action in the mapping is covered; no
  unsupported requirement is added.
- Every section follows the common pattern.
- The Defender, AD DS, Bastion, and duplicate `Allow-KV-TCP` discrepancies are stated
  or validated as current facts, not repaired or silently corrected.
- Sampled current claims trace to the reviewed source and sampled external claims trace
  to the appropriate authoritative source.
- No mission-specific, AO-owned, or dynamically discovered value is invented.
- Wider-MAG language names US Gov Arizona, Texas, and Virginia, and NIST SP 800-53
  Revision 5 is used consistently.
- Executable steps use checklist syntax; explanatory prose scores at grade 11 or lower.
- Markdown and link validation report zero errors or warnings.
- The implementation diff changes only planned documentation, navigation, planning
  artifacts, and any useful tests; infrastructure and deployment artifacts remain
  unchanged.
