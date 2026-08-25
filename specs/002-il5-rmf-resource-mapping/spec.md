# Feature Specification: IL5 RMF Resource Mapping Documentation

**Feature Branch**: `002-il5-rmf-resource-mapping`

**Feature Issue**: [#1301](https://github.com/Azure/missionlz/issues/1301) — Document MLZ relationships to IL5 RMF

**User Story Issue**: [#1302](https://github.com/Azure/missionlz/issues/1302) — Review MLZ resource-to-IL5 RMF mapping (native sub-issue of #1301)

**Created**: 2026-08-24

**Status**: Draft

**Input**: User description: "Create a new document under docs/ containing a table of core Mission Landing Zone resources, their relationship to DoD IL5 RMF controls, and explicit MLZ setting/template changes needed for IL5. Exclude add-ons. Distinguish default, optional, and absent capabilities. Do not claim deployment confers compliance or authorization."

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

**Why this priority**: This is the complete value described by the approved Feature and its only User
Story. A partial inventory without control relationships, capability state, or required changes would
not let mission owners and assessors identify evidence and gaps.

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
