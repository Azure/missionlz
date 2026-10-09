# Feature Specification: IL5 RMF Resource Mapping Documentation

**Feature Branch**: `002-il5-rmf-resource-mapping`

**Feature Issue**: [#1301](https://github.com/Azure/missionlz/issues/1301) — Document MLZ relationships to IL5 RMF

**User Story Issues**:

- [#1302](https://github.com/Azure/missionlz/issues/1302) — Review MLZ resource-to-IL5 RMF mapping (native sub-issue of #1301)
- [#1303](https://github.com/Azure/missionlz/issues/1303) — Document tactical changes required for an IL5 MLZ deployment (native sub-issue of #1301)

**Created**: 2026-08-24

**Status**: Draft

**Input**: User description: "Create a mapping document for core Mission Landing Zone resources and
DoD IL5 RMF relationships, plus a second tactical document that reconciles every required parameter,
template, and outside-MLZ action from the mapping into ordered, evidence-based procedures. Exclude
add-ons, do not implement infrastructure changes, and do not claim deployment confers compliance or
authorization."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Evaluate MLZ Support for an IL5 Authorization Package (Priority: P1)

**Maps to issue**: [#1302](https://github.com/Azure/missionlz/issues/1302)

A mission owner or assessor needs one contributor-maintained reference that inventories the core
Mission Landing Zone capabilities, states whether each capability is deployed by default, available
only by explicit configuration, or absent from the core template, and relates each capability's
security contribution to representative DoD IL5 RMF controls. The reference also identifies the
specific MLZ settings or core-template changes needed when the current behavior is insufficient for
the documented IL5 posture. This allows readers to evaluate MLZ as one part of an authorization
package without mistaking deployment for compliance or authorization.

**Why this priority**: This mapping is the foundation for the approved Feature and for the tactical
guidance in User Story 2. A partial inventory without control relationships, capability state, or
required changes would not let mission owners and assessors identify evidence and gaps.

**Independent Test**: A reviewer can use only the new document and its cited sources to select any
in-scope core capability, determine its current MLZ state, understand its security contribution, find
representative RMF relationships, and identify any required setting or template action. The reviewer
also sees an explicit warning that MLZ deployment alone does not establish compliance or authorization.

**Acceptance Scenarios**:

1. **Given** a reader evaluating the core MLZ deployment, **When** the reader opens the mapping,
   **Then** every in-scope core capability is listed once with an unambiguous state of default,
   optional, or absent.
2. **Given** a listed core capability, **When** the reader reviews its row, **Then** the row explains
   the capability's security contribution and identifies representative RMF control families and
   controls supported by that contribution.
3. **Given** a capability whose current MLZ behavior is insufficient for the documented IL5 posture,
   **When** the reader reviews its row, **Then** the row identifies the exact existing setting and
   required value or the specific core-template gap and required change.
4. **Given** a capability that already supports the documented posture by default, **When** the reader
   reviews its row, **Then** the row explicitly states that no MLZ setting or template change is
   required and identifies any mission-specific validation still expected.
5. **Given** a mission owner preparing authorization evidence, **When** the owner reads the scope and
   limitations, **Then** the document clearly states that the mapping is guidance, controls may have
   shared or external responsibilities, and deployment does not confer compliance or authorization.
6. **Given** a reviewer following a mapping or required-change statement, **When** the reviewer opens
   its citations, **Then** the claim can be traced to the MLZ implementation and authoritative
  NIST, DoD/DISA/CNSS, or Microsoft guidance, as applicable to the claim.

---

### User Story 2 - Plan Tactical Changes for an IL5 MLZ Deployment (Priority: P2)

**Maps to issue**: [#1303](https://github.com/Azure/missionlz/issues/1303)

A mission owner, deployment engineer, or assessor needs a second contributor-maintained document that
turns parameter changes and actions outside MLZ into practical steps. For planned template features,
the document states the current gap and customer action and links to the owning feature request. It
does not expose internal engineering instructions or invent mission-specific decisions.

**Why this priority**: The mapping establishes what must change; this story makes those findings
actionable. It depends on the completed mapping but remains independently useful as a tactical change
plan and evidence checklist for an IL5 deployment.

**Independent Test**: Compare the three action categories in the mapping with the tactical guide and
confirm that each mapped change is covered by a practical set of steps with files or owners and a
completion check.

**Acceptance Scenarios**:

1. **Given** the completed mapping, **When** a reviewer compares its parameter, template, and
  outside-MLZ actions with the tactical document, **Then** every mapped action is covered and no new
  requirement is introduced.
2. **Given** a parameter-change item, **When** a deployment engineer reviews its checklist, **Then** the
  item names the parameter, current default, required value or decision, declaration and consumer files,
  deployment input file when one exists, steps, and verification.
3. **Given** a planned template feature, **When** a customer reviews the guide, **Then** the item states
  the current limitation, customer action, expected result, and owning feature request without
  including engineering implementation instructions.
4. **Given** an action outside MLZ, **When** the responsible party reviews its checklist, **Then** the
  item identifies the owner, ordered steps, expected result, and evidence to retain.
5. **Given** related actions, **When** a deployment team follows the guide, **Then** the document presents
  them in a practical order from decisions and configuration through verification and operations.
6. **Given** a value that depends on mission needs, authorizing-official direction, or dynamic discovery,
  **When** the document reaches that decision point, **Then** it identifies the decision owner, inputs,
  and validation evidence instead of inventing a value.
7. **Given** official guidance with applicability wider than a single Microsoft Azure Government
  deployment, **When** it is cited or summarized, **Then** its wider applicability is preserved and the
  document names only US Gov Arizona, Texas, or Virginia for new deployments.
8. **Given** a reader comparing current MLZ behavior with a proposed change, **When** the reader reviews
  any tactical item, **Then** current behavior and proposed behavior are labeled separately and cannot
  be mistaken for an already implemented capability.
9. **Given** a completed tactical draft, **When** it undergoes documentation validation, **Then** it
  passes repository Markdown and link checks and its prose meets a grade-11 readability target.

### Edge Cases

- A core capability may include multiple resources with one shared security purpose; the mapping must
  avoid duplicate or contradictory rows while keeping each resource discoverable.
- A capability may be conditionally deployed through an existing setting; it must be classified as
  optional, and the enabling condition must be stated rather than treating it as default or absent.
- A security need may not be provided by the core template; it must be marked absent and described as
  a gap without pulling an add-on into scope or implying that a named external solution is mandatory.
- One resource may support several controls, and one control may depend on several resources; the
  mapping must describe contribution rather than imply one-to-one or complete control implementation.
- RMF control identifiers or authoritative guidance may change; citations must identify the source
  version or publication date used so readers can recognize stale mappings.
- A core resource may exist in the template but require mission-specific values unavailable as a
  universal default; the mapping must distinguish the template capability from the mission owner's
  responsibility to select and validate those values.
- One parameter change may affect several declaration, consumer, deployment, example, or
  user-interface files; the guide must identify the files a contributor or deployer needs.
- Several mapping actions may depend on the same mission decision or outside-MLZ handoff; the guide may
  explain that shared prerequisite once.
- A parameter or resource may be renamed, generated, conditionally consumed, or absent from one
  deployment method; the guide must state when a named file does not exist.
- Current behavior may already match the required posture; the tactical document must record the
  verification and evidence action without proposing an unnecessary change.
- An official source may describe multiple Azure Government or DoD environments; the tactical document
  must preserve the source's scope without implying that one region is a lifecycle stage of another.
- A link may be valid only for authenticated readers or may later move; validation must identify access
  limitations and retain enough source metadata for the reference to remain discoverable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The feature MUST add one dedicated contributor-facing document under `docs/` that is
  discoverable from the repository's existing documentation navigation or index.
- **FR-002**: The document MUST define its audience, IL5-focused purpose, scope, assumptions, and
  shared-responsibility boundaries before presenting the mapping.
- **FR-003**: The document MUST inventory all created resources and security capabilities transitively
  reachable from `src/mlz.bicep` through local core modules at the version reviewed.
- **FR-004**: The inventory and mapping MUST exclude everything under the MLZ add-ons scope.
- **FR-005**: Every mapped capability MUST have exactly one state: **Default** when deployed without an
  explicit opt-in, **Optional** when available only through an explicit configuration choice, or
  **Absent** when the core template does not provide it.
- **FR-006**: The mapping table MUST identify, for each capability, the associated core MLZ resource or
  resources, capability state, security contribution, representative RMF control family and control
  identifiers, required IL5 action, and supporting sources.
- **FR-007**: RMF relationships MUST be described as representative contributions to control objectives,
  not as exhaustive control coverage or evidence that a control is fully implemented.
- **FR-008**: For each Default capability, the document MUST state whether an MLZ change is unnecessary
  or identify the exact existing setting or core-template change still required for the documented
  IL5 posture.
- **FR-009**: For each Optional capability, the document MUST identify the exact existing MLZ setting,
  its current/default behavior, and the value or choice needed for the documented IL5 posture.
- **FR-010**: For each Absent capability, the document MUST cite evidence that the reachable core graph
  does not provide it and classify the response as a core-template change, external implementation, or
  deployment-time verification without bringing add-on implementations into scope.
- **FR-011**: Required-action statements MUST distinguish repository-controlled MLZ changes from
  mission-specific configuration, operational procedures, inherited controls, and responsibilities
  owned by other parties.
- **FR-012**: The document MUST state prominently that deploying MLZ does not by itself confer DoD IL5
  compliance, satisfy every RMF requirement, produce an authorization decision, or replace assessment
  by the responsible authorizing organization.
- **FR-013**: Material claims about MLZ defaults and settings MUST cite the applicable MLZ source or
  existing repository documentation. Control definitions and RMF terminology MUST cite NIST; IL5
  applicability, tailoring, and authorization context MUST cite DoD/DISA/CNSS; and Azure behavior,
  authorization scope, and configuration guidance MUST cite Microsoft.
- **FR-014**: Each external source MUST include enough publication or version information and a stable
  locator for a reviewer to identify the guidance used for the mapping.
- **FR-015**: The document MUST identify the MLZ revision and the RMF guidance baseline reviewed so
  readers can determine when the mapping requires revalidation.
- **FR-016**: Terminology and capability-state labels MUST be defined and used consistently throughout
  the document.
- **FR-017**: The document MUST pass the repository's Markdown validation with no errors or warnings.
- **FR-018**: The feature MUST add a second dedicated contributor-facing tactical document under
  `docs/`, linked from both the mapping document and the repository's existing documentation navigation.
- **FR-019**: The tactical document MUST reconcile every parameter change, proposed template change,
  and outside-MLZ action identified in the mapping, with no missing or invented actions.
- **FR-020**: The tactical document MUST organize work in a practical order and use checklist syntax
  for steps that a reader performs.
- **FR-021**: Every parameter-change section MUST name the parameter, current default, required value or
  mission decision, declaration file, consumer files, deployment input file when one exists, steps,
  and verification.
- **FR-022**: Every planned template-feature section MUST state the current limitation, customer
  action, expected result, and owning feature request. Engineering files, implementation steps,
  compatibility decisions, build instructions, and code tests MUST remain in the feature request.
- **FR-023**: Every outside-MLZ section MUST identify its accountable owner, ordered steps, expected
  result, and evidence to retain.
- **FR-024**: Related actions MAY share one section when that structure is easier to follow, provided
  each mapped action remains clear.
- **FR-025**: The guide MUST distinguish current MLZ behavior from required or proposed behavior.
- **FR-026**: The tactical document MUST NOT invent mission-specific values, authorizing-official
  decisions, or values that require dynamic discovery; it MUST instead identify the decision owner,
  required inputs, decision point, and validation evidence.
- **FR-027**: The tactical document MUST preserve the scope of official guidance that applies more
  widely than a single Microsoft Azure Government deployment and MUST name only US Gov Arizona,
  Texas, or Virginia for new deployments.
- **FR-028**: RMF terminology and tactical control relationships MUST use NIST SP 800-53 Revision 5 and
  the same documented DoD IL5 baselines selected for the mapping, without introducing a conflicting
  baseline.
- **FR-029**: Every tactical item MUST label verified current MLZ behavior separately from proposed
  behavior so readers cannot interpret documentation as an implemented infrastructure change.
- **FR-030**: The tactical document MUST use language understandable at or below a grade-11 reading
  level while retaining exact technical names, values, file paths, resource properties, and evidence
  requirements.
- **FR-031**: The tactical document MUST pass repository Markdown and link validation with zero errors
  or warnings.
- **FR-032**: The feature MUST remain documentation-only and MUST NOT modify infrastructure templates,
  deployment artifacts, parameter files, user-interface definitions, or deployed resources. Tests are
  allowed when useful.

### Key Entities *(include if feature involves data)*

- **Core MLZ Capability**: A security-relevant capability and its associated resource or resource group
  transitively reachable from the main MLZ template through core modules, or a closed-list IL5 need
  verified absent from that graph. Key attributes include resource names or absence evidence, security
  purpose, current deployment condition, and reviewed MLZ revision.
- **Capability State**: The mutually exclusive classification Default, Optional, or Absent, determined
  from actual core-template behavior rather than intended architecture.
- **RMF Relationship**: A representative relationship between a capability's security contribution and
  one or more DoD IL5 RMF control families or controls. It describes support for a control objective,
  not complete implementation or authorization status.
- **Required IL5 Action**: A concrete action needed to reach the documented posture. It identifies an
  existing parameter change, a core-template change, an external implementation, a deployment-time
  verification, or that no MLZ change is required, plus any mission-owned follow-up.
- **Authoritative Source**: Traceable evidence from the reviewed MLZ implementation or authoritative
  NIST, DoD/DISA/CNSS, or Microsoft guidance that supports a mapping, classification, or required action.
- **Tactical Change Section**: A practical set of steps for one or more closely related mapping actions,
  classified as parameter changes, proposed template changes, or outside-MLZ work.
- **Decision Point**: A value or choice that cannot be universally prescribed because it depends on
  mission needs, authorizing-official direction, organizational policy, or deployment-time discovery.
  It records the decision owner, required inputs, dependencies, and evidence rather than a fabricated
  answer.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of core resources and security capabilities identified in the reviewed main MLZ
  template and core modules appear in the mapping, and 0 add-on capabilities appear.
- **SC-002**: 100% of mapping rows contain one capability-state label, a security contribution, at least
  one representative RMF relationship or an explicit reason none applies, a required-action statement,
  and supporting citations.
- **SC-003**: For 100% of Optional rows, a reviewer can identify the exact setting and required choice;
  for 100% of Absent rows, a reviewer can identify the absence evidence and whether the response is a
  template change, external implementation, or deployment-time verification.
- **SC-004**: A structured inspection of a representative sample from each capability state reaches an
  unambiguous conclusion about current MLZ behavior and required action for every sampled row. An
  independent-reviewer check may follow as the documentation review process matures.
- **SC-005**: 100% of sampled RMF and IL5 claims can be traced to authoritative NIST, DoD/DISA/CNSS, or
  Microsoft guidance appropriate to the claim, and 100% of sampled MLZ behavior claims can be traced to
  the reviewed repository implementation or repository documentation.
- **SC-006**: The document contains an explicit authorization limitation before or adjacent to the first
  mapping table, and no reviewed statement claims that MLZ deployment alone establishes compliance or
  authorization.
- **SC-007**: In a timed structured inspection, the reviewer can locate a selected core capability's
  state, RMF relationship, and required action within 3 minutes using the document alone.
- **SC-008**: The completed document passes all repository Markdown validation checks with zero errors
  and zero warnings.
- **SC-009**: A category-by-category comparison finds every parameter, template, and outside-MLZ action
  from the mapping covered by the tactical guide, with zero omissions or invented requirements.
- **SC-010**: Every parameter section names the parameter and files to update plus the required value or
  decision, steps, and verification.
- **SC-011**: Every planned template-feature section links to its owning feature request, states the
  current limitation and customer action, and contains no internal engineering instructions.
- **SC-012**: Every outside-MLZ section identifies an owner, steps, expected result, and evidence without
  inventing mission-specific or authorizing-official decisions.
- **SC-013**: The guide follows the same practical pattern for each section: change, files or owner,
  current state, steps, and verification or evidence.
- **SC-014**: The tactical document records NIST SP 800-53 Revision 5 and the mapping's existing DoD IL5
  baselines, names only US Gov Arizona, Texas, and Virginia for new deployments, and contains
  zero conflicting baseline statements in review.
- **SC-015**: Repeatable review reports zero Markdown errors, zero broken links, and a Flesch-Kincaid
  grade-level score of 11 or lower for explanatory prose.

## Assumptions

- The approved scope is the core deployment rooted in the main MLZ template and its core modules;
  examples, artifacts, and all add-ons are excluded from the resource inventory.
- "IL5 posture" means configuration and evidence considerations relevant to using MLZ within a DoD IL5
  authorization boundary; it does not mean that one universal MLZ configuration can satisfy every
  mission's complete control implementation.
- Representative controls will use the RMF baseline and authoritative guidance current at the time of
  research, with the selected versions recorded in the document.
- Existing parameter names, defaults, and deployment conditions are facts to be verified against the
  reviewed repository revision during research rather than inferred from marketing or architecture
  descriptions.
- Where requirements depend on mission data, inherited services, organizational policy, or operational
  procedures, the document will identify those dependencies instead of inventing universal template
  defaults.
- The documentation will be maintained as guidance for contributors, mission owners, and assessors and
  will not serve as a system security plan, control assessment, or authorization package by itself.
- User Story 2 uses the completed mapping as its authoritative action inventory; the guide may group
  closely related work for readability but cannot add unsupported requirements.
- The existing DoD IL5 baseline selections and citations established for User Story 1 remain
  authoritative for User Story 2 alongside NIST SP 800-53 Revision 5.
- File names and change surfaces stated in the tactical document are planning facts verified against the
  reviewed repository revision; naming a file does not authorize or perform a modification.

## Out of Scope

- Implementing any MLZ setting, parameter, module, resource, or generated-template change identified by
  the mapping.
- Creating or modifying add-ons, or documenting add-ons as substitutes for absent core capabilities.
- Producing a complete control implementation statement, system security plan, assessment report,
  authorization package, compliance certification, or authorization decision.
- Mapping mission applications, workloads, tenant-wide services, inherited enterprise controls, or
  operational procedures beyond the boundaries needed to explain shared responsibility.
- Claiming that a resource alone fully satisfies an RMF control or that an MLZ deployment is compliant
  with or authorized for DoD IL5.
- Implementing, testing as implemented, deploying, or migrating any parameter or template change
  described by the tactical document.
- Choosing mission-specific values, making authorizing-official decisions, or predicting dynamically
  discovered deployment values on behalf of their accountable owners.
