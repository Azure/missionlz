# Research: IL5 RMF Resource Mapping Documentation

<!-- markdownlint-disable MD013 -->

**Feature**: `002-il5-rmf-resource-mapping`
**Research date**: 2026-08-24
**Reviewed MLZ revision**: `168474463215f99620531bfdeb47039bf7bd250a`
**Scope**: Core deployment rooted at `src/mlz.bicep` and local modules reachable
under `src/modules/`; `src/add-ons/` is excluded.

## US2/#1303 Tactical-Guide Research

This section is the source-research baseline for a future operator tactical guide. It
does not change MLZ infrastructure and does not turn mission-specific decisions into
universal IL5 values. **Current** statements below describe the reviewed repository;
**Proposed** statements describe the smallest identified template surface and are not
implemented behavior.

### Tactical-Guide Baseline and Action Categories

| Baseline item | Research result |
| --- | --- |
| Guide baseline | Commit `113fb08211bffe603b20c44668df6a756ae80821`, dated 2026-08-25 |
| Earlier source baseline | Commit `168474463215f99620531bfdeb47039bf7bd250a` |
| Source comparison | `git diff` between the two commits found no changes to `src/mlz.bicep`, any `src/modules/*.bicep`, `src/mlz.uiDefinition.json`, or `docs/deployment-guides/`. The Bicep facts reviewed for the mapping therefore remain the source facts for this guide baseline. The later commit adds the mapping and this research artifact. |
| Core parameter files | No core `.bicepparam` or deployment-parameters JSON file is present. Files of those types under `src/add-ons/` are excluded. Core deployment surfaces are `src/mlz.bicep`, generated `src/mlz.json`, `src/mlz.uiDefinition.json`, command-line examples, and the deployment guides. |
| Dynamic facts | Azure Government initiative availability, IL5 PA scope, service and feature availability, Dedicated Host family/capacity/quota, and region support remain deployment-time checks. |

The guide must cover these action groups from the mapping:

| Category | Action groups |
| --- | --- |
| Parameter changes | PPSM/NSG rules; Firewall modes and rules; Log Analytics and flow-log retention; traffic analytics; Defender tier, plans, and contact; Azure Policy IL5 settings; Bastion; AD DS; Sentinel. |
| Proposed template changes | Disable public Log Analytics ingestion and query; add Dedicated Host resources and VM placement. |
| Outside MLZ | Log lifecycle and recovery; key governance; VM operations; administration and identity governance; backup and recovery; PPSM registration; vulnerability management; incident response; data classification; application controls; SSP, assessment, risk, and authorization work. |

Related steps may share a section when that makes the guide easier to follow. The guide
must not omit a mapping action or add a new requirement.

### Current Parameter Paths

#### NSG and PPSM Arrays

The current root parameters are all type `array` with default `[]` and no Bicep
`@allowed` decorator:

- `hubNetworkSecurityGroupRules`
- `operationsNetworkSecurityGroupRules`
- `sharedServicesNetworkSecurityGroupRules`
- `identityNetworkSecurityGroupRules`

Their common path is `src/mlz.bicep` -> the corresponding object in the `networks`
array as `nsgRules` -> `src/modules/networking.bicep` -> `hub-network.bicep` for the hub
or `spoke-network.bicep` for the other tiers ->
`src/modules/network-security-group.bicep` ->
`Microsoft.Network/networkSecurityGroups.properties.securityRules`. The identity object
and its NSG exist only when `deployIdentity=true`; the other three tier NSGs always
deploy. The arrays accept the service security-rule property shape linked from the root
parameter descriptions; MLZ does not constrain or supply a mission PPSM list.

`docs/deployment-guides/command-line-tools.md` lists all four arrays and their empty
defaults. `src/mlz.uiDefinition.json` does not expose or emit any of them, so they are
command-line/API parameter-file inputs rather than Portal-create-UI inputs. Generated
`src/mlz.json` contains all four parameters and forwards them to the nested deployments.

