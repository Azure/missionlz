# Data Model: IL5 RMF Resource Mapping Documentation

**Feature**: `002-il5-rmf-resource-mapping` | **Date**: 2026-08-24

This documentation-only feature has no runtime database. Its entities define the
reviewable records and relationships required in the final mapping. Presentation rules
are in [contracts/document-contract.md](contracts/document-contract.md).

## Entity: Review Baseline

The fixed context against which every source and classification claim is made.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `mlzCommit` | Git SHA | yes | Exact repository revision reviewed. |
| `reviewDate` | ISO date | yes | Date dynamic external guidance was checked. |
| `cloudAndRegions` | string/list | yes | Azure Government environment and regions covered. |
| `ccSrgVersion` | string | yes | Revision/date printed in the reviewed CC SRG. |
| `dodi8510Version` | string | yes | Publication/change date printed in DoDI 8510.01. |
| `nistControlRelease` | string | yes | One NIST SP 800-53 revision/release used consistently. |

Dynamic availability or authorization-scope claims reference `reviewDate`. Missing
source metadata blocks publication and is not replaced with an inferred date.

## Entity: Core MLZ Capability

A security-relevant capability represented by one or more created resources reachable
from `src/mlz.bicep` through local modules under `src/modules/`, or a closed-list IL5
need verified absent from that reachable graph.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | string | yes | Unique reader-oriented capability name. |
| `resources` | list | conditional | Created resource types and source locations for Default or Optional capabilities; empty for Absent capabilities. |
| `absenceEvidence` | list | conditional | Required for Absent capabilities; source paths and inventory evidence showing the capability is not created. |
| `deploymentCondition` | string | yes | Always deployed or exact controlling parameter expression. |
| `state` | Capability State | yes | Exactly Default, Optional, or Absent. |
| `securityContribution` | string | yes | Narrow behavior supporting security or evidence. |
| `rmfRelationships` | list | yes | Representative relationships or an explicit reason none applies. |
| `requiredAction` | Required IL5 Action | yes | Exact setting, gap, or no-change statement. |
| `responsibilities` | list | yes | Parties responsible for implementation or evidence. |
| `sources` | list | yes | Repository and authoritative external evidence. |

Every reachable created resource belongs to exactly one capability's `resources` list.
Existing-resource declarations are dependencies, not created inventory. Add-on,
generated, example, and test resources are invalid inventory members.

## Entity: Capability State

| Value | Definition |
| --- | --- |
| `Default` | Deployed without explicit opt-in, even if harder settings or mission validation remain. |
| `Optional` | Available only through an explicit configuration choice. |
| `Absent` | The reachable core template does not provide the capability or configurability. |

```text
reachable and unconditional/default-enabled -> Default
reachable only after explicit opt-in         -> Optional
not provided by reachable core graph         -> Absent
```

An insufficient default does not make a capability Absent. State reflects deployment
behavior; the required action records hardening.

## Entity: RMF Relationship

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `family` | string | yes | Control family such as AC, AU, CA, CM, SC, or SI. |
| `controlIds` | list | yes | Small set of directly relevant representative controls. |
| `relationship` | string | yes | How the capability contributes to the objective. |
| `evidence` | string | yes | Evidence the capability can produce or support. |
| `limitations` | string | yes | Remaining operational, inherited, or assessment work. |

Relationships are many-to-many and begin with observable behavior, not Azure Policy
labels. Resource existence alone cannot be complete control implementation.

## Entity: Required IL5 Action

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `kind` | enum/list | yes | One or more of `NoMLZChange`, `ParameterChange`, `TemplateChange`, `ExternalImplementation`, or `DeploymentVerification`. |
| `currentBehavior` | string | yes | Verified default or absence. |
| `action` | string | yes | Exact value, capability change, or external activity. |
| `owner` | Responsibility Boundary | yes | Primary accountable party. |
| `validation` | string | yes | Evidence proving effective behavior. |

`ParameterChange` names the exact parameter and choice. `TemplateChange` identifies a
missing core capability without prescribing an add-on. `ExternalImplementation`
identifies a mission or organizational capability outside core MLZ.
`DeploymentVerification` records dynamic checks such as region, service authorization,
quota, or SKU availability. `NoMLZChange` still names mission validation and evidence
obligations.

## Entity: Responsibility Boundary

| Value | Meaning |
| --- | --- |
| `MLZ repository` | A core source, parameter, or template change owned here. |
| `Mission/customer` | Workload design, values, operations, evidence, or risk decisions. |
| `Microsoft/inherited` | Azure platform implementation or attestation within its scope. |
| `Shared` | Both platform and mission implementation are material. |
| `External/organizational` | Enterprise policy, AO, assessor, process, or external service. |

## Entity: Authoritative Source

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `title` | string | yes | Human-readable source title. |
| `publisher` | string | yes | Repository, NIST, DoD/DISA/CNSS, or Microsoft. |
| `versionOrDate` | string | yes | Commit, publication/revision, update, or review date. |
| `locator` | URI/path | yes | Stable page, section, file, or source location. |
| `supports` | list | yes | Claims supported by the source. |
| `accessNote` | string | no | Access or dynamic-content limitation. |

## Relationships

```text
Review Baseline 1 ---- * Authoritative Source
Review Baseline 1 ---- * Core MLZ Capability
Core MLZ Capability 1 ---- 1 Capability State
Core MLZ Capability 1 ---- * RMF Relationship
Core MLZ Capability 1 ---- 1 Required IL5 Action
Required IL5 Action * ---- 1 Responsibility Boundary
Core MLZ Capability * ---- * Authoritative Source
```

## Validation Invariants

1. Every reachable created core resource is represented exactly once; each Absent row
   has an empty resource list and explicit absence evidence.
2. No add-on resource is represented.
3. Every capability has exactly one state and required action.
4. Every material MLZ claim has repository evidence.
5. Every material IL5/RMF claim has authoritative external evidence.
6. No entity asserts that deployment confers compliance or authorization.
