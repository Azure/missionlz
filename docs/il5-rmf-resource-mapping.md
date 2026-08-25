# Mission Landing Zone Resources and IL5 Risk Management Framework Relationships

<!-- markdownlint-disable MD013 -->

[**Home**](../README.md) | [**Design**](./design.md) | [**SCCA**](./scca.md) | [**Resources**](./resources.md)

## Document Status

This document shows what the core Mission Landing Zone (MLZ) deploys, how those
resources support an Impact Level 5 (IL5) system, and what must change for an IL5
deployment. It is for mission owners, engineers, and security reviewers.

MLZ is a general-purpose, SCCA-compliant, opinionated landing zone model. It supports
several security environments, so its default settings are not all IL5 settings. This
document identifies the IL5 changes.

### Reviewed Baseline

| Baseline item | Reviewed value |
| --- | --- |
| MLZ revision | `168474463215f99620531bfdeb47039bf7bd250a` |
| Review date | 2026-08-24 |
| Included MLZ resources | Resources deployed by `src/mlz.bicep` and its modules under `src/modules/` |
| Cloud | Azure Government |
| RMF process | NIST SP 800-37 Revision 2 |
| Control catalog | NIST SP 800-53 Revision 5 |
| DoD guidance | DoDI 8510.01 and the DoD Cloud Computing Security Requirements Guide (SRG) |
| Azure guidance | Microsoft IL5 guidance and February 2026 service-scope list, reviewed 2026-08-24 |

Automated checks could not confirm the current SRG revision or open the DoDI 8510.01
and CNSSI 1253 PDFs. Before use, record the dates shown in those official documents.
The Azure Government policy initiative must also be checked in the target tenant. The
review environment was connected to commercial Azure, not Azure Government.

## Scope and Method

The inventory starts at [`src/mlz.bicep`](../src/mlz.bicep) and follows the modules it
uses under [`src/modules/`](../src/modules/). Resources are grouped by purpose. The
inventory does not include:

- Everything under `src/add-ons/`.
- Unreachable modules, examples, tests, and generated `src/mlz.json` content.
- Resources that MLZ uses but does not create.
- Mission applications or the full set of documents needed for authorization.

The RMF column lists NIST SP 800-53 Revision 5 controls that each capability supports.
Codes such as AC-4 and SC-7 identify security controls; the letters identify the control
family. This is not a complete control mapping.

### Terms

| Term | Meaning |
| --- | --- |
| **Default** | MLZ deploys it unless you turn it off. |
| **Optional** | MLZ deploys it only when you turn it on. |
| **Absent** | Core MLZ does not deploy it. |
| **Parameter change** | Change an existing MLZ setting. |
| **Template change** | Change the MLZ Bicep code. |
| **Outside MLZ** | The mission or another organization must provide it. |
| **Deployment check** | Check a value that can change by tenant, region, or deployment. |
| **Authorizing organization** | The officials who review risk and decide whether the system may operate. |

Technical abbreviations used below:

- **CMK**: customer-managed encryption key.
- **IDPS**: intrusion detection and prevention system.
- **NSG**: network security group.
- **PA**: DoD Provisional Authorization for an Azure service offering.
- **PPSM**: the mission's approved ports, protocols, and services list.
- **SIEM**: security information and event management system.

> [!IMPORTANT]
> MLZ is only one part of an IL5 system. Deploying it does not make the system IL5
> compliant or grant an Authorization to Operate. The mission owner must select the
> controls, test the complete system, fix or accept risks, and obtain approval. Azure's
> PA covers only the Azure services listed in that PA. Azure Policy and Defender provide
> useful findings, but those findings are not an authorization decision. Work may belong
> to Microsoft, the MLZ team, the mission, another organization, or be shared.

## What to Keep in Mind for IL5

The detailed table explains each resource. At the deployment level, these are the main
IL5 considerations:

1. **Use wider MAG.** [Microsoft recommends prioritizing US Gov regions for IL5
  workloads](https://learn.microsoft.com/azure/azure-government/documentation-government-overview-dod):
  choose US Gov Arizona, Texas, or Virginia for new deployments to benefit from the
  latest cloud innovations, and consider migrating existing US DoD region deployments
  to gain additional services. Use only services covered by the current IL5 PA. US DoD
  Central and East remain exclusive-use DoD regions; this recommendation is based on
  service and feature availability, not their lifecycle status.
2. **Provide physical separation for VMs in MAG regions.** Microsoft Azure Government
  (MAG) regions US Gov Arizona, Texas, and Virginia serve DoD customers and approved
  non-DoD government customers: State, Local, Tribal, and Federal Civilian (FedCiv).
  For IL5 physical separation, MLZ's single VMs must use Azure Dedicated Host in these
  regions. Core MLZ does not deploy Dedicated Host, so this requires a template change.
3. **Keep the customer in control of encryption keys.** Confirm that every service that
  stores IL5 data uses the required customer-managed keys and that the mission controls
  key access, rotation, recovery, and separation of duties.
4. **Replace general network defaults with the mission rules.** Add the approved PPSM
  rules to each network tier. After testing, set Firewall IDPS and threat intelligence
  to `Deny`. Test both allowed and blocked traffic.
5. **Protect and retain the logs.** Set log retention from mission requirements. Add MLZ
  settings to turn off public Log Analytics ingestion and query, then test all private
  access paths. Confirm required logs arrive and alerts work.
6. **Turn on the IL5 security settings.** Enable the Azure Government IL5 Policy
  initiative. Use Defender Standard, select plans for the deployed workloads, and set
  the security contact. Check the policy initiative and Defender plans in the target
  Azure Government tenant.
7. **Plan for work outside MLZ.** Backup and recovery, tenant identity governance,
  vulnerability management, incident response, system documentation, testing, and the
  authorization decision are mission or organizational responsibilities.

## Core Capability Mapping

The inventory contains 78 Bicep resource declarations across 35 Azure resource types.
Each deployed resource is counted once. Resources marked **Absent** were not found in
`src/mlz.bicep` or the modules it uses.

| Capability | State | Resources and current behavior | Security purpose | RMF | IL5 change | Owner and check |
| --- | --- | --- | --- | --- | --- | --- |
| Core resource groups | Default | [`resourceGroup`](../src/modules/resource-group.bicep) creates groups for the hub, operations, shared services, and Network Watcher. | Organizes resources and supports inventory. | CM-8; CA-7 | No MLZ change. | Mission: compare the deployed groups, tags, and owners with the system design. |
| Optional resource groups | Optional | [`active-directory-domain-services.bicep`](../src/modules/active-directory-domain-services.bicep) and [`remote-access.bicep`](../src/modules/remote-access.bicep) create groups when identity or management VMs are enabled. | Organizes optional workloads. | CM-8; CA-7 | No MLZ change. | Mission: check the groups and tags when these workloads are enabled. |
| Network separation and DNS | Default | MLZ creates [NSGs](../src/modules/network-security-group.bicep), [route tables](../src/modules/route-table.bicep), [virtual networks](../src/modules/virtual-network.bicep), [peerings](../src/modules/virtual-network-peering.bicep), [private DNS zones](../src/modules/private-dns-zone.bicep), and [DNS links](../src/modules/virtual-network-link.bicep). NSG rules are empty by default. | Separates network tiers and sends spoke traffic through the hub. | AC-4; SC-7; SC-32 | **Parameter change:** add approved PPSM rules to every deployed tier. | Mission: test routes, DNS, allowed traffic, and blocked traffic. |
| Azure Firewall | Default | [Firewall Premium](../src/modules/firewall.bicep), [firewall rules](../src/modules/firewall-rules.bicep), and public IPs deploy by default. IDPS and threat intelligence start in `Alert` mode. | Filters traffic and reports possible attacks. | SC-7; SI-4 | **Parameter change:** after tuning, set IDPS and threat intelligence to `Deny`. Replace the sample rules with approved PPSM rules. | Shared: test allowed and blocked traffic and review firewall alerts. |
| Monitoring and private access | Default | [Log Analytics](../src/modules/log-analytics-workspace.bicep), [Azure Monitor Private Link](../src/modules/private-link-scope.bicep), and a [private endpoint](../src/modules/private-endpoint.bicep) deploy by default. Retention is 30 days. Public ingestion and query are enabled. Sentinel is off. | Collects security and operations logs. | AU-2; AU-6; AU-12; CA-7; SI-4 | **Parameter change:** set the required retention period. **Template change:** add settings to turn off public ingestion and query. **Outside MLZ:** configure Sentinel if it is the mission SIEM. | MLZ team and mission: test private DNS, log ingestion, queries, retention, and Sentinel incidents when used. |
| Diagnostic settings and flow logs | Default | [Diagnostic settings](../src/modules/diagnostic-settings.bicep) send platform logs to central storage and Log Analytics. [Network flow logs](../src/modules/network-watcher-flow-logs.bicep) retain data for 30 days by default. Traffic analytics is off. | Records platform and network activity. | AU-2; AU-6; AU-11; AU-12; SI-4 | **Parameter change:** set flow-log retention and turn on traffic analytics if the monitoring plan requires it. | Mission: confirm required log types arrive and alerts work. |
| Protected log storage | Default | [Storage accounts](../src/modules/storage-account.bicep) block public and shared-key access, require TLS 1.2, use encryption, and create private endpoints. | Protects stored logs. | AU-9; AU-11; SC-13; SC-28 | No standard parameter change. Define how long logs are kept, when they are deleted, how they are copied and recovered, and whether they may be changed. | Shared: test private access, key use, retention, recovery, and permissions. |
| Customer-managed encryption keys | Default | [`customer-managed-keys.bicep`](../src/modules/customer-managed-keys.bicep) creates a Premium Key Vault, managed identity, role assignments, private endpoint, and a temporary helper VM. Its script creates the key and, for VM workloads, the disk encryption set. The helper VM is then removed. | Gives the customer control of encryption keys. | AC-6; IA-4; SC-12; SC-13; SC-28 | No standard parameter change. Define who controls the keys, how often they rotate, how they are recovered, whether hardware protection is required, and which duties must be assigned to different people. | Shared: check the key, roles, rotation and recovery; confirm the helper VM was removed. |
| Microsoft Defender for Cloud | Default | [`defender-for-cloud.bicep`](../src/modules/defender-for-cloud.bicep) deploys Defender with the Free tier and the Virtual Machines plan. The security benchmark assignment is set to `DoNotEnforce`. | Finds security weaknesses and threats. | CA-7; RA-5; SI-3; SI-4 | **Parameter change:** use the Standard tier, choose plans for the deployed workloads, and set a security contact. | Shared: confirm coverage, alert delivery, recommendations, and Azure Government availability. |
| Azure Policy | Optional | [`policy-assignment.bicep`](../src/modules/policy-assignment.bicep) deploys policy assignments and supporting roles. Policy is off by default and automatic fixes are disabled. | Checks resource settings against selected rules. | CA-2; CA-7; CM-6; CM-7 | **Parameter change:** in Azure Government set `deployPolicy=true` and `policy='IL5'`. | Shared: confirm the built-in IL5 policy initiative, which is a managed set of policy rules, exists in the target Azure Government tenant. Then review its settings, exceptions, results, and repair process. |
| Azure Bastion | Optional | [`bastion-host.bicep`](../src/modules/bastion-host.bicep) creates the host and public IP when `deployBastion=true`. | Provides a managed path for remote administration. | AC-17; SC-7 | **Parameter change:** enable it if the administration design uses Bastion. **Outside MLZ:** apply MFA, Conditional Access, privileged-access controls, and session review. | Mission: test approved access and confirm other paths are blocked. |
| Management and domain-controller VMs | Optional | [`virtual-machine.bicep`](../src/modules/virtual-machine.bicep) creates VMs, network interfaces, and monitoring and security extensions. Management VMs and domain controllers use separate enable settings. | Provides administrative or directory servers with monitoring and encrypted disks. | CM-6; SC-3; SC-28; SI-2; SI-6 | **Template change:** follow the wider-MAG Azure Dedicated Host requirement in the next row. **Outside MLZ:** patch, harden, monitor, and protect the VMs. | Shared: first confirm the region, host availability, quota, and PA coverage. Then check VM encryption, extensions, patching, endpoint protection, and accounts. |
| Active Directory Domain Services | Optional | [`active-directory-domain-services.bicep`](../src/modules/active-directory-domain-services.bicep) deploys two domain controllers when identity and AD DS are enabled. | Provides directory, DNS, authentication, and account services. | AC-2; AC-3; IA-2; IA-4; IA-5 | **Parameter change:** enable only when needed. **Outside MLZ:** configure multi-factor authentication (MFA) or Common Access Card (CAC) authentication, account management, privileged access, backup, hardening, and recovery. | Mission: test directory health, DNS, authentication, accounts, backup, and recovery. |
| Azure Dedicated Host | Absent | No host group, dedicated host, or VM host placement exists in core MLZ. | Provides physical separation for VMs where required. | SC-3; SC-4; SC-39 | **Template change:** add host groups, hosts, and VM placement for US Gov Arizona, Texas, or Virginia. | MLZ team and mission: confirm host family, quota, region, placement, and current Microsoft guidance. |
| Backup and recovery | Absent | Core MLZ has no backup vault, backup policy, protected item, or restore workflow. | Protects data and supports recovery after loss or damage. | CP-9; CP-10 | **Outside MLZ:** provide backup storage, encryption, retention, access controls, monitoring, and restore procedures. | Mission: test restores and keep the results. |
| Identity governance | Absent | Core MLZ does not configure tenant MFA, Conditional Access, privileged identity management, access reviews, or emergency accounts. | Controls user and administrator access over time. | AC-2; AC-6; IA-2; IA-5; IA-12 | **Outside MLZ:** configure these tenant controls and operating procedures. | Mission and identity team: review users, service identities, roles, privileged access, and emergency access. |
| RMF and security operations | Absent | Core MLZ does not produce the system security plan, authorization package, assessor records, or PPSM registration. It also does not perform vulnerability management, incident response, data classification, application controls, or risk decisions. | Provides the management and operating work needed for authorization. | Mission-selected controls across CA, CM, IR, PL, RA, and SI | **Outside MLZ:** complete these activities through the mission's RMF and operations processes. | Mission and authorizing organization: keep plans, procedures, test results, findings, and risk decisions. |

## Deployment Records

Keep these records for each IL5 deployment:

- The exact MLZ revision and parameter file used.
- The Azure Government region and the current list of Azure services covered by the
  IL5 PA.
- Azure Policy and Defender settings, exceptions, findings, and alert tests.
- Firewall, route, NSG, private endpoint, and DNS settings compared with the approved
  network design and PPSM list.
- Proof that required logs arrive, alerts work, and records are kept for the required
  time.
- Encryption keys, permissions, rotation, recovery, and encrypted-resource settings.
- VM host placement, security settings, patches, endpoint protection, and administrator
  access.
- The mission's control descriptions, procedures, test results, open findings, and risk
  decisions.

## Maintenance and Re-Review Triggers

Review this document again when:

- MLZ adds resources or changes defaults.
- NIST, DoD, or CNSS guidance changes.
- Microsoft changes the IL5 PA, isolation guidance, policy initiative, Azure service,
  or Dedicated Host family.
- The mission changes its region, design, data, identity system, or system boundary.

## References

### Requirements and Control Sources

- [DoD Cloud Computing Security Requirements Guide library](https://public.cyber.mil/dccs/dccs-documents/), reviewed 2026-08-24.
- [DoDI 8510.01, Risk Management Framework for DoD Systems](https://www.esd.whs.mil/Portals/54/Documents/DD/issuances/dodi/851001p.pdf), official locator reviewed 2026-08-24.
- [NIST SP 800-37 Revision 2](https://doi.org/10.6028/NIST.SP.800-37r2), December 2018.
- [NIST SP 800-53 Revision 5 control catalog](https://csrc.nist.gov/Projects/risk-management/sp800-53-controls/release-search#/800-53), revision selected 2026-08-24.
- [CNSSI 1253, Security Categorization and Control Selection for National Security Systems](https://www.dcsa.mil/Portals/91/Documents/CTP/NAO/CNSSI_No1253.pdf).

### Azure Government and Service Guidance

- [Department of Defense Impact Level 5](https://learn.microsoft.com/azure/compliance/offerings/offering-dod-il5), reviewed 2026-08-24.
- [Isolation guidelines for Impact Level 5 workloads](https://learn.microsoft.com/azure/azure-government/documentation-government-impact-level-5), reviewed 2026-08-24.
- [Department of Defense in Azure Government](https://learn.microsoft.com/azure/azure-government/documentation-government-overview-dod), reviewed 2026-08-25.
- [Azure Government services by audit scope](https://learn.microsoft.com/azure/azure-government/compliance/azure-services-in-fedramp-auditscope), reviewed 2026-08-24.
- [Shared responsibility in the cloud](https://learn.microsoft.com/azure/security/fundamentals/shared-responsibility), reviewed 2026-08-24.
- [Azure Policy built-ins](https://learn.microsoft.com/azure/governance/policy/samples/), reviewed 2026-08-24.
- [Azure Firewall Premium features](https://learn.microsoft.com/azure/firewall/premium-features) and [threat intelligence settings](https://learn.microsoft.com/azure/firewall-manager/threat-intelligence-settings), reviewed 2026-08-24.