Practical verification must compare all four supplied arrays, where the identity tier
is enabled, to the approved PPSM/data-flow record; inspect effective NSG rules on each
subnet/NIC; and exercise both approved and denied paths through the effective routes.
An empty array is a source fact, not an IL5 recommendation. Azure default NSG rules still
exist and must be included in effective-rule review.

#### Firewall IDPS, Threat Intelligence, and Rule Collections

| Root parameter | Type/default/accepted values | Current path and effect |
| --- | --- | --- |
| `firewallIntrusionDetectionMode` | `string`, default `Alert`; `@allowed`: `Alert`, `Deny`, `Off` | `src/mlz.bicep` -> `networking.firewallSettings.intrusionDetectionMode` -> `networking.bicep` -> `hub-network.bicep` -> `firewall.bicep` -> `Microsoft.Network/firewallPolicies.properties.intrusionDetection.mode`. The property is set only for Premium; `firewallSkuTier` defaults `Premium` and accepts `Premium` or `Standard`. |
| `firewallThreatIntelMode` | `string`, default `Alert`; `@allowed`: `Alert`, `Deny`, `Off` | Same module path -> `Microsoft.Network/firewallPolicies.properties.threatIntelMode`. |
| `customFirewallRuleCollectionGroups` | `array`, default `[]`; service-defined group objects, no root `@allowed` shape | `src/mlz.bicep` selects the built-in array when empty and otherwise uses the supplied array -> `networking.bicep` -> `hub-network.bicep` -> `firewall.bicep` -> `firewall-rules.bicep` -> one `Microsoft.Network/firewallPolicies/ruleCollectionGroups` resource per array item, using `group.name` and `group.properties`. |

The built-in group is `MLZ-DefaultCollectionGroup`, priority 100. It contains an Allow
network collection for Log Analytics private-endpoint HTTPS, Microsoft Entra ID HTTPS,
Key Vault HTTPS, Azure Resource Manager HTTPS, conditional AD DS TCP/UDP ports, and
conditional KMS traffic; it also contains a conditional Windows Update application
rule. The source currently contains two built-in rules with the same name
`Allow-KV-TCP`. Supplying any non-empty `customFirewallRuleCollectionGroups` array
replaces this entire built-in group; it does not merge mission rules into it. A tactical
guide must therefore require the mission ruleset to preserve every still-required
platform flow as well as approved PPSM flows.

The command-line deployment guide lists all three parameters, but the Portal UI emits
none of them. Generated `src/mlz.json` contains the modes, custom array, default-group
selection, and nested resource properties. Verify the deployed Firewall Policy SKU,
IDPS mode, threat-intelligence mode, and complete effective collection groups; then run
approved and blocked traffic tests and review IDPS/threat-intelligence logs. Move to
`Deny` only after mission tuning, allowlist review, and false-positive testing.

#### Log Analytics, Flow Logs, Traffic Analytics, and Sentinel

| Root parameter | Type/default/accepted values | Dependencies, affected resources, and surfaces |
| --- | --- | --- |
| `logAnalyticsWorkspaceRetentionInDays` | `int`, default `30`; no root min/max decorator | `mlz.bicep` -> `monitoring.bicep` -> `log-analytics-workspace.bicep` -> workspace `properties.retentionInDays`. If `deploySentinel=true` and the requested value is below 90, source sets the effective value to 90. The service also limits retention by pricing plan. The CLI guide lists the parameter; Portal UI does not emit it. |
| `networkWatcherFlowLogsRetentionDays` | `int`, default `30`; no root min/max decorator | `mlz.bicep` -> `diagnostic-settings.bicep` -> NSG or VNet diagnostic wrapper -> `network-watcher-flow-logs.bicep` -> flow-log `properties.retentionPolicy.days`; `enabled` is always true. Portal UI emits it and constrains text input to 0-365; this UI constraint is not a root-template constraint. The CLI guide lists it. |
| `deployNetworkWatcherTrafficAnalytics` | `bool`, default `false` | Same diagnostics path -> flow-log `properties.flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration`. When true, `enabled` and `workspaceResourceId` are populated; when false, both are null. Portal UI and the CLI guide expose it. |
| `deploySentinel` | `bool`, default `false` | `mlz.bicep` -> `monitoring.bicep` -> `log-analytics-workspace.bicep`; conditionally creates the `SecurityInsights` Operations Management solution and `Microsoft.SecurityInsights/onboardingStates/default`, and changes the retention expression described above. Portal UI emits it. Enabling does not configure connectors, analytics rules, automation, incidents, or operating procedures. |

