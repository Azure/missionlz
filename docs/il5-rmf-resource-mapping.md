# Mission Landing Zone Resources and IL5 Risk Management Framework Relationships

<!-- markdownlint-disable MD013 -->

[**Home**](../README.md) | [**Design**](./design.md) | [**SCCA**](./scca.md) | [**Resources**](./resources.md) | [**IL5 Tactical Guide**](./il5-rmf-tactical-guide.md)

## Purpose

Mission Landing Zone (MLZ) deploys Azure resources for Department of Defense (DoD)
Impact Level 5 (IL5) systems. This mapping shows what MLZ provides and what must change.
It links those resources to examples of Risk Management Framework (RMF) security
controls. Setup and test steps are in the [Tactical Guide](./il5-rmf-tactical-guide.md).

### Posture as of 20 October 2026

| Posture item | Value |
| --- | --- |
| MLZ source revision | `168474463215f99620531bfdeb47039bf7bd250a` |
| Included MLZ resources | Resources deployed by `src/mlz.bicep` and its modules under `src/modules/` |
| Cloud | Azure Government |
| RMF process | NIST SP 800-37 Revision 2 |
| Control catalog | NIST SP 800-53 Revision 5 |
| DoD Cloud Computing SRG | Cloud Service Provider SRG, Version 1, Release 7, 30 June 2026 |
| DoDI 8510.01 | Effective 19 July 2022; reissues and cancels the 12 March 2014 instruction, as amended |
| CNSSI 1253 | 27 March 2014 |
| Azure guidance | Microsoft IL5 guidance and February 2026 service-scope list |

## Scope

This mapping covers the resources created by [`src/mlz.bicep`](../src/mlz.bicep) and its
modules in [`src/modules/`](../src/modules/). It excludes:

- Everything under `src/add-ons/`.
- Unused modules, examples, tests, and generated `src/mlz.json` content.
- Resources that MLZ uses but does not create.
- Customer apps and the full set of documents needed for approval to operate.

The RMF column gives examples of NIST SP 800-53 Revision 5 controls, not a full control
list. Codes such as AC-4 identify specific security controls.

### Terms

| Term | Meaning |
| --- | --- |
| **Default** | MLZ deploys it without a setting to turn it on. |
| **Optional** | MLZ deploys it only when you turn it on. |
| **Absent** | Core MLZ does not deploy it. |
| **Parameter change** | Change an existing MLZ setting. |
| **Template change** | Change the MLZ Bicep code. |
| **Outside MLZ** | The customer or another organization must provide it. |
| **Shared** | Microsoft, MLZ, and customer teams share the work. |
| **Authorizing organization** | Officials who review risk and decide if the system may operate. |

Technical abbreviations used below:

- **AD DS**: Active Directory Domain Services.
- **DNS**: domain name system.
- **IDPS**: intrusion detection and prevention system.
- **MAG**: Microsoft Azure Government.
- **NSG**: network security group.
- **PA**: DoD Provisional Authorization for an Azure service offering.
- **PPSM**: Ports, Protocols, and Services Management; the process for approving network
  traffic.
- **SIEM**: security information and event management system.
- **VM**: virtual machine.

> **Important**
>
> Deploying MLZ does not make a system IL5 compliant or grant approval to operate.
> Azure's PA covers only its listed services. Microsoft, MLZ, and customer teams each
> have work to do. Azure Policy and Defender findings do not grant approval to operate.

## What to Keep in Mind for IL5

