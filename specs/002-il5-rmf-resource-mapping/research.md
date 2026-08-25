# Research: IL5 RMF Resource Mapping Documentation

**Feature**: `002-il5-rmf-resource-mapping`
**Research date**: 2026-08-24
**Reviewed MLZ revision**: `168474463215f99620531bfdeb47039bf7bd250a`
**Scope**: Core deployment rooted at `src/mlz.bicep` and local modules reachable
under `src/modules/`; `src/add-ons/` is excluded.

## Decision 1: Use a Source Hierarchy That Separates Requirements, Platform Guidance, and Implementation Facts

**Decision**: Use the following evidence hierarchy for the eventual document:

1. DoD Cloud Computing Security Requirements Guide (CC SRG) and DoD Instruction
   8510.01 for DoD cloud and RMF requirements.
2. NIST SP 800-37 Rev. 2 and the applicable NIST SP 800-53 control catalog for RMF
   process and representative control objectives.
3. Current Microsoft Azure Government IL5 offering, isolation, service-scope, shared
   responsibility, and Azure Policy documentation for platform-specific guidance.
4. The reviewed `src/mlz.bicep` and transitively referenced `src/modules/` files for
   MLZ defaults, conditions, resources, and gaps.

Repository source is authoritative only for what MLZ declares. It cannot establish
DoD requirements, a service's current IL5 PA scope, or an authorization decision.

**Rationale**: This prevents Microsoft guidance from being presented as DoD policy and
prevents an infrastructure template from being treated as compliance evidence by
itself. It also gives every material claim a traceable owner.

**Alternatives considered**:

- Derive controls directly from Azure Policy. Rejected because Microsoft states that
  Azure Policy provides only a partial view of overall compliance.
- Use MLZ parameter descriptions as IL5 requirements. Rejected because those
  descriptions document template behavior, not authoritative DoD requirements.

### Authoritative Source Register