No universal retention value follows from IL5 alone. Select workspace and flow-log
values from the records schedule, selected controls, incident-response and investigation
needs, protected-log design, service constraints, capacity, and cost. Verify the
deployed workspace retention, any table-level overrides, flow-log retention policy,
storage lifecycle settings, actual oldest/newest searchable records, and traffic-
analytics linkage/results when enabled.

#### Defender for Cloud Parameter Path

| Root parameter | Type/default/accepted values | Current path and effect |
| --- | --- | --- |
| `deployDefender` | `bool`, source default `true` | `mlz.bicep` -> `security.bicep`; conditionally invokes `defender-for-cloud.bicep` for each tier subscription. The root description incorrectly says the default is false, and the CLI guide also says false. Portal UI does not emit this parameter and therefore relies on the actual root default `true`. |
| `defenderSkuTier` | `string`, default `Free`; `@allowed`: `Standard`, `Free` | `security.bicep` -> each selected `Microsoft.Security/pricings` resource's `properties.pricingTier`. Portal UI emits `Standard` when its paid-feature checkbox is checked, otherwise `Free`. |
| `deployDefenderPlans` | `array`, default `['VirtualMachines']`; no root `@allowed` because array values are not enforced | Becomes the names of `Microsoft.Security/pricings` resources. Portal UI currently offers `CloudPosture`, `VirtualMachines`, `Api`, `AppServices`, `Arm`, `CosmosDbs`, `KeyVaults`, `OpenSourceRelationalDatabases`, `SqlServerVirtualMachines`, `SqlServers`, `StorageAccounts`, and `Containers`. Validity and availability remain cloud/service facts. |
| `emailSecurityContact` | `string`, default empty; no root format decorator | When non-empty, creates `Microsoft.Security/securityContacts/default` with alert notifications on and the listed account roles notified. Portal UI requires an email only when its paid-feature checkbox is selected and applies an email regex. An empty CLI value creates no contact. |

For `Free`, the module writes the pricing tier for every selected plan in all clouds. For
`Standard` outside `AzureCloud`, including Azure Government, it writes the tier but no
subplan or extensions. Commercial Azure has a separate subplan/extension map. The module
also assigns Microsoft Cloud Security Benchmark at subscription scope with
`enforcementMode: DoNotEnforce` whenever Defender is invoked.

The IL5 profile is therefore an existing-parameter operation: preserve
`deployDefender=true`, set `defenderSkuTier='Standard'`, select plans based on resources
and mission risk, and supply the approved monitored contact. Verify each target
subscription's effective pricing plan, tier, subplan/extensions if applicable, coverage,
recommendations, alert delivery, contact routing, current Azure Government availability,
and cost. The contradictory default descriptions and guide text are unresolved source
documentation defects; the executable default is `true`.

#### Azure Policy

`deployPolicy` is `bool`, defaults `false`, and gates one call to
`src/modules/policy-assignment.bicep` for every tier resource group.
`policy` is `string`, defaults `NISTRev4`, and accepts `NISTRev4`, `NISTRev5`, `IL5`, or
`CMMC`. Both appear in the CLI guide and Portal UI; the Portal policy control is visible
only when policy deployment is checked. `docs/policies.md` also gives a command-line
example.

