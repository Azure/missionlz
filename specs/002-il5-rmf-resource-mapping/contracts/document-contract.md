# Contract: IL5 RMF Resource Mapping Document

**Feature**: `002-il5-rmf-resource-mapping` | **Date**: 2026-08-24

This contract defines the future `docs/il5-rmf-resource-mapping.md`. It does not contain
the final mapping content.

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
cloud innovations and to migrate existing US DoD region deployments for additional
services. US DoD Central and East remain exclusive-use DoD regions; the recommendation
does not imply a lifecycle status for them.

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
  Virginia. Do not recommend US DoD Central or East for new deployments.
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
