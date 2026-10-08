# Tactical Changes for an IL5 Mission Landing Zone

<!-- markdownlint-disable MD013 -->

[**Home**](../README.md) | [**IL5 RMF Mapping**](./il5-rmf-resource-mapping.md)

## Table of Contents

- [Purpose and Boundary](#purpose-and-boundary)
  - [Audience](#audience)
  - [Scope and Exclusions](#scope-and-exclusions)
- [How to Use This Guide](#how-to-use-this-guide)
- [Current and Proposed Behavior](#current-and-proposed-behavior)
  - [Key Terms](#key-terms)
- [Predeployment Decisions](#predeployment-decisions)
- [Parameter Changes](#parameter-changes)
  - [Network Security Group and PPSM Rules](#network-security-group-and-ppsm-rules)
  - [Azure Firewall Modes and Rules](#azure-firewall-modes-and-rules)
  - [Logging, Retention, Traffic Analytics, and Sentinel](#logging-retention-traffic-analytics-and-sentinel)
  - [Microsoft Defender for Cloud](#microsoft-defender-for-cloud)
  - [Azure Policy IL5 Initiative](#azure-policy-il5-initiative)
  - [Azure Bastion](#azure-bastion)
  - [Active Directory Domain Services](#active-directory-domain-services)
- [Planned vNext Features](#planned-vnext-features)
  - [Disable Public Log Analytics Ingestion and Query](#disable-public-log-analytics-ingestion-and-query)
  - [Add Azure Dedicated Host Placement](#add-azure-dedicated-host-placement)
- [Work Outside MLZ](#work-outside-mlz)
  - [Operate Logs and Sentinel](#operate-logs-and-sentinel)
  - [Govern Customer-Managed Keys](#govern-customer-managed-keys)
  - [Operate and Protect Virtual Machines](#operate-and-protect-virtual-machines)
  - [Operate Identity and Administrative Access](#operate-identity-and-administrative-access)
  - [Provide Backup and Recovery](#provide-backup-and-recovery)
  - [Maintain PPSM and Validate Network Flows](#maintain-ppsm-and-validate-network-flows)
  - [Perform Vulnerability Management and Incident Response](#perform-vulnerability-management-and-incident-response)
  - [Complete Data, Application, and RMF Work](#complete-data-application-and-rmf-work)
- [Maintenance](#maintenance)
- [References](#references)

## Purpose and Boundary

This guide turns the changes in the [MLZ IL5 RMF mapping](./il5-rmf-resource-mapping.md)
into steps that an implementation team can follow. It covers:

- Existing MLZ parameters to set for an IL5 deployment.
- Planned vNext features for the core MLZ templates.
- Security and authorization work performed outside MLZ.

This document does not implement the planned vNext features. It does not make MLZ,
a workload, or a mission system IL5 compliant or authorized. The mission owner and
Authorizing Official (AO) decide the control set, accept risk, and grant or deny an
authorization to operate (ATO).

### Audience

This guide is for mission owners, cloud platform engineers, security engineers,
operations teams, control owners, assessors, and authorization staff.

### Scope and Exclusions

The source baseline is the core deployment graph that starts at
[`src/mlz.bicep`](../src/mlz.bicep) and uses reachable modules under
[`src/modules/`](../src/modules/). This guide excludes add-ons, mission applications,
and unreferenced modules. Generated [`src/mlz.json`](../src/mlz.json) is an output to
rebuild after a future template change, not the source of current behavior.

The reviewed guide baseline is MLZ commit
`113fb08211bffe603b20c44668df6a756ae80821`, dated 2026-08-25. Its executable MLZ
defaults and paths match the earlier source baseline,
`168474463215f99620531bfdeb47039bf7bd250a`.

## How to Use This Guide

Complete the sections in this order:

1. Make the predeployment decisions.
2. Prepare the MLZ parameter values.
3. Review the two planned vNext features and account for the current gaps.
4. Deploy and verify MLZ.
5. Complete and maintain the work outside MLZ.

Each change lists the files or owner, current state, steps, and verification. Values such
as retention periods, network rules, Defender plans, host stock keeping units (SKUs),
and recovery objectives must come from mission requirements. This guide does not invent
them.

## Current and Proposed Behavior

Sections labeled **Parameter Changes** describe settings that already exist in MLZ.
Teams apply those values through an approved deployment input without changing MLZ
source defaults. **Planned vNext Features** identify current gaps and link to their
feature requests. Sections under **Work Outside MLZ** belong to the named mission,
platform, security, operations, assessment, or authorization owner.

Azure resources and MLZ settings provide capabilities and evidence. They do not by
themselves satisfy a control. Each party keeps its assigned duties. Those parties are
Microsoft, the MLZ team, mission teams, and outside groups. Duties may be inherited,
shared, system-specific, part of MLZ, or external.

### Key Terms

- **AO:** The Authorizing Official decides if the system may operate.
- **ATO:** An authorization to operate is the AO's formal decision.
- **Control:** A safeguard used to reduce risk.
- **Evidence:** A record that helps show whether a control works.
- **IL5:** DoD Impact Level 5 for controlled unclassified information.
- **Inherited control:** A control supplied by another system or organization.
- **MAG:** Microsoft Azure Government.
- **PA:** A Provisional Authorization covers a stated cloud service and scope.
- **PPSM:** Ports, Protocols, and Services Management records approved network flows.
- **RMF:** The Risk Management Framework guides security and risk decisions.
- **SIEM:** A security information and event management service collects and reviews
  security events.
- **SSP:** A system security plan explains how the system addresses its controls.
- **STIG:** A Security Technical Implementation Guide defines a system baseline.
- **What-if:** An Azure check that previews a deployment before it runs.

## Predeployment Decisions

**Owner:** Mission system owner, cloud platform team, security team, and AO staff.

**Current state:** Azure service coverage, policy availability, quota, and capacity can
change. MLZ cannot select mission values or make authorization decisions.

**Steps:**

- [ ] Select US Gov Arizona, Texas, or Virginia for new deployments.
  [Microsoft recommends prioritizing US Gov regions for IL5
  workloads](https://learn.microsoft.com/azure/azure-government/documentation-government-overview-dod)
  because they provide the latest cloud innovations and additional services.
- [ ] Confirm every planned Azure service is in the current IL5 Provisional
  Authorization (PA) scope for the selected region.
- [ ] Confirm the target tenant contains the required Azure Policy initiative.
- [ ] Confirm required Defender and Sentinel features are available in the target
  Azure Government region.
- [ ] If VMs will be deployed in a wider Microsoft Azure Government (MAG) region,
  confirm Dedicated Host family, VM-size compatibility, quota, capacity, and zone
  support.
- [ ] Approve the mission network flows and Ports, Protocols, and Services Management
  (PPSM) record.
- [ ] Approve the rules for logs, data, keys, identity, backup, and recovery.
- [ ] Approve the plans for vulnerability management and incident response.

**Verify and retain:** Record the review date, source links, selected region, PA service
list, policy lookup, SKU and quota results, approved architecture, and approved mission
requirements.

## Parameter Changes

Core MLZ does not include a deployment-specific `.bicepparam` or parameter JSON file.
For command-line or template-spec deployments, update the mission's deployment parameter
file or command invocation. For Portal deployments, use the fields exposed by
[`src/mlz.uiDefinition.json`](../src/mlz.uiDefinition.json). Do not change defaults in
[`src/mlz.bicep`](../src/mlz.bicep) merely to configure one deployment.

### Network Security Group and PPSM Rules

**Change:** Supply the approved rules for each deployed network tier.

**Files:** Parameters are declared in [`src/mlz.bicep`](../src/mlz.bicep), forwarded by
[`src/modules/networking.bicep`](../src/modules/networking.bicep),
[`src/modules/hub-network.bicep`](../src/modules/hub-network.bicep), and
[`src/modules/spoke-network.bicep`](../src/modules/spoke-network.bicep), and applied by
[`src/modules/network-security-group.bicep`](../src/modules/network-security-group.bicep).
Set the values in the mission deployment parameter file or command invocation. The
Portal UI does not expose these arrays.

**Current state:** These arrays default to empty:

- `hubNetworkSecurityGroupRules`
- `operationsNetworkSecurityGroupRules`
- `sharedServicesNetworkSecurityGroupRules`
- `identityNetworkSecurityGroupRules`

The identity rules apply only when `deployIdentity=true`.

**Steps:**

- [ ] Translate the approved PPSM and data-flow records into Azure NSG rule objects.
- [ ] Set all three always-deployed rule arrays in the mission deployment input.
- [ ] Set `identityNetworkSecurityGroupRules` when the identity tier is enabled.
- [ ] Check priorities, source and destination prefixes, ports, protocols, direction,
  and access for conflicts.
- [ ] Deploy through the mission's approved change process.

**Verify and retain:** Export effective NSG rules for each subnet and network interface.
Test representative allowed and blocked paths. Retain the parameter input, effective-rule
exports, route results, and test results with the approved PPSM record.

### Azure Firewall Modes and Rules

**Change:** After tuning, use prevention modes and replace sample rules with the complete
approved ruleset.

**Files:** Parameters are declared in [`src/mlz.bicep`](../src/mlz.bicep) and consumed
through [`src/modules/networking.bicep`](../src/modules/networking.bicep),
[`src/modules/hub-network.bicep`](../src/modules/hub-network.bicep),
[`src/modules/firewall.bicep`](../src/modules/firewall.bicep), and
[`src/modules/firewall-rules.bicep`](../src/modules/firewall-rules.bicep). Set values in
the mission deployment parameter file or command invocation. The Portal UI does not
expose these settings.

**Current state:** `firewallSkuTier` defaults to `Premium`.
`firewallIntrusionDetectionMode` and `firewallThreatIntelMode` default to `Alert`.
`customFirewallRuleCollectionGroups` defaults to an empty array, which causes MLZ to use
its built-in rule group. A non-empty custom array replaces the entire built-in group; it
does not merge with it. The built-in group currently contains two rules named
`Allow-KV-TCP`.

**Steps:**

- [ ] Confirm the deployed Firewall Policy uses the Premium tier.
- [ ] Run IDPS and threat-intelligence monitoring in `Alert` while tuning signatures,
  allowlists, and false positives.
- [ ] Build a complete `customFirewallRuleCollectionGroups` value from the approved
  PPSM rules and every required Azure and MLZ platform flow.
- [ ] Review the duplicate built-in `Allow-KV-TCP` names when translating required
  built-in flows into the replacement ruleset.
- [ ] Set `firewallIntrusionDetectionMode='Deny'` after tuning is approved.
- [ ] Set `firewallThreatIntelMode='Deny'` after tuning is approved.
- [ ] Set `customFirewallRuleCollectionGroups` to the approved complete collection.
- [ ] Deploy through the approved change process.

**Verify and retain:** Export the effective Firewall Policy and rule collection groups.
Test approved and denied traffic. Confirm IDPS and threat-intelligence events reach the
monitoring system. Retain the deployed parameter values, policy export, tuning record,
and traffic-test results.

### Logging, Retention, Traffic Analytics, and Sentinel

**Change:** Set the approved log retention. Enable traffic analytics when required.
Enable Sentinel when it is the selected security information and event management
(SIEM) service.

**Files:** Parameters are declared in [`src/mlz.bicep`](../src/mlz.bicep). Monitoring
values flow through [`src/modules/monitoring.bicep`](../src/modules/monitoring.bicep) and
[`src/modules/log-analytics-workspace.bicep`](../src/modules/log-analytics-workspace.bicep).
Flow-log values flow through
[`src/modules/diagnostic-settings.bicep`](../src/modules/diagnostic-settings.bicep),
[`src/modules/network-security-group-diagnostic-setting.bicep`](../src/modules/network-security-group-diagnostic-setting.bicep),
[`src/modules/virtual-network-diagnostic-setting.bicep`](../src/modules/virtual-network-diagnostic-setting.bicep),
and
[`src/modules/network-watcher-flow-logs.bicep`](../src/modules/network-watcher-flow-logs.bicep).
Set values in the mission deployment input. The Portal exposes flow-log retention,
traffic analytics, and Sentinel, but not Log Analytics workspace retention.

**Current state:**

- `logAnalyticsWorkspaceRetentionInDays` defaults to `30`. When
  `deploySentinel=true`, MLZ uses at least 90 days.
- `networkWatcherFlowLogsRetentionDays` defaults to `30`.
- `deployNetworkWatcherTrafficAnalytics` defaults to `false`.
- `deploySentinel` defaults to `false`. Enabling it onboards the workspace but does not
  configure connectors, analytics rules, automation, or operating procedures.

**Steps:**

- [ ] Obtain the approved workspace and flow-log retention periods from the records,
  incident-response, and investigation requirements.
- [ ] Set `logAnalyticsWorkspaceRetentionInDays` in the mission deployment input.
- [ ] Set `networkWatcherFlowLogsRetentionDays` in the mission deployment input.
- [ ] Set `deployNetworkWatcherTrafficAnalytics=true` only when the monitoring design
  requires it.
- [ ] Set `deploySentinel=true` only when Sentinel is the selected mission SIEM.
- [ ] Deploy through the approved change process.
- [ ] When Sentinel is enabled, complete the outside-MLZ Sentinel steps later in this
  guide.

**Verify and retain:** Confirm effective workspace and table retention, flow-log
retention, traffic-analytics linkage when enabled, and oldest and newest searchable
records. Confirm Sentinel onboarding when selected. Retain parameter values, deployed
settings, ingestion checks, and query results.

### Microsoft Defender for Cloud

**Change:** Use Standard, select plans for deployed workloads, and set the monitored
security contact.

**Files:** Parameters are declared in [`src/mlz.bicep`](../src/mlz.bicep), forwarded by
[`src/modules/security.bicep`](../src/modules/security.bicep), and applied by
[`src/modules/defender-for-cloud.bicep`](../src/modules/defender-for-cloud.bicep). Set
values in the mission deployment parameter file or command invocation. The Portal emits
the tier, plan array, and contact when its paid-feature option is selected.

**Current state:** The executable default for `deployDefender` is `true`, although its
description and the command-line guide say `false`. `defenderSkuTier` defaults to
`Free`, `deployDefenderPlans` defaults to `['VirtualMachines']`, and
`emailSecurityContact` defaults to empty. The module assigns Microsoft Cloud Security
Benchmark with `enforcementMode: 'DoNotEnforce'`.

**Steps:**

- [ ] Confirm `deployDefender=true` in the effective deployment input.
- [ ] Identify the Defender plans needed for the resources in each target subscription.
- [ ] Confirm those plans and their behavior are available in Azure Government.
- [ ] Set `defenderSkuTier='Standard'`.
- [ ] Set `deployDefenderPlans` to the approved plan list.
- [ ] Set `emailSecurityContact` to the approved monitored address.
- [ ] Review cost and alert-routing effects before deployment.
- [ ] Deploy through the approved change process.

**Verify and retain:** Check the pricing tier and plans in each target subscription.
Check coverage, recommendations, and security contact routing. Test one alert. Retain
the input values, plan list, alert result, and exceptions.

### Azure Policy IL5 Initiative

**Change:** Enable policy deployment and select the Azure Government IL5 initiative.

**Files:** `deployPolicy` and `policy` are declared in
[`src/mlz.bicep`](../src/mlz.bicep), forwarded by
[`src/modules/security.bicep`](../src/modules/security.bicep), and applied by
[`src/modules/policy-assignment.bicep`](../src/modules/policy-assignment.bicep). The IL5
parameter values are in
[`src/policies/IL5-policyAssignmentParameters.json`](../src/policies/IL5-policyAssignmentParameters.json).
Set deployment values in the mission input or Portal UI.

**Current state:** `deployPolicy` defaults to `false`; `policy` defaults to `NISTRev4`.
Selecting `IL5` uses initiative ID `f9a961fa-3241-4b20-adc4-bbf8ad9d7197`. MLZ does not
deploy automatic remediation because `deployRemediation` is hard-coded to `false`.
Commercial Azure changes an IL5 selection to NIST Rev. 4, so this profile must be used in
Azure Government.

**Steps:**

- [ ] Resolve the IL5 initiative ID in the target Azure Government tenant.
- [ ] Review the initiative definitions and parameters against the mission baseline.
- [ ] Set `deployPolicy=true`.
- [ ] Set `policy='IL5'`.
- [ ] Review the repository IL5 parameter JSON and approve any mission-specific changes
  through a separate implementation change.
- [ ] Deploy through the approved change process.

**Verify and retain:** Confirm policy assignments and their managed identities. Check
roles and scope across the tier resource groups. Check monitoring-agent assignments,
exceptions, and policy results. Retain the initiative lookup, deployment input,
assignment export, findings, and repair records. Policy results are evidence inputs, not
an authorization decision.

### Azure Bastion

**Change:** Enable Bastion when it is the approved administrative access path.

**Files:** `deployBastion` and `bastionHostSubnetAddressPrefix` are declared in
[`src/mlz.bicep`](../src/mlz.bicep). They flow through
[`src/modules/networking.bicep`](../src/modules/networking.bicep),
[`src/modules/hub-network.bicep`](../src/modules/hub-network.bicep),
[`src/modules/remote-access.bicep`](../src/modules/remote-access.bicep), and
[`src/modules/bastion-host.bicep`](../src/modules/bastion-host.bicep). Set them in the
mission deployment input or Portal UI.

**Current state:** `deployBastion` defaults to `false` and the subnet prefix defaults to
`10.0.128.192/26`. Bastion creates its host, subnet and network security group, public
IP, and diagnostics. It does not enable Linux or Windows jumpboxes; those use separate
parameters.

**Steps:**

- [ ] Confirm the administration design selects Bastion and approves its public IP.
- [ ] Confirm the subnet prefix fits the approved hub address plan.
- [ ] Set `deployBastion=true` and set `bastionHostSubnetAddressPrefix` when the default
  does not match the approved plan.
- [ ] Decide separately whether Linux or Windows jumpboxes are required.
- [ ] Deploy through the approved change process.

**Verify and retain:** Confirm the Bastion host, subnet, NSG, public IP, diagnostics, and
approved connection path. Test that unapproved direct management paths are blocked.
Retain deployed settings, connection results, and access-control evidence.

### Active Directory Domain Services

**Change:** Enable the identity tier and Active Directory Domain Services (AD DS) only
when required by the mission identity design.

**Files:** Parameters are declared in [`src/mlz.bicep`](../src/mlz.bicep). The primary
consumers are [`src/modules/networking.bicep`](../src/modules/networking.bicep),
[`src/modules/active-directory-domain-services.bicep`](../src/modules/active-directory-domain-services.bicep),
[`src/modules/domain-controller.bicep`](../src/modules/domain-controller.bicep),
[`src/modules/virtual-machine.bicep`](../src/modules/virtual-machine.bicep), and
[`src/modules/firewall-rules.bicep`](../src/modules/firewall-rules.bicep). Set values in
the mission deployment input or Portal UI.

**Current state:** `deployIdentity` and `deployActiveDirectoryDomainServices` default to
`false`. Both must be true or no domain controllers are created. The companion
parameters and executable defaults are:

- `addsDomainName=''`
- `addsAdministratorUsername=''`
- `addsAdministratorPassword=''` as a secure parameter
- `addsSafeModeAdminPassword=''` as a secure parameter
- `addsVmImageSku='2019-datacenter-gensecond'`
- `addsVmSize='Standard_D2s_v3'`
- `identitySubscriptionId=subscription().subscriptionId`
- `identityVirtualNetworkAddressPrefix='10.0.130.0/24'`
- `identitySubnetAddressPrefix='10.0.130.0/24'`
- `identityNetworkSecurityGroupRules=[]`

The AD DS guide contains stale or incomplete default and input information; use
executable source as the baseline.

**Steps:**

- [ ] Confirm AD DS is required and define the approved domain, DNS, account, image,
  sizing, network, backup, and recovery design.
- [ ] Set `deployIdentity=true` and `deployActiveDirectoryDomainServices=true`.
- [ ] Set every required companion input. Supply passwords through an approved secret
  mechanism; do not store secrets in source control.
- [ ] Review the Firewall DNS and conditional AD DS rule effects.
- [ ] Confirm the proposed Dedicated Host design before deploying these VMs in wider
  MAG for IL5.
- [ ] Deploy through the approved change process.

**Verify and retain:** Confirm two domain-controller VMs, DNS configuration, replication,
and authentication. Check encryption, monitoring, Firewall updates, backup, and restore.
Retain the non-secret deployment input and secret-source reference. Keep the health
checks, account review, and recovery result.

## Planned vNext Features

The following capabilities are not available in core MLZ today. Their engineering work
is tracked in the linked feature requests.

### Disable Public Log Analytics Ingestion and Query

**Change:** Add parameters that allow public ingestion and query to be disabled after all
required private paths work.

**Feature request:**
[#1304: Add configurable private-only Log Analytics access](https://github.com/Azure/missionlz/issues/1304)

**Current state:** The workspace module hard-codes
`publicNetworkAccessForIngestion: 'Enabled'` and
`publicNetworkAccessForQuery: 'Enabled'`. MLZ already deploys Azure Monitor Private Link,
a private endpoint, and related private DNS zones.

**Customer action:** Keep public workspace access enabled unless the mission has an
approved alternative. Track #1304 and plan to adopt the capability after it is released
and the mission has tested every required private ingestion and query path.

**Expected result:** After the feature is released and enabled, authorized clients use
private paths and public ingestion and query are blocked.

### Add Azure Dedicated Host Placement

**Change:** Add host groups, Dedicated Hosts, and VM host placement for MLZ VMs deployed
in US Gov Arizona, Texas, or Virginia when required for IL5 isolation.

**Feature request:**
[#1305: Add Azure Dedicated Host placement for core MLZ VMs](https://github.com/Azure/missionlz/issues/1305)

**Current state:** Core MLZ has no host group, Dedicated Host, host ID parameter, or VM
`properties.host` assignment. Persistent management and domain-controller VMs use the
common VM module. Temporary customer-managed-key helper VMs are declared separately and
must also be included in the isolation design.

**Customer action:** Track #1305. Before adopting the capability, confirm current host
availability, VM-size compatibility, quota, capacity, zone support, and IL5 scope in the
selected region. Do not deploy MLZ VMs for an IL5 workload until the approved physical
separation design is available.

**Expected result:** After the feature is released and enabled, all core MLZ VMs,
including temporary helper VMs, use the approved Dedicated Host placement.

## Work Outside MLZ

### Operate Logs and Sentinel

**Change:** Establish the protected-log lifecycle and, when selected, configure and
operate Sentinel beyond the workspace onboarding that MLZ provides.

**Owner:** Mission records owner, security operations center (SOC), SIEM owner, and
platform team.

**Current state:** MLZ routes platform and flow logs and can onboard its workspace to
Sentinel. It does not define the mission records schedule, full storage lifecycle,
Sentinel connectors, analytics, automation, incident workflow, or operating coverage.

**Steps:**

- [ ] Approve workspace, table, flow-log, and storage retention from mission and records
  requirements.
- [ ] Configure lifecycle, immutability or change protection, deletion approval, legal
  holds, archive or protected copies, access, and recovery where required.
- [ ] If Sentinel is used, configure connectors, analytics rules, automation, roles,
  watchlists, alert routing, incident workflow, and operating coverage.
- [ ] Test log ingestion, query, alert-to-incident flow, deletion protection, and recovery.

**Expected result:** Required logs remain available and protected for the approved
period, can be recovered, and reach an operated detection and response process.

**Verify and retain:** Keep the approved schedule, deployed settings, connector and rule
inventory, access review, alert test, oldest/newest record checks, and recovery result.

### Govern Customer-Managed Keys

**Change:** Establish the roles and lifecycle controls needed to operate MLZ-created
customer-managed keys.

**Owner:** Mission key-management owner with platform and security teams.

**Current state:** MLZ creates customer-managed-key resources, identities, roles, private
endpoints, and disk encryption sets. Resource deployment alone does not define mission
key governance.

**Steps:**

- [ ] Define the encryption boundary, hardware and certification requirements,
  separation of duties, and recovery requirements.
- [ ] Assign key owners and custodians and limit their roles.
- [ ] Define how keys are made and enabled.
- [ ] Define how keys rotate, expire, and are revoked or deleted.
- [ ] Define how keys are backed up and recovered.
- [ ] Confirm each data-bearing service uses the intended key before mission data is
  written.
- [ ] Confirm the temporary helper VM is removed after key setup.
- [ ] Test key rotation and revocation.
- [ ] Test key recovery.

**Expected result:** Every in-scope resource uses its approved key, and authorized staff
can rotate, revoke, and recover keys without bypassing separation of duties.

**Verify and retain:** Keep key and version IDs and their resource links. Keep role
reviews and key test results. Keep soft-delete and purge-protection settings. Keep proof
that the helper VM was removed and record approved exceptions.

### Operate and Protect Virtual Machines

**Change:** Apply and continuously operate the approved VM security baseline.

**Owner:** Workload or operating-system owner with security operations.

**Current state:** MLZ deploys monitoring and security extensions and supports encrypted
VM disks. It does not apply a mission operating-system baseline, run the patch program,
or operate endpoint protection.

**Steps:**

- [ ] Apply the approved operating-system baseline or Security Technical Implementation
  Guide (STIG).
- [ ] Configure patching, endpoint detection and response, antimalware, application
  control, time, DNS, local accounts, and secure administration.
- [ ] Monitor extensions and agents for health.
- [ ] Scan for vulnerabilities, assign findings, remediate or accept risk, and rescan.
- [ ] Review privileged and local accounts on the required cadence.

**Expected result:** Deployed VMs remain hardened, patched, monitored, and protected,
with findings corrected or formally accepted.

**Verify and retain:** Keep baseline scans, patch history, endpoint onboarding and health,
vulnerability and rescan results, account reviews, approved exceptions, and alert tests.

### Operate Identity and Administrative Access

**Change:** Apply the mission login rules to MLZ identities. Apply account and privileged
access rules to each admin path.

**Owner:** Tenant identity owner and mission account-management owner.

**Current state:** MLZ can deploy Bastion and AD DS. It does not configure tenant
multi-factor authentication (MFA) or Common Access Card (CAC) authentication. It also
does not set Conditional Access, privileged identity management, access reviews,
emergency accounts, or session review.

**Steps:**

- [ ] Approve the authenticator, federation or public key infrastructure design, account
  model, role model, emergency-access design, and review cadence.
- [ ] Configure MFA or CAC as required and apply Conditional Access.
- [ ] Configure privileged access, time-bound activation, and role review.
- [ ] Define how accounts are added, changed, and removed.
- [ ] Define service identity and emergency account steps.
- [ ] Connect AD DS to the approved identity services and operating procedures when AD
  DS is deployed.
- [ ] Configure and review administrative sessions through the approved access path.
- [ ] Test normal, privileged, denied, and emergency access.

**Expected result:** Only approved identities can use mission resources and privileged
paths, and emergency access remains controlled and testable.

**Verify and retain:** Keep login and access-policy results. Keep privileged activation
and review records. Keep account lists, emergency-access tests, and session records.

### Provide Backup and Recovery

**Change:** Deploy and operate backup and recovery capabilities for all required mission
resources and configuration.

**Owner:** System and data owners with the continuity and recovery team.

**Current state:** Core MLZ has no backup vault, backup policy, protected item, or restore
workflow.

**Steps:**

- [ ] Complete the business impact analysis and approve recovery objectives.
- [ ] Identify every VM, data store, configuration, key, and other item that needs
  protection.
- [ ] Select and configure the backup and recovery services outside core MLZ.
- [ ] Set backup retention and encryption from the approved rules.
- [ ] Separate backup access, monitor jobs, and use the approved region.
- [ ] Monitor backup jobs and correct failures.
- [ ] Test a restore.
- [ ] Test the continuity plan.

**Expected result:** Protected items can be restored within the mission's approved
recovery objectives.

**Verify and retain:** Keep the protected-item inventory, policies, encryption and access
settings, successful jobs, restore and failover results, measured recovery results, and
corrective actions.

### Maintain PPSM and Validate Network Flows

**Change:** Keep the deployed network controls aligned with approved PPSM records and
verified data flows.

**Owner:** Mission network owner, PPSM authority, and security engineering.

**Current state:** MLZ provides configurable NSGs, routes, private endpoints, and
Firewall rules. It does not approve mission flows or maintain PPSM registration.

**Steps:**

- [ ] Maintain the approved PPSM registration and architecture and data-flow diagrams.
- [ ] Give the approved flows to the team preparing NSG and Firewall parameters.
- [ ] Preserve required Azure and MLZ platform flows in the complete ruleset.
- [ ] Validate routes, DNS, private endpoints, and effective NSG and Firewall rules.
- [ ] Test representative allowed and denied connections after each material change.

**Expected result:** Effective network controls allow approved flows, block tested
unapproved flows, and remain traceable to the current PPSM record.

**Verify and retain:** Keep the approved PPSM artifact, deployed parameter values,
effective-rule exports, route and DNS checks, traffic tests, logs, and exceptions.

### Perform Vulnerability Management and Incident Response

**Change:** Run repeatable vulnerability scans and incident response. Use the MLZ
inventory, findings, and logs as inputs.

**Owner:** The mission vulnerability and incident-response owners, SOC, system owner,
and required reporting authorities.

**Current state:** MLZ provides resource inventory, Defender findings, logs, and optional
Sentinel onboarding. It does not operate vulnerability or incident-response programs.

**Steps:**

- [ ] Approve each scan source and its access.
- [ ] Define severity, repair, reporting, evidence, and exception rules.
- [ ] Scan the cloud resources and operating systems.
- [ ] Scan identities and applications.
- [ ] Combine Defender and other findings, remove duplicates, assign owners, remediate
  or formally accept risk, rescan, and trend results.
- [ ] Connect MLZ telemetry to detection and case workflows.
- [ ] Define how the team will review, contain, remove, and recover from threats.
- [ ] Define reporting, evidence handling, and lessons-learned steps.
- [ ] Exercise these steps with a realistic event.

**Expected result:** Findings and incidents have accountable owners, timely actions,
verified closure or risk decisions, and preserved evidence.

**Verify and retain:** Keep coverage reports, findings, owners, due dates, and rescans.
Keep risk decisions and trend reports. For incidents, keep the timeline, evidence,
messages, recovery checks, and after-action fixes.

### Complete Data, Application, and RMF Work

**Change:** Complete the mission-owned data, application, assessment, risk, and
authorization work that infrastructure deployment cannot perform.

**Owner:** System owner, data owner, application owners, control owners, assessor,
security management, and AO.

**Current state:** MLZ does not classify mission data, implement workload application
controls, produce a system security plan (SSP), assess controls, accept risk, or issue an
ATO.

**Steps:**

- [ ] Define the authorization boundary and data flows.
- [ ] Categorize and classify mission data and approve its handling rules.
- [ ] Select and tailor NIST SP 800-53 Revision 5 controls for the system.
- [ ] Implement and test application, data, and operational controls outside MLZ.
- [ ] State who owns each inherited, shared, system, and external control.
- [ ] Write the SSP and collect Microsoft, MLZ, mission, and external evidence.
- [ ] Assess control effectiveness and record findings.
- [ ] Track plans of action and milestones, risk responses, and accepted risk.
- [ ] Submit the authorization package to the designated AO.
- [ ] Keep monitoring the system after the AO makes a decision.

**Expected result:** The AO receives a complete package that has been assessed. It shows
the known risk and includes an active monitoring plan.

**Verify and retain:** Keep the SSP, boundary, data-flow diagrams, and data decisions.
Keep the evidence index, assessment plan, report, and findings. Keep plans of action and
milestones, risk decisions, the AO decision and terms, and monitoring records.

## Maintenance

Review this guide when MLZ parameters or resources change. Review it when Microsoft,
NIST, or DoD guidance changes. Review it when the mission changes its design, region,
data, identity plan, or authorization boundary.

## References

- [MLZ IL5 RMF resource mapping](./il5-rmf-resource-mapping.md)
- [DoD Cloud Computing Security Requirements Guide library](https://www.cyber.mil/dccs/dccs-documents/) - Cloud Service Provider SRG Version 1, Release 7, dated 30 June 2026.
- [DoDI 8510.01, Risk Management Framework for DoD Systems](https://www.esd.whs.mil/Portals/54/Documents/DD/issuances/dodi/851001p.pdf) - published 12 March 2014 and incorporating Change 3, effective 19 July 2022.
- [CNSSI 1253, Security Categorization and Control Selection for National Security Systems](https://www.dcsa.mil/Portals/91/Documents/CTP/NAO/CNSSI_No1253.pdf) - 27 March 2014.
- [Department of Defense in Azure Government](https://learn.microsoft.com/azure/azure-government/documentation-government-overview-dod)
- [Isolation guidelines for Impact Level 5 workloads](https://learn.microsoft.com/azure/azure-government/documentation-government-impact-level-5)
- [Department of Defense Impact Level 5](https://learn.microsoft.com/azure/compliance/offerings/offering-dod-il5)
- [NIST SP 800-53 Revision 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)
- [NIST SP 800-37 Revision 2](https://csrc.nist.gov/pubs/sp/800/37/r2/final)