The path is `src/mlz.bicep` -> `src/modules/security.bicep` ->
`src/modules/policy-assignment.bicep`. `IL5` selects built-in initiative ID
`f9a961fa-3241-4b20-adc4-bbf8ad9d7197`, merges the repository IL5 parameter JSON with
the Log Analytics workspace ID and local-administrator membership, and creates the main
assignment, VM and VMSS monitoring-agent assignments, supporting role assignments, and
workspace reader role. Commercial `AzureCloud` silently changes an IL5 request to
`NISTRev4`. `security.bicep` hard-codes `deployRemediation: false`, so the remediation
resource is not created.

For the Azure Government profile, set `deployPolicy=true` and `policy='IL5'`. Before
deployment, resolve the initiative by ID in the target tenant and review its current
definitions and parameters. After deployment, verify assignment identity and scope for
every tier resource group, supporting roles, exceptions, compliance results, agent
assignments, and the mission's finding/repair process. Policy output is partial evidence,
not an authorization result.

#### Bastion

`deployBastion` is `bool`, defaults `false`, and appears in both CLI and Portal inputs.
The path spans two root call sites:

1. `mlz.bicep` -> `networking.bicep` -> `hub-network.bicep` conditionally adds the
  `AzureBastionSubnet` and a dedicated NSG with the service's required inbound/outbound
  rules.
2. `mlz.bicep` -> `remote-access.bicep` -> `bastion-host.bicep` conditionally creates a
  Standard public IP and `Microsoft.Network/bastionHosts`; `diagnostic-settings.bicep`
  adds Bastion, public-IP, and NSG diagnostics/flow logs.

The Portal also emits `bastionHostSubnetAddressPrefix`; the root default is
`10.0.128.192/26`. Enabling Bastion does not itself enable Linux or Windows jumpboxes;
those use separate `deployLinuxVirtualMachine` and `deployWindowsVirtualMachine`
parameters despite CLI-guide wording that says Bastion provisions jumpboxes. Verify
the host, subnet, dedicated NSG, public IP, diagnostics, approved administrative path,
and that unapproved direct management paths are blocked. MFA/CAC, Conditional Access,
privileged access, and session-review controls remain outside MLZ.

#### Identity Tier and Active Directory Domain Services

`deployIdentity` and `deployActiveDirectoryDomainServices` are `bool` and both default
`false`. The root AD DS module condition is
`deployActiveDirectoryDomainServices && deployIdentity`; setting AD DS true without the
identity tier creates no domain controllers. Both are available in CLI/Portal surfaces,
and `docs/active-directory-domain-services.md` contains command-line and conceptual
parameter-file examples.

When both are true, `mlz.bicep` passes the AD DS domain, credentials, image, size, and
network values to `active-directory-domain-services.bicep`. That module creates an
identity resource group, CMK path, updates Firewall DNS to the two controller IPs,
creates an availability set, and invokes `domain-controller.bicep` twice. Each controller
then invokes `virtual-machine.bicep`, followed by the domain-promotion run command.
Root companion parameters are:

- `addsDomainName`, `addsAdministratorUsername`, `addsAdministratorPassword`, and
  `addsSafeModeAdminPassword`: string inputs defaulting empty; the two passwords are
  secure, but the template does not impose a non-empty root constraint.
- `addsVmImageSku`: string default `2019-datacenter-gensecond`, allowed
  `2019-datacenter-core-g2`, `2019-datacenter-gensecond`,
  `2022-datacenter-core-g2`, or `2022-datacenter-g2`.
- `addsVmSize`: free-form string default `Standard_D2s_v3`.