| Source | Version/date captured | Use in the mapping | Access caveat |
| --- | --- | --- | --- |
| [DoD Cloud Computing Security](https://www.cyber.mil/dccs/) and its [CC SRG document library](https://public.cyber.mil/dccs/dccs-documents/) | Current public landing page reviewed 2026-08-24 | Cloud authorization process, IL5 model, CC SRG locator; Microsoft cites CC SRG sections 3.1.3, 5.1.1, 5.2.2.3, and 5.11 | The landing page is accessible, but the current CC SRG file and its revision metadata were not exposed to the available fetcher. The implementation review must record the revision/date printed in the downloaded SRG before citing requirements. |
| [DoD Instruction 8510.01](https://www.esd.whs.mil/Portals/54/Documents/DD/issuances/dodi/851001p.pdf), *Risk Management Framework for DoD Systems* | Current official PDF locator reviewed 2026-08-24 | DoD RMF roles, lifecycle, authorization, and ongoing authorization framing | The official PDF was not text-extractable through the available fetcher. Cite section/page only after a reviewer opens the current PDF and records its displayed publication/change date. |
| [NIST SP 800-37 Rev. 2](https://doi.org/10.6028/NIST.SP.800-37r2), *Risk Management Framework for Information Systems and Organizations* | Final, December 2018 | RMF lifecycle, common/shared/system-specific controls, assessment evidence, authorization, and continuous monitoring | Public page and DOI were accessible. |
| [NIST SP 800-53 control catalog](https://csrc.nist.gov/Projects/risk-management/sp800-53-controls/release-search#/800-53) | Revision 5, selected by the feature owner on 2026-08-24 | Representative control identifiers and control-family language | Use Revision 5 consistently; do not mix Rev. 4 identifiers or Azure Policy initiative labels into the representative mapping. |
| [Department of Defense Impact Level 5](https://learn.microsoft.com/azure/compliance/offerings/offering-dod-il5) | Page reviewed 2026-08-24 | Azure Government IL5 PAs, service-scope links, responsibility labels, and the warning that Azure Policy is partial compliance evidence | Service scope and policy content are dynamic and must be rechecked at publication time. |
| [Isolation guidelines for Impact Level 5 workloads](https://learn.microsoft.com/azure/azure-government/documentation-government-impact-level-5) | Page reviewed 2026-08-24 | Required compute/storage isolation configuration for US Gov regions, CMK guidance, and regional distinctions | Microsoft states that the article covers additional isolation settings, not all network, access-control, or security requirements. |
| [Department of Defense in Azure Government](https://learn.microsoft.com/azure/azure-government/documentation-government-overview-dod) | Page reviewed 2026-08-25 | Microsoft recommends US Gov regions for new IL5 deployments to gain the latest cloud innovations and encourages migration from US DoD regions for additional services. US DoD regions remain reserved for exclusive DoD use. | The recommendation concerns service and feature availability, not region lifecycle status. Availability and PA scope vary by region and over time. |
| [Azure Government shared responsibility guidance](https://learn.microsoft.com/azure/azure-government/documentation-government-overview-wwps#shared-responsibility) | Page reviewed 2026-08-24 | Microsoft, customer, and shared responsibility boundaries | Responsibility changes by service model and customer architecture. |
| [Azure Government security and regulatory compliance initiatives](https://learn.microsoft.com/azure/azure-government/documentation-government-plan-security#customer-monitoring-of-azure-resources) | Page reviewed 2026-08-24 | Azure Policy's role in enforcing standards and assessing posture | Microsoft explicitly describes policy compliance as partial, not an authorization result. |
| [Azure Policy built-ins index](https://learn.microsoft.com/azure/governance/policy/samples/) | Page reviewed 2026-08-24 | Current built-in initiative discovery and IDs | The linked `gov-dod-impact-level-5` page redirected to this index, whose Azure Government table did not list the DoD IL5 initiative on the review date. |
| [Azure Firewall threat intelligence configuration](https://learn.microsoft.com/azure/firewall-manager/threat-intelligence-settings) and [Firewall Premium IDPS](https://learn.microsoft.com/azure/firewall/premium-features#idps) | Pages reviewed 2026-08-24 | Meanings of Alert, Deny/Alert and Deny, and Off modes | Mission owners must tune and test prevention behavior; the mapping should not imply zero operational risk. |

## Decision 2: Derive the Inventory Only From the Reachable Core Bicep Graph

**Decision**: Start at the seven module declarations in `src/mlz.bicep`, recursively
follow only local module paths under `src/modules/`, and inventory resources declared
by those reachable files. Group related resource declarations into one discoverable
security capability when they have one security purpose. Record all associated Azure
resource types and source files in that capability row.

Do not inventory:

- Any file or capability under `src/add-ons/`.
- Unreferenced modules merely present in `src/modules/` (for example, `aks.bicep`).
- Generated `src/mlz.json`, examples, test fixtures, or deployment artifacts as
  independent sources of resource truth.
- `existing` resource declarations as MLZ-created resources; use them only to explain
  relationships or dependencies.

**Rationale**: Reachability reflects the actual core deployment surface. Grouping by
security purpose avoids duplicate control claims while retaining resource
discoverability.

**Alternatives considered**:

- Inventory every file in `src/modules/`. Rejected because dormant modules would be
  incorrectly presented as core capabilities.
- Inventory every ARM resource declaration as a separate mapping row. Rejected because
  helper, child, role-assignment, and diagnostic resources would create duplicate and
  misleading control claims.

### Reachable Core Capability Inventory

| Capability group | Root path or deployment condition | Principal created resource types |
| --- | --- | --- |
| Resource and tier structure | Always through `modules/networking.bicep`; resource groups also created for optional remote access | `Microsoft.Resources/resourceGroups` |
| Hub-and-spoke network segmentation | Always | Virtual networks, subnets, NSGs, route tables, VNet peerings, private DNS zones and links |
| Central Azure Firewall | Always | Firewall Policy, Azure Firewall, firewall rule collection groups, public IP addresses |
| Central monitoring and private monitor path | Always | Log Analytics workspace, Operations Management solutions, Azure Monitor Private Link Scope, private endpoint and DNS zone group |
| Central diagnostic routing and flow logs | Always, with resource-specific conditions | Diagnostic settings and Network Watcher flow logs for activity, storage, NSG/VNet, public IP, firewall, Key Vault, Bastion, and NIC scopes |
| Core storage with customer-managed keys | Always for tier log storage; optional consumers reuse the CMK path | Storage accounts, Key Vault, keys, managed identity, private endpoints, private DNS groups, disk encryption set and supporting role assignments |
| Azure Policy regulatory assignment | Optional: `deployPolicy` | Policy assignments, role assignments, VM/VMSS monitoring assignments, optional remediation |
| Defender for Cloud | Default capability because `deployDefender` defaults true; tier and plan selection remain configurable | Defender pricing plans, security contact when email supplied, and Microsoft Cloud Security Benchmark assignment in `DoNotEnforce` mode |
| Microsoft Sentinel | Optional: `deploySentinel` | SecurityInsights solution and onboarding state |
| Bastion remote access | Optional: `deployBastion` | Bastion host, dedicated NSG, and public IP |
| Management VMs | Optional: Linux and Windows deployment flags | NICs, VMs, Trusted Launch/guest/monitoring extensions, CMK-backed disks |
| AD DS identity tier | Optional: `deployIdentity` and `deployActiveDirectoryDomainServices` | Availability set, domain-controller VMs, run commands, CMK resources, and firewall-policy update |

The implementation must expand this grouped inventory against the recursive source graph
and prove that each reachable created resource is represented exactly once. The table
above is the planning baseline, not the final mapping table.

## Decision 3: Map Security Contributions to Representative Controls, Not Control Satisfaction

**Decision**: For each capability, describe the observable security contribution first,
then map that contribution to a small set of representative control families and control
identifiers from one declared NIST baseline. Apply this sequence:

1. Establish current behavior from Bicep: state, condition, defaults, and resource
   properties.
2. State the capability's narrow security contribution without compliance language.
3. Select representative controls whose objective is directly supported by that
   contribution.
4. Label responsibility as repository-controlled, mission/customer, Microsoft/inherited,
   shared, or external/organizational.
5. State what evidence the capability can produce and what evidence remains outside MLZ.
6. Identify the exact MLZ setting or template gap, plus mission validation.

Use phrases such as "contributes to," "supports evidence for," and "is relevant to."
Never use "implements," "satisfies," "meets," or "complies with" unless an
authoritative source explicitly supports the precise scoped claim and all shared
responsibilities are stated.

Examples of representative relationships to validate during implementation include:

- Network segmentation, firewall, NSGs, and private endpoints: AC-4, SC-7, and SI-4.
- Diagnostic settings, flow logs, and Log Analytics: AU-2, AU-6, AU-9, AU-11, and CA-7.
- Key Vault, CMK, disk/storage encryption: SC-12, SC-13, and SC-28.
- Azure Policy and Defender posture data: CA-2, CA-7, CM-6, RA-5, and SI-4.
- Trusted Launch and hardened VM configuration: CM-6, SI-6, and SC-3.

These are candidates, not final control assertions. The final identifiers must be checked
against the selected NIST revision and the current DoD baseline.

**Rationale**: RMF controls are many-to-many, and resource existence does not prove
control effectiveness. Contribution-first mapping is reviewable and resists accidental
authorization claims.

**Alternatives considered**:

- One resource to one control. Rejected because both resource capabilities and controls
  are compositional.
- Copy all controls associated with an Azure Policy initiative. Rejected because it
  overstates coverage and obscures customer, inherited, and operational responsibilities.

## Decision 4: Required MLZ Settings and Core Template Gaps

**Decision**: The eventual document must include the following explicit findings and
classify each capability as Default, Optional, or Absent from actual core behavior.

### Azure Government IL5 Policy Initiative

`deployPolicy` defaults to `false`, and `policy` defaults to `NISTRev4`. MLZ contains
IL5 initiative ID `f9a961fa-3241-4b20-adc4-bbf8ad9d7197` and falls back to NIST Rev. 4
in Azure Commercial. For Azure Government IL5, set `deployPolicy=true` and
`policy='IL5'`, then verify that the initiative ID is currently available and appropriate
in the target tenant. This is an Optional repository setting; policy results remain
partial evidence only.

### Defender for Cloud

`deployDefender` defaults to `true`, `defenderSkuTier` defaults to `Free`, and
`deployDefenderPlans` defaults to `['VirtualMachines']`. Government Standard pricing
receives no subplan or extension configuration in the module. Set
`defenderSkuTier='Standard'` and select every plan required by the deployed core resource
types and mission risk assessment. Verify plan names, availability, pricing, and
government-cloud behavior. Defender is a Default MLZ capability; the tier and plan
changes are IL5 profile parameter changes, not corrections to the general-purpose MLZ
baseline. No plan set grants IL5 authorization.

### Firewall SKU, IDPS, and Threat Intelligence

Firewall Premium is the default, but `firewallIntrusionDetectionMode` and
`firewallThreatIntelMode` both default to `Alert`. Retain Premium and set
`firewallIntrusionDetectionMode='Deny'` after mission tuning and testing. Set
`firewallThreatIntelMode='Deny'` after allowlist and false-positive review. MLZ uses the
Bicep value `Deny` for the service's Alert and Deny or prevention behavior. These are
existing setting changes to a Default firewall capability.

### Audit and Flow-Log Retention

Log Analytics and Network Watcher flow-log retention default to 30 days. Enabling
Sentinel forces workspace retention to at least 90 days. Select values from the system
retention schedule, applicable controls, records policy, incident-response needs,
capacity, and cost. Do not invent one universal IL5 duration; flow-log and
workspace/table retention can differ. These are mission-owned values on existing
parameters.

### Log Analytics Network Exposure

The workspace hard-codes public ingestion and query to `Enabled`, even though MLZ also
deploys an Azure Monitor Private Link Scope and private endpoint. Add core parameters and
properties to disable public ingestion and query while preserving and validating
private-link paths, DNS, deployment agents, and operational access. This configurability
is Absent and requires a core-template change.

### NSG and PPSM Rules

The hub, operations, shared-services, and identity NSG rule arrays all default empty.
Supply least-privilege rules derived from the mission's approved Ports, Protocols, and
Services Management (PPSM) registration or baseline and data flows. MLZ cannot define
universal PPSM values. Validate effective rules and routing for every tier. These are
Optional existing parameters with mission-owned values.

### VM Compute Isolation in US Gov Regions

Core VMs accept a free-form `virtualMachineSize` and optional availability set. No host
group, Dedicated Host, or host placement resource or property exists, and defaults are
ordinary shared-host SKUs. In US Gov Arizona, Texas, or Virginia, use Azure Dedicated
Host for the single VMs that core MLZ deploys. Add host-group, host, and placement
capability. Treat wider MAG as the target for new MLZ deployments. Do not recommend US
DoD Central or East as peer targets. Microsoft recommends US Gov regions for new IL5
deployments to gain the latest cloud innovations and encourages migration from US DoD
regions for additional services. This recommendation is based on service and feature
availability, not region lifecycle status. Dedicated Host support is Absent. Validate
current service scope, host-family availability, quota, and region at deployment time.

### VM and Storage Encryption

Core management and domain-controller VMs use encryption at host, Trusted Launch, disk
encryption sets, Key Vault, and CMK support. Core storage uses CMK paths and disables
public access. Treat these as security contributions, then validate key ownership,
HSM/FIPS requirements, rotation, recovery, service scope, and whether every data-bearing
service uses the required CMK before data is written. The core capability is present,
but operational validation remains.

### Capabilities Not Supplied by Core MLZ

The core graph does not provide a complete SSP or control implementation statement,
authorization package, assessor evidence set, PPSM registration, vulnerability-management
operations, incident-response procedures, identity governance, data classification,
backup and recovery policy, endpoint-protection operations, application controls, or
Dedicated Host. Use `Absent` only for deployment state, then classify the response
independently as a template change, external implementation, or deployment-time
verification. Do not pull add-ons into scope or prescribe one external product.

**Rationale**: This preserves exact source facts while separating repository changes from
mission configuration and inherited or organizational responsibilities.

**Alternatives considered**:

- Declare all listed values mandatory universal IL5 defaults. Rejected because retention,
  PPSM, plan selection, region, workload mix, and evidence requirements are mission-specific.
- Treat a parameter as sufficient merely because it exists. Rejected because availability,
  effective deployment state, and operational evidence still require validation.

## Decision 5: Region and Availability Claims Must Be Time-Bounded

**Decision**: Recommend wider MAG regions US Gov Arizona, Texas, and Virginia for new
MLZ deployments. Cite Microsoft's compute-isolation requirement and require Dedicated
Host for the single VMs MLZ deploys. Mention US DoD regions only for existing-deployment
service-scope and migration checks; do not present them as peer targets. Do not publish
a static host-SKU list as timeless fact. Record the validation date and link to current
Dedicated Host families, products-by-region, and IL5 PA audit scope.

**Rationale**: Host-family availability, quota, and service authorization vary by region
and date. Microsoft's current page reserves isolated VM guidance for scale sets in its
service-specific section; core MLZ deploys single VMs, not scale sets.

**Alternatives considered**:

- Embed a fixed host-SKU list in the mapping. Rejected because it would become stale and
  could direct readers to unavailable hardware.

## Decision 6: Authorization and Compliance Caveat Is a Release Gate

**Decision**: Place an authorization limitation before or directly adjacent to the first
mapping table. It must state that:

- MLZ is one technical component within a larger authorization boundary.
- Deployment does not confer DoD IL5 compliance, satisfy every RMF control, produce a
  provisional authorization or authorization to operate, or replace assessment by the
  responsible authorizing organization.
- Azure's PA applies to the scoped cloud service offering, not automatically to the
  customer's system or mission deployment.
- Control implementation and evidence can be Microsoft/inherited, shared,
  repository-controlled, mission/customer-controlled, or external/organizational.
- Azure Policy and Defender findings are posture and evidence inputs, not authorization
  decisions.

The quickstart review must fail if the caveat is missing, appears only after the mapping,
or if any row claims complete control implementation from resource deployment alone.

**Rationale**: DoDI 8510.01 and NIST RMF place authorization with designated officials
using assessed evidence and risk decisions. Microsoft likewise says customers remain
responsible for designing and deploying applications to meet IL5 requirements and that
Azure Policy shows only part of overall compliance status.

**Alternatives considered**:

- Put a short disclaimer only at the end. Rejected because readers could encounter and
  reuse the mapping before seeing its limitations.

## Research Limitations and Publication-Time Checks

The following are not unresolved design questions; they are explicit publication-time
verification steps for dynamic or access-limited sources:

1. Record the current CC SRG revision/date from the downloaded official document and
   verify cited section/page numbers.
2. Record the current DoDI 8510.01 publication/change date and verify cited sections.
3. Select and state one NIST SP 800-53 revision/control release for all identifiers.
4. Verify initiative ID `f9a961fa-3241-4b20-adc4-bbf8ad9d7197` in the target Azure
   Government environment because the current public built-ins index did not expose the
  linked DoD IL5 initiative page. The 2026-08-24 implementation check found only an
  authenticated `AzureCloud` context, so this target-tenant check remains open.
5. Verify each core Azure service is in the current IL5 PA audit scope for the intended
   region.
6. For wider MAG, verify Dedicated Host families, quota, and availability on the
  validation date. Confirm the document does not recommend US DoD Central or East for
  new deployments.

These checks are required evidence for the documentation implementation; none permits
the document to claim authorization.
