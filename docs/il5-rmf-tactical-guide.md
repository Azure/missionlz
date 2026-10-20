# Tactical Changes for an IL5 Mission Landing Zone

<!-- markdownlint-disable MD013 -->

[**Home**](../README.md) | [**IL5 RMF Mapping**](./il5-rmf-resource-mapping.md)

## Table of Contents

- [Purpose and Boundary](#purpose-and-boundary)
  - [Scope and Exclusions](#scope-and-exclusions)
- [How to Use This Guide](#how-to-use-this-guide)
- [Key Terms](#key-terms)
- [Predeployment Inputs](#predeployment-inputs)
- [Parameter Changes](#parameter-changes)
  - [Network Security Group and PPSM Rules](#network-security-group-and-ppsm-rules)
  - [Azure Firewall Modes and Rules](#azure-firewall-modes-and-rules)
  - [Logging, Retention, Traffic Analytics, and Sentinel](#logging-retention-traffic-analytics-and-sentinel)
  - [Microsoft Defender for Cloud](#microsoft-defender-for-cloud)
  - [Azure Policy IL5 Initiative](#azure-policy-il5-initiative)
  - [Azure Bastion](#azure-bastion)
  - [Active Directory Domain Services](#active-directory-domain-services)
- [Current Template Limitations](#current-template-limitations)
  - [Public Log Analytics Access Cannot Be Disabled](#public-log-analytics-access-cannot-be-disabled)
  - [Dedicated Host Placement Is Not Available](#dedicated-host-placement-is-not-available)
- [Work Outside MLZ](#work-outside-mlz)
  - [Operate Logs and Sentinel](#operate-logs-and-sentinel)
  - [Govern Customer-Managed Keys](#govern-customer-managed-keys)
  - [Operate and Protect Virtual Machines](#operate-and-protect-virtual-machines)
  - [Operate Identity and Administrative Access](#operate-identity-and-administrative-access)
  - [Provide Backup and Recovery](#provide-backup-and-recovery)
  - [Maintain PPSM and Validate Network Flows](#maintain-ppsm-and-validate-network-flows)
  - [Perform Vulnerability Management and Incident Response](#perform-vulnerability-management-and-incident-response)
  - [Complete Data, Application, and RMF Work](#complete-data-application-and-rmf-work)
- [References](#references)

## Purpose and Boundary

Use this guide to configure and test core Mission Landing Zone (MLZ) for Department
of Defense (DoD) Impact Level 5 (IL5). Use the
[resource mapping](./il5-rmf-resource-mapping.md) to identify the changes required for
your deployment.

> **Important**
>
> This guide does not make a system IL5 compliant or grant approval to operate.
> It documents required changes; it does not implement the proposed template changes.

### Scope and Exclusions

Core [`src/mlz.bicep`](../src/mlz.bicep) and its modules under
[`src/modules/`](../src/modules/). Add-ons, customer applications, and unused modules are
excluded.

## How to Use This Guide

Complete the sections in this order:

1. Collect the predeployment inputs.
2. Prepare the MLZ parameter values.
3. Complete the template changes required for this deployment.
4. Deploy and test MLZ.
5. Complete and maintain the work outside MLZ.

## Key Terms

- **AD DS:** Active Directory Domain Services.
- **AO:** The Authorizing Official decides if the system may operate.
- **CAC:** Common Access Card.
- **DNS:** Domain name system.
- **IDPS:** Intrusion detection and prevention system.
- **MAG:** Microsoft Azure Government.
- **MFA:** Multi-factor authentication.
- **NSG:** A network security group allows or blocks network traffic.
- **PA:** A Provisional Authorization covers a stated cloud service and scope.
- **PPSM:** Ports, Protocols, and Services Management; the process for approving network
  traffic.
- **RMF:** The Risk Management Framework guides security and risk decisions.
- **SIEM:** A security information and event management service collects and reviews
  security events.
- **SKU:** A stock keeping unit identifies a product or service size.
- **SSP:** A system security plan explains how the system addresses its controls.
- **STIG:** A Security Technical Implementation Guide defines a system baseline.
- **VM:** Virtual machine.

## Predeployment Inputs

**Owner:** Customer system owner with cloud, security, and AO staff.

**Steps:**

- [ ] Select US Gov Arizona, Texas, or Virginia for new deployments.
- [ ] Confirm the IL5 PA lists each planned Azure service for the chosen region.
- [ ] Confirm the required Azure Policy initiative exists in the tenant.
- [ ] Confirm required Defender and Sentinel features are available in the target
  Azure Government region.
- [ ] For VMs in these MAG regions, check that Dedicated Hosts support the VM sizes and
  zones. Check the subscription quota and available host capacity.
- [ ] Get the permitted traffic list from the network owner and PPSM record. Include
  source, destination, protocol, ports, direction, and the networks that need each
  connection. Use this list for the [NSG rules](#network-security-group-and-ppsm-rules)
  and [Firewall rules](#azure-firewall-modes-and-rules).
- [ ] Get workspace and flow-log retention periods, in days, from the records owner.
  Use these values in [Logging, Retention, Traffic Analytics, and Sentinel](#logging-retention-traffic-analytics-and-sentinel).

**Verify and retain:** Keep the date, source links, region, PA service list, policy
lookup, SKU and quota results, traffic list, and retention periods.

## Parameter Changes

Set values in the deployment parameter file or command, not the defaults in
[`src/mlz.bicep`](../src/mlz.bicep). When using
[MLZ's deployment form](../src/mlz.uiDefinition.json), use the controls named below.

JSON examples show entries inside the parameter file's `parameters` object.
Replace `<...>` with customer values.

Keep the MLZ version, input values without secrets, and each section's test results.
After deployment, compare resource groups, tags, and owners with the deployment inputs.

### Network Security Group and PPSM Rules

**Steps:**

- [ ] For each connection in the [traffic list](#predeployment-inputs), write an NSG rule
  with the source, destination, ports, protocol, direction, access, and priority.
- [ ] Set `hubNetworkSecurityGroupRules`, `operationsNetworkSecurityGroupRules`, and
  `sharedServicesNetworkSecurityGroupRules` to those rules. Use a parameter file
  or command; MLZ's deployment form has no inputs for these arrays.
  Replace these sample HTTPS rules with each tier's PPSM rules:

  ```json
  {
    "hubNetworkSecurityGroupRules": {
      "value": [{
        "name": "Allow-PPSM-HTTPS",
        "properties": {
          "priority": 100,
          "direction": "Inbound",
          "access": "Allow",
          "protocol": "Tcp",
          "sourceAddressPrefix": "<hub-source-prefix>",
          "sourcePortRange": "*",
          "destinationAddressPrefix": "<hub-destination-prefix>",
          "destinationPortRange": "443"
        }
      }]
    },
    "operationsNetworkSecurityGroupRules": {
      "value": [{
        "name": "Allow-PPSM-HTTPS",
        "properties": {
          "priority": 100,
          "direction": "Inbound",
          "access": "Allow",
          "protocol": "Tcp",
          "sourceAddressPrefix": "<operations-source-prefix>",
          "sourcePortRange": "*",
          "destinationAddressPrefix": "<operations-destination-prefix>",
          "destinationPortRange": "443"
        }
      }]
    },
    "sharedServicesNetworkSecurityGroupRules": {
      "value": [{
        "name": "Allow-PPSM-HTTPS",
        "properties": {
          "priority": 100,
          "direction": "Inbound",
          "access": "Allow",
          "protocol": "Tcp",
          "sourceAddressPrefix": "<shared-services-source-prefix>",
          "sourcePortRange": "*",
          "destinationAddressPrefix": "<shared-services-destination-prefix>",
          "destinationPortRange": "443"
        }
      }]
    }
  }
  ```

- [ ] Set `identityNetworkSecurityGroupRules` when `deployIdentity=true`.

  ```json
  {
    "identityNetworkSecurityGroupRules": {
      "value": [{
        "name": "Allow-PPSM-HTTPS",
        "properties": {
          "priority": 100,
          "direction": "Inbound",
          "access": "Allow",
          "protocol": "Tcp",
          "sourceAddressPrefix": "<identity-source-prefix>",
          "sourcePortRange": "*",
          "destinationAddressPrefix": "<identity-destination-prefix>",
          "destinationPortRange": "443"
        }
      }]
    }
  }
  ```

- [ ] Check rule priorities, source and destination addresses, ports, protocols,
  direction, and allow/deny actions for conflicts.

**Verify and retain:** Export the NSG rules in effect for each subnet and network
interface. Test allowed and blocked traffic. Keep the input values, rule exports,
route checks, and test results with the PPSM record.

### Azure Firewall Modes and Rules

**Steps:**

- [ ] Keep `firewallSkuTier='Premium'`. In MLZ's deployment form, select **Premium**
  under **Firewall SKU**.
- [ ] Run IDPS and threat intelligence in `Alert` mode. Test the connections in the
  [traffic list](#predeployment-inputs) and check for false detections before enabling
  `Deny` mode.
- [ ] Build a complete `customFirewallRuleCollectionGroups` value from the traffic
  list and the connections that Azure and MLZ services need.
  Complete this sample with the required customer, Azure, and MLZ service rules before use:

  ```json
  {
    "customFirewallRuleCollectionGroups": {
      "value": [{
        "name": "MLZ-DefaultCollectionGroup",
        "properties": {
          "priority": 100,
          "ruleCollections": [{
            "name": "PPSM-Network-Rules",
            "priority": 100,
            "ruleCollectionType": "FirewallPolicyFilterRuleCollection",
            "action": { "type": "Allow" },
            "rules": [{
              "name": "Allow-PPSM-HTTPS",
              "ruleType": "NetworkRule",
              "ipProtocols": ["TCP"],
              "sourceAddresses": ["<source-prefix>"],
              "destinationAddresses": ["<destination-prefix>"],
              "destinationPorts": ["443"]
            }]
          }]
        }
      }]
    }
  }
  ```

- [ ] Set `firewallIntrusionDetectionMode='Deny'` after required connections pass the
  traffic tests.
- [ ] Set `firewallThreatIntelMode='Deny'` after required connections pass the traffic
  tests.
- [ ] Set `customFirewallRuleCollectionGroups` to the complete collection built above.
- [ ] Supply the detection modes and custom rule groups through a parameter file or
  command; MLZ's deployment form has no inputs for them.

  ```json
  {
    "firewallIntrusionDetectionMode": { "value": "Deny" },
    "firewallThreatIntelMode": { "value": "Deny" }
  }
  ```

**Verify and retain:** Export the Firewall Policy and rule collection groups in effect.
Confirm Allow rules match the traffic list. Test allowed and blocked traffic.
Confirm IDPS and threat-intelligence events reach the log system.
Keep the input values, policy export, settings review, and traffic-test results.

### Logging, Retention, Traffic Analytics, and Sentinel

**Steps:**

- [ ] Set `logAnalyticsWorkspaceRetentionInDays` to the workspace retention period
  supplied by the records owner in [Predeployment Inputs](#predeployment-inputs).
  Use at least 90 days when Sentinel is enabled. Supply this value through a parameter
  file or command; MLZ's deployment form has no workspace-retention input.
  Example for a 180-day requirement:

  ```json
  {
    "logAnalyticsWorkspaceRetentionInDays": { "value": 180 }
  }
  ```

- [ ] Set `networkWatcherFlowLogsRetentionDays` to the flow-log retention period from
  the same records owner.
  In MLZ's deployment form, use **Retention Days**.
- [ ] If the security operations team needs flow-log traffic analytics, set
  `deployNetworkWatcherTrafficAnalytics=true`. In MLZ's deployment form, select
  **Enable Traffic Analytics**.
- [ ] Set `deploySentinel=true` only when Sentinel is the selected customer SIEM.
  In MLZ's deployment form, select **Enable Microsoft Sentinel?**
- [ ] When Sentinel is enabled, complete [Operate Logs and Sentinel](#operate-logs-and-sentinel).

**Verify and retain:** Check how long workspace tables and flow logs keep data. Check
that traffic analytics is connected when enabled. Query the oldest and newest records.
Confirm the workspace is connected to Sentinel when selected. Keep the input values,
deployed settings, log arrival checks, and query results.

### Microsoft Defender for Cloud

**Steps:**

- [ ] Confirm `deployDefender=true` in the parameter file or command.
  Example for the `VirtualMachines` plan:

  ```json
  {
    "deployDefender": { "value": true },
    "defenderSkuTier": { "value": "Standard" },
    "deployDefenderPlans": { "value": ["VirtualMachines"] },
    "emailSecurityContact": { "value": "<monitored-security-email>" }
  }
  ```

- [ ] Identify the Defender plans needed for the resources in each target subscription.
- [ ] Confirm those plans and their behavior are available in Azure Government.
- [ ] Change `defenderSkuTier` from `Free` to `Standard`.
- [ ] Set `deployDefenderPlans` to the plan IDs selected for those workload types.
- [ ] Set `emailSecurityContact` to the security operations team's monitored address.
- [ ] In MLZ's deployment form, select **Enable additional features for Microsoft
  Defender for Cloud?**, then choose the plans and set the security contact.
- [ ] Review costs and where alerts will be sent before deployment.

**Verify and retain:** Check the pricing tier and plans in each target subscription.
Check which resources are protected and review the findings. Test that an alert reaches
the security contact. Keep the input values, plan list, alert result, and exceptions.

### Azure Policy IL5 Initiative

**Steps:**

- [ ] Use Azure Government for this deployment. Look up IL5 initiative ID
  `f9a961fa-3241-4b20-adc4-bbf8ad9d7197` in the tenant.
- [ ] Check its policy rules and settings against customer requirements.
- [ ] Change `deployPolicy` from `false` to `true` and `policy` from `NISTRev4` to `IL5`.
- [ ] In MLZ's deployment form, select **Create policy assignments?** and choose
  **DoD IL5** under **Policy Assignment**.
- [ ] Open noncompliant resources from the Azure Policy findings. Correct the settings
  identified by each finding, then check the compliance results again.

**Verify and retain:** Check the policy assignments, managed identities, and roles in
each tier resource group. Compare assignment parameters with the
[IL5 parameter JSON](../src/policies/IL5-policyAssignmentParameters.json).
Check which resources the assignments cover. Check agent policy assignments,
exceptions, and results. Keep the initiative lookup, input values, assignment export,
findings, and repair records.

### Azure Bastion

**Steps:**

- [ ] Confirm administrators will connect through Bastion and can reach its public
  endpoint from their administration network.
- [ ] Get an unused subnet prefix in the hub network from the network owner.
- [ ] Change `deployBastion` from `false` to `true` and set
  `bastionHostSubnetAddressPrefix` to that prefix. In MLZ's deployment form,
  select **Deploy Bastion?** and set **Azure Bastion Subnet CIDR Range**.
- [ ] Set `deployLinuxVirtualMachine` or `deployWindowsVirtualMachine` only when the
  platform owner needs standalone management VMs in addition to Bastion.
- [ ] When enabling a management VM through a parameter file or command, supply
  `linuxVmAdminPasswordOrKey` for Linux or `windowsVmAdminPassword` for Windows from a
  secret store. Match the Linux credential to `linuxVmAuthenticationType`
  (`password` or `sshPublicKey`). Do not store credentials in source control.

**Verify and retain:** Check the Bastion host, subnet, NSG, public IP, logs, and selected
connection path. Test that direct admin access is blocked where it is not allowed.
Keep the deployed settings, connection results, and access test results.

### Active Directory Domain Services

**Steps:**

- [ ] When the workload needs AD DS, set `deployIdentity=true` and
  `deployActiveDirectoryDomainServices=true`.
- [ ] In MLZ's deployment form, select **Deploy identity resources?** and
  **Deploy active directory domain services?**
- [ ] Set `addsDomainName` and `addsAdministratorUsername` to the domain name and
  administrator account supplied by the directory owner.
- [ ] Supply `addsAdministratorPassword` and `addsSafeModeAdminPassword` from a
  secret store; do not store them in source control.
- [ ] Set `addsVmImageSku` and `addsVmSize` to an image and size supported by the
  domain-controller software and the selected Dedicated Host.
- [ ] Set `identitySubscriptionId`, `identityVirtualNetworkAddressPrefix`, and
  `identitySubnetAddressPrefix` to the target subscription and network prefixes
  supplied by the network owner.
- [ ] Supply `identityNetworkSecurityGroupRules` through a parameter file or command,
  following [Network Security Group and PPSM Rules](#network-security-group-and-ppsm-rules).
- [ ] Check the Firewall DNS settings and the rules added when AD DS is enabled.
- [ ] Before deploying the domain controllers, complete
  [Dedicated Host placement](#dedicated-host-placement-is-not-available) for both VMs.

**Verify and retain:** Confirm both domain controllers work. Test DNS, directory
replication, and login. Check encryption, logs, Firewall rules, backup, and restore.
Keep the input values without secrets, the secret store reference, health checks,
account review, and recovery result.

## Current Template Limitations

### Public Log Analytics Access Cannot Be Disabled

**Steps:**

- [ ] Preserve MLZ's existing Azure Monitor Private Link Scope, workspace association,
  private endpoint, and private DNS.
- [ ] Test private DNS, guest-log arrival, and queries before disabling public access.
  Complete the [VM guest-log setup](#operate-and-protect-virtual-machines) for agent traffic.
- [ ] Through a template change, set the workspace's
  `publicNetworkAccessForIngestion` and `publicNetworkAccessForQuery` from `Enabled`
  to `Disabled`.

**Verify and retain:** Check private DNS, log arrival, and queries. Confirm public requests
are blocked. Retain workspace settings and test results.

### Dedicated Host Placement Is Not Available

**Steps:**

- [ ] Before deploying IL5 standalone VMs in US Gov Arizona, Texas, or Virginia,
  update the template to place every persistent and temporary VM on Dedicated Hosts.
- [ ] Check that the hosts support the VM sizes and zones. Check quota and available
  host capacity before deployment.

**Verify and retain:** Confirm host placement for every persistent and temporary VM.
Keep the host assignments and proof that each host supports its VM sizes.

## Work Outside MLZ

MLZ deploys the infrastructure. The steps below are examples of customer configuration,
operations, and authorization work after deployment.

### Operate Logs and Sentinel

**Owner:** Customer records owner, security operations center (SOC), SIEM owner, and
platform team.

**Steps:**

- [ ] Set workspace, table, flow-log, and storage retention to the periods supplied by
  the records owner. Use the [logging parameters](#logging-retention-traffic-analytics-and-sentinel)
  and each service's retention controls.
- [ ] Assign Azure roles for log readers and operators on the workspace and storage
  accounts. Check that readers cannot change settings or delete stored logs.
- [ ] For protected log copies in Blob Storage, configure the
  [retention policies and legal holds](https://learn.microsoft.com/azure/storage/blobs/immutable-storage-overview)
  required by the records owner.
- [ ] If Sentinel is used, get the required log sources and detection conditions from
  the security operations team. Configure data connectors for those sources and
  analytics rules for those conditions. Enable incident creation on the rules.
- [ ] For Sentinel incidents, give handlers the
  [Microsoft Sentinel Responder role](https://learn.microsoft.com/azure/sentinel/roles).
  Send a test alert and confirm they can open and update its incident.
- [ ] Test log arrival, queries, alerts that open incidents, protection from deletion,
  and recovery.

**Verify and retain:** Keep the log retention rules, deployed settings, connector and
rule lists, access review, alert tests, queries for the oldest and newest records,
and recovery result.

### Govern Customer-Managed Keys

**Owner:** Customer key-management owner with platform and security teams.

**Steps:**

- [ ] Record the Key Vault, key ID, and key version used by each encrypted resource.
- [ ] Assign separate Azure roles for key management and workload key use. Check that
  the workload identity cannot manage or delete keys.
- [ ] Set the key's
  [rotation policy and expiry](https://learn.microsoft.com/azure/key-vault/keys/how-to-configure-key-rotation)
  to the intervals supplied by the key owner.
- [ ] Check soft-delete and purge-protection settings. Back up keys and test recovery
  using the key owner's recovery requirements.
- [ ] Confirm each service that stores customer data uses the right key before data is
  written.
- [ ] Confirm the temporary helper VM is removed after key setup.
- [ ] Test key rotation, revocation, and recovery on test keys and test resources.

**Verify and retain:** Keep key and version IDs, resource links, role reviews, and key
test results. Keep soft-delete and purge-protection settings, proof that the helper VM
was removed, and approved exceptions.

### Operate and Protect Virtual Machines

**Owner:** Workload or operating-system owner with the security team.

**Steps:**

- [ ] Apply the operating-system owner's security baseline or STIG for the VM image.
- [ ] Set up patching, endpoint detection and response, antimalware, application
  control, time, DNS, local accounts, and secure admin access.
- [ ] Get the required Windows events and Linux syslog sources from the security
  operations team. Create guest-log data collection rules for those sources, select
  the intended Log Analytics workspace, and link them to the VMs.
- [ ] Set up collection endpoints in the VMs' regions for private agent configuration.
  Add each endpoint to MLZ's Azure Monitor Private Link Scope and link each VM to
  its region's endpoint. Follow
  [Microsoft's private-monitoring setup](https://learn.microsoft.com/azure/azure-monitor/fundamentals/private-link-vm-kubernetes#enable-agent-configuration).
- [ ] Keep the workspace linked to that scope for private log ingestion. Check that the
  VMs can resolve the endpoint names and reach them over private connections.
- [ ] Check that extensions and agents are running.
- [ ] Check that sample Windows events or Linux syslog arrive in the intended Log
  Analytics workspace.
- [ ] Scan the VMs after patching and confirm the repaired findings no longer appear.
- [ ] Compare local and admin accounts with the identity owner's account list.
  Remove access for accounts that are no longer authorized.

**Verify and retain:** Keep scans, patch history, and proof that endpoint protection
works. Keep data collection rules, endpoint settings, scope membership, VM links, and
guest-log query results. Save account reviews, approved exceptions, and alert tests.

### Operate Identity and Administrative Access

**Owner:** Tenant identity owner and customer account owner.

**Steps:**

- [ ] Get the required sign-in methods, user groups, admin roles, activation limits,
  and account-review schedule from the identity owner.
- [ ] Configure MFA or CAC sign-in for those users. Set the users, applications, and
  sign-in requirements in
  [Conditional Access policies](https://learn.microsoft.com/entra/identity/conditional-access/overview).
- [ ] Assign Azure roles to the listed admin groups at the required scopes.
- [ ] If using
  [Microsoft Entra Privileged Identity Management](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-resource-roles-configure-role-settings),
  set **Activation maximum duration** for each listed role and resource scope to the
  limit supplied by the identity owner.
- [ ] At each scheduled account review, compare accounts and Azure role assignments
  with the identity owner's account list. Create, update, or disable them to match.
- [ ] Review service identities and emergency accounts. Remove unused role assignments
  and test emergency sign-in.
- [ ] When AD DS is deployed, repeat its
  [directory and login tests](#active-directory-domain-services) after identity changes.
- [ ] Test admin access through the selected Bastion or other administration path.
  Check that direct access is blocked where it is not allowed.
- [ ] Test normal, privileged, denied, and emergency access.

**Verify and retain:** Keep login tests, access rules, admin role use and reviews,
account lists, emergency-access tests, and session records.

### Provide Backup and Recovery

**Owner:** System and data owners with the continuity and recovery team.

**Steps:**

- [ ] Get the maximum recovery time and data-loss period, in minutes or hours, from
  the system and data owners. Use them as pass/fail limits for the restore test below.
- [ ] Identify every VM, data store, configuration, key, and other item that needs
  protection.
- [ ] Configure a supported backup method for each item. If Azure Backup is selected
  for VMs, [enable VM backup](https://learn.microsoft.com/azure/backup/quick-backup-vm-portal).
- [ ] Set backup frequency and retention from the data owner's requirements. Check
  that the backup store uses the required encryption key.
- [ ] Assign backup roles separately from workload administration roles. Check that
  the backup store's region matches the data owner's location requirements.
- [ ] Monitor backup jobs and correct failures.
- [ ] Write timestamped test data while backups run, up to a simulated outage in the
  test environment. Restore the protected item and confirm it can be read or started.
- [ ] Record the outage time, the time the restored item is usable, and the timestamp
  of the newest restored test data. Compare outage duration with the recovery time
  limit, and the gap between the newest restored data and the outage with the
  data-loss limit.

**Verify and retain:** Keep the list of protected items, backup rules, encryption and
access settings, job results, restore tests, and measured recovery times.
Record failures and how they were fixed.

### Maintain PPSM and Validate Network Flows

**Owner:** Customer network owner, PPSM authority, and security team.

**Steps:**

- [ ] Compare deployed custom NSG and Firewall rules with the
  [traffic list](#predeployment-inputs) and PPSM record. Correct differences using the
  [NSG](#network-security-group-and-ppsm-rules) and [Firewall](#azure-firewall-modes-and-rules)
  steps.
- [ ] Keep the rules needed by Azure and MLZ services.
- [ ] Check routes, DNS, private endpoints, and the NSG and Firewall rules in effect.
- [ ] Test allowed and blocked connections after changes that affect traffic.

**Verify and retain:** Keep the PPSM record, traffic diagrams, input values, rule exports,
route and DNS checks, traffic tests, logs, and exceptions.

### Perform Vulnerability Management and Incident Response

**Owner:** Security operations team and resource owners.

**Steps:**

- [ ] Configure the customer's scanner to cover the deployed resources, operating
  systems, identities, and workload endpoints. Give its identity the access required
  by that scanner.
- [ ] Run scans and combine the results with Defender findings. For each finding,
  record the resource ID, severity, resource owner, and repair due date.
- [ ] Fix each finding and scan again to confirm the repair. For findings left open,
  attach the customer's risk decision to the finding record.
- [ ] Connect MLZ logs and alerts to the incident system used by the security
  operations team. Send a test alert and confirm that a case opens.
- [ ] If Sentinel is used, configure
  [automation rules](https://learn.microsoft.com/azure/sentinel/automate-incident-handling-with-automation-rules)
  to assign incidents to the responder identified by the security operations team.
- [ ] In a test environment, exercise containment and recovery on a test resource.
  Record the access changes, repair, restore result, and follow-up scan in the case.
- [ ] Attach alert records, the incident timeline, actions taken, and recovery checks
  to the case. Include unresolved findings in the
  [assessment records](#complete-data-application-and-rmf-work).

**Verify and retain:** Keep scan reports, findings, owners, due dates, and follow-up scans.
Keep risk decisions and changes over time. For incidents, keep the timeline, evidence,
messages, recovery checks, and fixes.

### Complete Data, Application, and RMF Work

**Owner:** System owner, data owner, application owners, control owners, assessor,
security management, and AO.

**Steps:**

- [ ] Record the deployed resource IDs and data flows in the SSP's authorization
  boundary.
- [ ] Record the data's security category, classification, and handling requirements
  in the SSP. Check the deployed encryption, access, and storage settings against them.
- [ ] For the customer's selected NIST SP 800-53 Revision 5 controls, record each
  control owner, implementation, and test result. Include controls supplied by other
  systems or shared with other teams.
- [ ] Add the configuration exports and test results from this guide to the SSP and
  assessment report. Include application and external-control evidence from their
  owners.
- [ ] Record unresolved findings, resource owners, and repair dates in the plans of
  action and milestones. Attach customer risk decisions.
- [ ] Submit the SSP, assessment report, findings, and risk records to the AO through
  the customer's authorization process.
- [ ] Record the AO's decision and conditions. Apply any required configuration
  changes and add the required tests and review dates to the operating schedule.

**Verify and retain:** Keep the SSP, system boundary, traffic diagrams, and data decisions.
Keep the evidence list, assessment plan, report, and findings. Keep plans of action and
milestones, risk decisions, the AO decision and terms, and monitoring records.

## References

- [MLZ IL5 RMF resource mapping](./il5-rmf-resource-mapping.md)
- [DoD Cloud Computing Security Requirements Guide library](https://www.cyber.mil/dccs/dccs-documents/) - Cloud Service Provider SRG Version 1, Release 7, dated 30 June 2026.
- [DoDI 8510.01, Risk Management Framework for DoD Systems](https://www.esd.whs.mil/Portals/54/Documents/DD/issuances/dodi/851001p.pdf) - effective 19 July 2022; reissues and cancels the 12 March 2014 instruction, as amended.
- [CNSSI 1253, Security Categorization and Control Selection for National Security Systems](https://www.dcsa.mil/Portals/91/Documents/CTP/NAO/CNSSI_No1253.pdf) - 27 March 2014.
- [Department of Defense in Azure Government](https://learn.microsoft.com/azure/azure-government/documentation-government-overview-dod)
- [Isolation guidelines for Impact Level 5 workloads](https://learn.microsoft.com/azure/azure-government/documentation-government-impact-level-5)
- [Department of Defense Impact Level 5](https://learn.microsoft.com/azure/compliance/offerings/offering-dod-il5)
- [NIST SP 800-53 Revision 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)
- [NIST SP 800-37 Revision 2](https://csrc.nist.gov/pubs/sp/800/37/r2/final)