The dedicated AD DS page contains stale examples: its table states a different VM-size
default and does not list every required administrator input. The Portal does collect
the domain, safe-mode password, VM administrator credentials, image, and size when AD DS
is selected. Verify two VM/resource IDs, directory and DNS health, replication,
authentication, firewall DNS/rules, encryption, monitoring extensions, and recovery.
MFA/CAC integration, account lifecycle, privileged access, hardening, backup, and
identity governance are mission/identity-team work rather than effects of these flags.

### Proposed Template Gap: Log Analytics Public Ingestion and Query

**Current fact**: `src/modules/log-analytics-workspace.bicep` hard-codes
`publicNetworkAccessForIngestion: 'Enabled'` and
`publicNetworkAccessForQuery: 'Enabled'`. MLZ also creates an Azure Monitor Private Link
Scope, associates the workspace, creates a private endpoint in the operations subnet,
and links the monitor/OMS/ODS/agent service/blob private DNS zones. There is no current
root/module/UI parameter for either public-access property.

**Proposed smallest file-level surface**:

1. In `src/mlz.bicep`, add two strings such as
  `logAnalyticsWorkspacePublicNetworkAccessForIngestion` and
  `logAnalyticsWorkspacePublicNetworkAccessForQuery`, each limited to `Enabled` and
  `Disabled` and defaulted to `Enabled` for backward compatibility.
2. Forward both through the existing `monitoring` module call.
3. Add matching parameters in `src/modules/monitoring.bicep`, forward them to
  `log-analytics-workspace.bicep`, and replace the two hard-coded workspace properties
  there. No new resource or output is required; the existing workspace and private-link
  outputs remain sufficient.
4. Add explicit Portal controls and output bindings in `src/mlz.uiDefinition.json` if
  Portal users must select the IL5 posture. Document both parameters in the CLI and
  Portal deployment guides. If the intended product posture is to expose them only to
  parameter-file/CLI users, record that decision rather than silently omitting UI
  support.
5. Rebuild and commit generated `src/mlz.json` from `src/mlz.bicep` with the repository's
  pinned Bicep version.

The schema for `Microsoft.OperationalInsights/workspaces@2021-06-01` confirms
`Enabled` and `Disabled` for both properties. Defaulting to `Enabled` preserves existing
deployments; the IL5 parameter profile would explicitly choose `Disabled` after private
paths are proven. Validation must compile Bicep, confirm generated JSON is synchronized,
run default and disabled what-if/deployments, inspect both workspace properties and the
private-link association, resolve every private DNS name from approved networks, send
representative agent/platform ingestion, execute authorized queries privately, and
prove public ingestion/query attempts fail. Deployment agents and break-glass operating
paths must be included in the test design.

Unresolved facts are whether Portal exposure is required for the first change, which
specific ingestion/query clients require approved private connectivity, and whether any
mission table-level retention or data-export design changes the operational test set.

### Proposed Template Gap: Azure Dedicated Host Placement

**Current fact**: no `Microsoft.Compute/hostGroups`, child host resource, host ID
parameter, or VM `properties.host` assignment exists. Persistent jumpbox and domain-
controller VMs use `src/modules/virtual-machine.bicep`; domain controllers also receive
an availability-set ID. `src/modules/customer-managed-keys.bicep` separately creates a
temporary CMK helper VM in the hub and in each optional VM workload path, then invokes a
run command intended to delete it. That helper is still compute that must be considered
in a physical-separation design.

**Proposed smallest complete file-level surface**:

1. Add root enable/configuration inputs in `src/mlz.bicep` for dedicated placement,
  including mission-selected host SKU/family, fault-domain/zone choices, and enough
  topology to cover the hub and optional identity VM paths. Do not assign timeless
  defaults to host SKU, zone, capacity, or quota. A Boolean opt-in should default false
  to preserve current behavior; required host inputs should be validated when enabled.