1. **Region:** [Microsoft recommends US Gov Arizona, Texas, or Virginia for new IL5
  deployments](https://learn.microsoft.com/azure/azure-government/documentation-government-overview-dod).
  These MAG regions serve DoD and approved non-DoD government customers.
2. **VM isolation:** DoD requires IL5 VMs to run on physical hosts that do not run
  non-DoD workloads.
3. **Encryption:** The customer controls the keys used to encrypt IL5 data.
4. **Network controls:** Rules must allow approved PPSM traffic. Firewall protection
  must block detected threats, not just report them.
5. **Logging:** Customer rules set how long logs are kept, who can use them, and how
  they are protected.
6. **Security services:** The IL5 profile uses the IL5 policy rules and Standard
  Defender plans for its workloads.
7. **Customer duties:** The customer manages backups, user access, threats, tests, and
  approval to operate.

## Core Capability Mapping

| Capability | State | Resources and current behavior | Security purpose | RMF | Required change | Owner | Sources |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Core resource groups | Default | [`resource-groups.bicep`](../src/modules/resource-groups.bicep) creates hub, operations, and shared-services network groups. MLZ uses an existing Network Watcher. | Groups resources by purpose. | CM-8; CA-7 | No MLZ change. | Customer | [NIST 800-53]; [DoDI 8510.01] |
| Optional resource groups | Optional | [`resource-groups.bicep`](../src/modules/resource-groups.bicep) adds the identity network group when `deployIdentity=true`. [`active-directory-domain-services.bicep`](../src/modules/active-directory-domain-services.bicep) creates the domain-controller group when identity and AD DS are enabled. [`remote-access.bicep`](../src/modules/remote-access.bicep) creates the jump-box group when Linux or Windows management VMs are enabled. | Organizes optional workloads. | CM-8; CA-7 | No MLZ change. | Customer | [NIST 800-53]; [DoDI 8510.01] |
| Network separation and DNS | Default | MLZ creates [NSGs](../src/modules/network-security-group.bicep), [routes](../src/modules/route-table.bicep), [virtual networks](../src/modules/virtual-network.bicep), [peerings](../src/modules/virtual-network-peering.bicep), [private DNS zones](../src/modules/private-dns-zone.bicep), and [DNS links](../src/modules/virtual-network-link.bicep). NSG rule arrays are empty by default. | Keeps networks separate and routes spoke traffic through the hub. | AC-4; SC-7; SC-32 | **Parameter change:** approved PPSM rules for each network. | Customer | [NIST 800-53]; [CC SRG] |
| Azure Firewall | Default | [Firewall Premium](../src/modules/firewall.bicep), [rule collections](../src/modules/firewall-rules.bicep), and public IPs deploy by default. IDPS and threat intelligence default to `Alert`. | Filters traffic and detects attacks. | SC-7; SI-4 | **Parameter change:** IDPS and threat intelligence in `Deny` mode; approved PPSM rules. | Shared | [NIST 800-53]; [CC SRG]; [Firewall guidance] |
| Monitoring and private access | Default | [Log Analytics](../src/modules/log-analytics-workspace.bicep), [Azure Monitor Private Link](../src/modules/private-link-scope.bicep), and a [private endpoint](../src/modules/private-endpoint.bicep) deploy by default. Logs are kept for 30 days by default. Clients can send logs and run queries over public networks. | Collects logs in one workspace. | AU-2; AU-6; AU-12; CA-7; SI-4 | **Parameter change:** how long logs are kept. **Template change:** private-only workspace access. | MLZ team and customer | [NIST 800-53]; [CC SRG]; [Microsoft IL5] |
| Microsoft Sentinel | Optional | [`log-analytics-workspace.bicep`](../src/modules/log-analytics-workspace.bicep) adds the workspace to Sentinel when `deploySentinel=true`, which defaults to `false`. | Connects the workspace to the SIEM. | AU-6; AU-12; CA-7; IR-4; SI-4 | **Parameter change:** Sentinel enabled when selected. **Outside MLZ:** SIEM setup and daily operations. | Customer | [NIST 800-53]; [CC SRG]; [Microsoft Sentinel] |
| Diagnostic settings and flow logs | Default | [Diagnostic settings](../src/modules/diagnostic-settings.bicep) send platform logs to storage and Log Analytics. [Network flow logs](../src/modules/network-watcher-flow-logs.bicep) keep data for 30 days by default. Traffic analytics is off. | Records platform and network activity. | AU-2; AU-6; AU-11; AU-12; SI-4 | **Parameter change:** how long to keep logs; traffic analytics when needed. | Customer | [NIST 800-53]; [CC SRG] |
| Protected log storage | Default | [Storage accounts](../src/modules/storage-account.bicep) block public and shared-key access, require TLS 1.2, encrypt data, and have private endpoints. | Protects stored logs. | AU-9; AU-11; SC-13; SC-28 | **Outside MLZ:** rules for keeping, deleting, and recovering logs. | Shared | [NIST 800-53]; [CC SRG]; [Microsoft IL5] |
| Customer-managed encryption keys | Default | [`customer-managed-keys.bicep`](../src/modules/customer-managed-keys.bicep) creates a Premium Key Vault, managed identity, roles, private endpoint, and temporary helper VM. The helper creates the key and, for VM workloads, the disk encryption set. The helper VM is then removed. | Gives the customer control of encryption keys. | AC-6; IA-4; SC-12; SC-13; SC-28 | **Outside MLZ:** key owners, rotation, recovery, and separate admin roles. | Shared | [NIST 800-53]; [CC SRG]; [Microsoft IL5] |
| Microsoft Defender for Cloud | Default | [`defender-for-cloud.bicep`](../src/modules/defender-for-cloud.bicep) defaults to the Free tier and Virtual Machines plan. The security benchmark assignment uses `DoNotEnforce`. | Reports weak security settings and workload threats. | CA-7; RA-5; SI-3; SI-4 | **Parameter change:** Standard tier, plans for customer workloads, and security contact. | Shared | [NIST 800-53]; [CC SRG]; [Microsoft IL5] |
| Azure Policy | Optional | [`policy-assignment.bicep`](../src/modules/policy-assignment.bicep) creates assignments and supporting roles. Policy and automatic remediation are off by default. The DoD Impact Level 5 initiative is available in Azure Government. | Checks resource settings against selected rules. | CA-2; CA-7; CM-6; CM-7 | **Parameter change:** IL5 initiative enabled. | Shared | [NIST 800-53]; [Azure Policy]; [Microsoft IL5] |
| Azure Bastion | Optional | [`bastion-host.bicep`](../src/modules/bastion-host.bicep) creates the host and public IP when `deployBastion=true`, which defaults to `false`. | Provides remote admin access. | AC-17; SC-7 | **Parameter change:** Bastion enabled when required. **Outside MLZ:** user and admin access rules. | Customer | [NIST 800-53]; [CC SRG] |
| Management and domain-controller VMs | Optional | [`virtual-machine.bicep`](../src/modules/virtual-machine.bicep) creates VMs, network interfaces, and monitoring and security extensions. It installs agents but does not set up guest-log collection. Management VMs require `deployLinuxVirtualMachine=true` or `deployWindowsVirtualMachine=true`; domain controllers require identity and AD DS enabled. | Runs admin and directory VMs with encrypted disks and monitoring agents. | CM-6; SC-3; SC-28; SI-2; SI-6 | **Outside MLZ:** guest logs, secure VM settings, patches, and endpoint protection. | Shared | [NIST 800-53]; [CC SRG]; [IL5 isolation] |
| Active Directory Domain Services | Optional | [`active-directory-domain-services.bicep`](../src/modules/active-directory-domain-services.bicep) deploys domain controllers only when both `deployIdentity=true` and `deployActiveDirectoryDomainServices=true`. | Provides directory, DNS, and authentication services. | AC-2; AC-3; IA-2; IA-4; IA-5 | **Parameter change:** identity and AD DS enabled together when required. **Outside MLZ:** directory operations and recovery. | Customer | [NIST 800-53]; [CC SRG] |
| Azure Dedicated Host placement | Absent | Core MLZ does not deploy host groups or Dedicated Hosts or assign VMs to hosts. | Keeps IL5 VMs on hosts that do not run non-DoD workloads. | SC-3; SC-4; SC-39 | **Template change:** Dedicated Host placement for MLZ VMs. | MLZ team and customer | [NIST 800-53]; [CC SRG]; [IL5 isolation] |
| Backup and recovery | Absent | Core MLZ has no backup vault, backup policy, protected item, or restore workflow. | Supports recovery after loss or damage. | CP-9; CP-10 | **Outside MLZ:** customer backup and recovery. | Customer | [NIST 800-53]; [CC SRG] |
| Identity governance | Absent | Core MLZ does not manage user accounts or login rules. Multi-factor authentication, Conditional Access, admin role controls, access reviews, and emergency accounts are set up outside MLZ. | Controls user and admin access. | AC-2; AC-6; IA-2; IA-5; IA-12 | **Outside MLZ:** user accounts, login rules, and admin access. | Customer and identity team | [NIST 800-53]; [CC SRG] |
| RMF and security operations | Absent | Core MLZ does not write security plans or approval records, assess controls, register PPSM traffic, scan for weaknesses, or respond to incidents. It does not classify data, secure apps, or accept risk. | Supports system approval and daily operations. | Customer-selected controls across CA, CM, IR, PL, RA, and SI | **Outside MLZ:** customer security plans, tests, risk decisions, and operations. | Customer and authorizing organization | [NIST 800-53]; [DoDI 8510.01]; [CNSSI 1253] |

## References

### Requirements and Control Sources

- [DoD Cloud Computing Security Requirements Guide library](https://www.cyber.mil/dccs/dccs-documents/), Cloud Service Provider SRG Version 1, Release 7, dated 30 June 2026.
- [DoDI 8510.01, Risk Management Framework for DoD Systems](https://www.esd.whs.mil/Portals/54/Documents/DD/issuances/dodi/851001p.pdf), effective 19 July 2022; reissues and cancels the 12 March 2014 instruction, as amended.
- [NIST SP 800-37 Revision 2](https://doi.org/10.6028/NIST.SP.800-37r2), December 2018.
- [NIST SP 800-53 Revision 5 control catalog](https://csrc.nist.gov/Projects/risk-management/sp800-53-controls/release-search#/800-53).
- [CNSSI 1253, Security Categorization and Control Selection for National Security Systems](https://www.dcsa.mil/Portals/91/Documents/CTP/NAO/CNSSI_No1253.pdf), 27 March 2014.

### Azure Government and Service Guidance

- [Department of Defense Impact Level 5](https://learn.microsoft.com/azure/compliance/offerings/offering-dod-il5).
- [Isolation guidelines for Impact Level 5 workloads](https://learn.microsoft.com/azure/azure-government/documentation-government-impact-level-5).
- [Department of Defense in Azure Government](https://learn.microsoft.com/azure/azure-government/documentation-government-overview-dod).
- [Azure Government services by audit scope](https://learn.microsoft.com/azure/azure-government/compliance/azure-services-in-fedramp-auditscope).
- [Shared responsibility in the cloud](https://learn.microsoft.com/azure/security/fundamentals/shared-responsibility).
- [Azure Policy built-ins](https://learn.microsoft.com/azure/governance/policy/samples/).
- [Azure Firewall Premium features](https://learn.microsoft.com/azure/firewall/premium-features) and [threat intelligence settings](https://learn.microsoft.com/azure/firewall-manager/threat-intelligence-settings).

[NIST 800-53]: https://csrc.nist.gov/Projects/risk-management/sp800-53-controls/release-search#/800-53
[CC SRG]: https://www.cyber.mil/dccs/dccs-documents/
[DoDI 8510.01]: https://www.esd.whs.mil/Portals/54/Documents/DD/issuances/dodi/851001p.pdf
[CNSSI 1253]: https://www.dcsa.mil/Portals/91/Documents/CTP/NAO/CNSSI_No1253.pdf
[Microsoft IL5]: https://learn.microsoft.com/azure/compliance/offerings/offering-dod-il5
[IL5 isolation]: https://learn.microsoft.com/azure/azure-government/documentation-government-impact-level-5
[Azure Policy]: https://learn.microsoft.com/azure/governance/policy/samples/
[Firewall guidance]: https://learn.microsoft.com/azure/firewall/premium-features
[Microsoft Sentinel]: https://learn.microsoft.com/azure/sentinel/overview
