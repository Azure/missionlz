# Contract: IL5 RMF Resource Mapping Document

<!-- markdownlint-disable MD013 -->

**Feature**: `002-il5-rmf-resource-mapping` | **Date**: 2026-08-25

This contract defines the future `docs/il5-rmf-resource-mapping.md`. It does not contain
the final mapping content.

The US1 mapping is now complete. Its contract remains below as historical design and
as the source of required changes for the US2 guide.

## Required Section Order

1. Title and purpose.
2. Dated posture and source baseline.
3. Scope and exclusions, explicitly excluding `src/add-ons/`.
4. Terminology and state definitions.
5. Shared-responsibility model.
6. Prominent authorization and compliance limitation.
7. Consolidated IL5 considerations.
8. Core capability mapping.
9. Authoritative references.

The authorization limitation appears before or directly adjacent to the first mapping
table.

The consolidated IL5 considerations state requirements, not implementation steps.
DoD requires IL5 compute isolation from non-DoD workloads in Microsoft Azure Government
(MAG) regions US Gov Arizona, Texas, and Virginia. Those regions serve DoD customers and approved non-DoD State, Local,
Tribal, and Federal Civilian (FedCiv) government customers. Wider MAG is the recommended
target. The recommendation follows Microsoft guidance to use US Gov regions for the
latest cloud innovations and additional services.

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
| Required change | A concise required outcome classified as a parameter change, template change, outside-MLZ work, or no MLZ change. |
| Owner | The responsible party, without verification instructions. |

The mapping contains posture facts, representative controls, required outcomes, owners,
and sources. Implementation steps, verification, and evidence retention belong only in
the tactical guide. Review history, access limitations, internal findings, and resource
tallies do not belong in customer-facing prose. Abbreviations are defined once.

## Controlled Vocabulary

**Capability State**: `Default`, `Optional`, `Absent`.

**Responsibility**: `MLZ repository`, `Customer`, `Microsoft/inherited`,
`Shared`, `External/organizational`.

**Required Action**: `No MLZ change`, `Parameter change`, `Template change`,
`External implementation`, `Deployment-time verification`.

## Required Cross-Cutting Findings

- IL5 policy enablement, with exact parameter values and initiative verification in
  the tactical guide.
- Defender is a Default capability; for the IL5 deployment profile, select Standard and
  the workload protection plans required by the customer architecture.
- Firewall Premium with IDPS and threat intelligence Deny/prevention modes.
- Customer-derived audit and flow-log retention.
- Disabled Log Analytics public ingestion and query with validated private access.
- PPSM-derived NSG rules for hub, operations, shared-services, and identity tiers.
- Azure Dedicated Host placement for every persistent and temporary MLZ standalone VM
  in wider MAG: US Gov Arizona, Texas, and Virginia.
- Closed-list capabilities absent from core MLZ: complete IL5 VM isolation across every
  VM, backup and recovery, identity governance, and operational procedures that
  infrastructure cannot implement.

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
  every IL5 customer.

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

1. Title and purpose.
2. Purpose, scope, and exclusions.
3. How to use the guide and the three action categories.
4. Key terms.
5. Predeployment decisions and checks.
6. Existing parameter-change steps.
7. Current template limitations.
8. Outside-MLZ steps.
9. Authoritative references.

The mapping owns posture and control relationships; the guide owns implementation and
verification. Put defaults and limitations needed for a procedure directly in its steps.
Do not add standalone current-state descriptions, repeated change summaries, module
call-chain narration, or internal review history.
Do not use undefined organizational approvals as deployment steps. For a required
customer input, name its owner, fields or units, and the parameter, service setting,
test, or evidence artifact that consumes it. Non-Azure authorization work must name
the document or record produced, not imply an Azure approval operation.

### Common Section Pattern

Each change section uses this short pattern:

| Part | Content rule |
| --- | --- |
| Input or owner | Where to supply MLZ values, or the responsible party for outside work. Shared input instructions may appear once. |
| Steps | Ordered checklist steps detailed enough to follow. |
| Verify | What to check and what evidence to retain. |

Parameter steps name the exact parameter, required value or decision, and where to
supply it. Include a starting default only when needed to explain the change. Link
files the customer must edit or review, not module call chains. Template-limitation
sections state the required customer actions and verification.
Engineering files, implementation steps,
compatibility decisions, build instructions, and code tests belong in the feature
request, not this customer-facing guide. Outside-MLZ sections name the owner, steps,
verification of the intended result, and evidence. Related work may share a section when that makes the
instructions easier to follow.

Do not link to repository issues in the guide. The Log Analytics and Dedicated Host
sections must not imply that missing template settings are available. The
guide does not prescribe one universal product, retention period, PPSM rule set,
authentication method, recovery objective, or AO decision.

### Required Cross-Cutting Tactical Findings

The guide must make these actions explicit; it must not change infrastructure:

- Confirm `deployDefender=true` and set the required paid tier, plans, and contact.
- Set the identity and AD DS flags together and supply the domain, credential,
  safe-mode, image, size, and network inputs.
- Set the Bastion flag and subnet, verify its deployed resources, and select Linux or
  Windows management VMs separately.
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

Use customer when referring to the organization deploying or using MLZ. Preserve
Mission Landing Zone as the product name.

Use clear language at an 11th-grade level, with technical terms only where the task
requires them. Use direct verbs, define abbreviations, and avoid invented jargon.
Explanatory prose targets Flesch-Kincaid grade 11 or lower. Check the standard graders
and text scopes in [readability validation](../quickstart.md#14-validate-readability).

### Tactical Guide Release Gates

- Every parameter, template, and outside-MLZ action in the mapping is covered; no
  unsupported requirement is added.
- Every section provides executable steps and verification. Identify the input
  location or owner without repeating shared instructions or posture descriptions.
- Defender, AD DS, and Bastion behavior is accurate and
  actionable without internal review narration or unrelated source fixes.
- Sampled current claims trace to the reviewed source and sampled external claims trace
  to the appropriate authoritative source.
- No customer-specific, AO-owned, or dynamically discovered value is invented.
- Wider-MAG language names US Gov Arizona, Texas, and Virginia, and NIST SP 800-53
  Revision 5 is used consistently.
- Executable steps use checklist syntax; explanatory prose scores at grade 11 or lower.
- Markdown and link validation report zero errors or warnings.
- The implementation diff changes only planned documentation, navigation, planning
  artifacts, and any useful tests; infrastructure and deployment artifacts remain
  unchanged.