2. Add a focused module, for example `src/modules/dedicated-host.bicep`, owning
  `Microsoft.Compute/hostGroups` and `Microsoft.Compute/hostGroups/hosts`. The current
  schema requires host-group `platformFaultDomainCount`; supports optional
  `supportAutomaticPlacement`; and requires child-host `sku.name`. Output host resource
  IDs for placement.
3. Invoke the host module at the nearest subscription/resource-group ownership point
  that can cover hub and identity VMs, then forward the relevant host ID through
  `storage.bicep`, `remote-access.bicep`,
  `active-directory-domain-services.bicep`, `domain-controller.bicep`, and
  `customer-managed-keys.bicep` as applicable. Add an optional `dedicatedHostResourceId`
  parameter to `virtual-machine.bicep` and set VM `properties.host.id` only when non-empty.
  The separate helper VM declaration in `customer-managed-keys.bicep` needs the same
  conditional host property; changing only the common VM module is incomplete.
4. Decide whether host IDs need root outputs for inventory/evidence consumers. They are
  not required merely to establish deployment dependencies, so omit new outputs unless
  an evidence or downstream deployment consumer is identified.
5. Add Portal controls/output bindings and deployment-guide parameters for every
  supported deployment mode, then rebuild `src/mlz.json`.

Backward compatibility requires no host resources and no VM host property when the new
feature is disabled. Enabling must fail early when required host inputs are absent or a
selected VM size is incompatible. Compile/build checks must include exact generated-ARM
sync. Deployment checks must cover what-if and creation in each supported subscription,
host-group/host IDs, VM-to-host placement for persistent and helper VMs, helper-VM
deletion, fault-domain behavior, capacity, quota, zone and region compatibility, failure
and replacement behavior, and teardown ordering.

Unresolved design facts require live Azure Government validation before implementation:

- The current Dedicated Host family/SKU compatible with each selected VM size, its
  capacity, quota, PA scope, and availability in the chosen wider-MAG region.
- Whether one host topology may place all relevant cross-resource-group workloads or
  separate hub/identity hosts are required by platform constraints or mission boundary.
- Whether current AD DS availability-set placement can coexist with explicit host
  placement; if not, the enabled path must replace rather than combine those models.
- Whether the temporary helper VM is permitted as designed or should be eliminated in
  favor of a non-VM key-provisioning mechanism in a later design.
- The required fault-domain count, zone strategy, host auto-replacement setting,
  licensing choice, capacity reserve, and recovery procedure.

For new IL5 deployments, preserve Microsoft's guidance to prioritize wider MAG regions
US Gov Arizona, Texas, or Virginia for service and feature availability, and apply the
required compute-isolation design there.

### Outside-MLZ Checklist Research

The following categories are ready to turn into checklist items. `Owner` names the
party that must be assigned for a deployment, not a universal organization chart.
`Prerequisite` is the input needed before action. `Handoff` identifies the boundary at
which MLZ-generated facts become mission or authorizing-organization work.

| Category | Owner | Prerequisite | Action and handoff | Evidence |
| --- | --- | --- | --- | --- |
| Sentinel when used | Mission security operations/SIEM owner, with platform team | Approved SIEM architecture, data sources, region/service availability, retention and incident requirements | Decide whether `deploySentinel=true`; after MLZ onboards the workspace, configure connectors, content/analytics rules, watchlists, automation, roles, alert routing, incident workflow, and operating coverage. Hand the workspace/onboarding IDs and ingestion validation to SOC operations. | Effective onboarding state; connector health; rule and automation inventory; representative alert-to-incident test; role review; retention result; operating procedure and response record. |
| Protected-log lifecycle and recovery | Records owner, system owner, security operations, and storage/platform team | Records schedule, selected controls, legal/mission holds, data classification, recovery objectives, threat model, and cost constraints | Define workspace/table/storage retention, immutability or change protection where required, deletion approval, archive/copy, access, monitoring, and recovery. Hand MLZ workspace/storage IDs and diagnostic destinations to the records and operations processes. | Approved schedule; deployed retention/lifecycle/immutability settings; access review; deletion/hold test; protected copy inventory; restore/query test with timestamps and results. |
| CMK governance | Mission key-management owner and platform/security teams | Data inventory, encryption boundary, HSM/FIPS and PA requirements, separation-of-duties model, recovery objectives | Assign key owners/custodians, limit roles, define creation/activation/rotation/expiration/revocation/deletion/recovery, protect backups, and confirm every data-bearing service uses the intended key before data is written. Hand MLZ vault/key/identity/DES IDs to the key-management process. | Key and version IDs; resource key associations; RBAC review; rotation/revocation/recovery test; purge-protection/soft-delete state; helper-VM removal evidence; exception/risk record. |
| VM hardening, patching, and endpoint protection | Workload/OS owner with security operations | Approved OS baseline/STIG, maintenance policy, endpoint-protection standard, vulnerability and exception processes | Apply and continuously assess the baseline; configure patching, antimalware/EDR, application control, time/DNS, local accounts, secure administration, and extension/agent health. Hand deployed VM/image/extension IDs to operations. | Baseline scan; patch level and maintenance history; endpoint onboarding/health; vulnerability findings and closure; local/privileged account review; exception approvals; alert test. |
| MFA/CAC and identity governance | Tenant identity owner and mission account-management owner | Approved authenticator, federation/PKI design, account/role model, break-glass design, and access-review cadence | Configure MFA or CAC as required, Conditional Access, privileged identity management, access reviews, service-identity lifecycle, emergency access, joiner/mover/leaver actions, and session review. Hand Bastion and AD DS access paths plus MLZ identities/roles to tenant governance. | Authentication and Conditional Access test; privileged activation/review records; account and service-principal inventory; emergency-access test; access-review decisions; session evidence. |
| Backup and recovery | System/data owner and continuity/recovery team | Business impact analysis, recovery objectives, protected-item inventory, retention schedule, encryption and region strategy | Select and configure backup/recovery services outside core MLZ, protect required VMs/data/configuration/keys, isolate backup administration, monitor jobs, and exercise restoration and continuity procedures. | Vault/policy/protected-item inventory; encryption/RBAC settings; successful jobs; restore and failover exercise results; measured recovery objectives; corrective actions. |
| PPSM and network validation | Mission network owner, PPSM authority, and security engineering | Approved PPSM registration/baseline, architecture/data-flow diagrams, endpoints, dependencies, and test plan | Translate approved flows into all four NSG arrays and the complete Firewall collection set; preserve required Azure/MLZ service flows; validate routes, DNS, private endpoints, IDPS and threat-intelligence behavior; hand effective configuration to PPSM/configuration control. | Approved PPSM artifact; parameter values; effective NSG/firewall exports; route/DNS/private-link checks; allowed/blocked packet or connection tests; Firewall/flow-log evidence; exceptions. |
| Vulnerability management | Mission vulnerability-management owner and asset/workload owners | Authorized scanners/sources, credential and network access, asset inventory, severity/SLA and exception process | Scan infrastructure, OS, identity, and applications; ingest Defender and other findings; deduplicate, assign, remediate or formally accept, rescan, and trend. Hand MLZ resource inventory and Defender coverage to the program. | Coverage and scan records; findings register; ownership/SLA status; remediation commits/change records; rescans; exception/risk acceptances; trend reports. |
| Incident response | Mission incident-response owner, SOC, system owner, and external reporting authorities | Incident plan, categorization/reporting thresholds, contacts, telemetry sources, evidence-handling and exercise plan | Integrate MLZ telemetry with detection and case workflows; define triage, containment, eradication, recovery, reporting, evidence preservation, and lessons learned; exercise representative scenarios. | Approved plan/contact roster; alert and escalation tests; exercise/incident timeline; preserved evidence chain; communications; recovery validation; after-action corrections. |
| SSP, evidence, assessment, and authorization | System owner, control owners, assessor, ISSM/security management, and authorizing organization | Defined authorization boundary, categorization, selected/tailored controls, inherited/shared responsibility statements, assessment and authorization strategy | Document how the complete system implements controls; collect Microsoft/inherited, MLZ, mission, and external evidence; assess effectiveness; track POA&M/risk; submit the package for the designated authorization decision. Hand this mapping only as traceability input, never as proof of compliance. | SSP/control implementation statements; boundary/data-flow diagrams; evidence index; assessment plan/report; findings/POA&M; risk responses; authorization decision and terms; continuous-monitoring strategy. |
| Dynamic Azure Government region, PA, quota, and service checks | Cloud/platform owner with system owner and authorizing organization | Intended region, architecture, service/SKU/host-family list, expected capacity, tenant/subscriptions, and planned deployment date | Prefer wider MAG for new deployments per current Microsoft service/feature guidance; resolve every service against current IL5 PA/audit scope and products-by-region; confirm policy/Defender/Sentinel features, Dedicated Host family, VM-size compatibility, quota/capacity, and deployment permissions. Recheck before deployment and on material change. | Dated source links/screenshots or exports; target-tenant initiative lookup; provider/SKU availability result; quota approval; what-if/deployment result; PA/service-scope review record; approved exception or redesign. |

### Tactical-Guide Unresolved Facts

The guide must carry these as explicit checks rather than filling them with assumptions:

1. Current CC SRG and DoDI 8510.01 revision/change metadata and any precise cited
  sections remain reviewer-open as described in the source register.
2. IL5 initiative ID availability and suitability in the target Azure Government tenant
  remain unverified; the review context was commercial Azure.
3. Retention periods, PPSM rules, Defender plans, contact addresses, authentication
  mechanisms, recovery objectives, and evidence cadence are mission-derived.
4. Current Azure Government support and behavior for each Defender plan/subplan,
  Sentinel feature, Log Analytics private client path, and selected service/SKU must be
  checked at deployment time.
5. Dedicated Host topology, family/SKU, VM-size compatibility, capacity, quota, zone,
  fault domains, availability-set interaction, recovery, and helper-VM treatment need a
  design validated in the target wider-MAG region.
6. Source/documentation inconsistencies remain: `deployDefender` executes with default
  `true` despite false-default text; Portal does not emit that Boolean; the AD DS page
  gives a stale VM-size default and incomplete required inputs; the CLI guide implies
  Bastion also provisions jumpboxes; and the built-in Firewall rules duplicate the
  `Allow-KV-TCP` name. A tactical guide should report current executable behavior and
  avoid silently normalizing these discrepancies.

None of these checks changes the authorization boundary: MLZ supplies technical
capabilities and evidence inputs, while the mission and authorizing organization retain
control selection, assessment, risk response, and authorization responsibility.

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
| [Department of Defense in Azure Government](https://learn.microsoft.com/azure/azure-government/documentation-government-overview-dod) | Page reviewed 2026-08-25 | Microsoft recommends US Gov regions for new IL5 deployments to gain the latest cloud innovations and additional services. | Availability and PA scope vary by region and over time. |
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
capability. Use US Gov Arizona, Texas, or Virginia for new MLZ deployments. Microsoft
recommends US Gov regions for new IL5 deployments to gain the latest cloud innovations
and additional services. Dedicated Host support is Absent. Validate current service
scope, host-family availability, quota, and region at deployment time.

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
Host for the single VMs MLZ deploys. Do not publish a static host-SKU list as timeless
fact. Record the validation date and link to current Dedicated Host families,
products-by-region, and IL5 PA audit scope.

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
  validation date. Confirm the document names only US Gov Arizona, Texas, or Virginia
  for new deployments.

These checks are required evidence for the documentation implementation; none permits
the document to claim authorization.
