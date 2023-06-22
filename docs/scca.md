# SCCA

## Concepts

Mission LZ is intended to comply with the controls listed in the  [Secure Cloud Computing Architecture (SCCA) Functional Requirements Document (FRD)](https://rmf.org/wp-content/uploads/2018/05/SCCA_FRD_v2-9.pdf).

The SCCA has four components:

- [Boundary Cloud Access Point (BCAP)](#bcap-controls)
- [Virtual Datacenter Security Stack (VDSS)](#vdss-controls)
- [Virtual Datacenter Managed Services (VDMS)](#vdms-controls)
- [Trusted Cloud Credential Manager (TCCM)](#tccm-controls)

Each component has a set of controls. The controls for each component are listed below, with a mapping to the technologies used in Mission LZ to implement each control.

- Some of the controls are implemented using Azure technologies, but are not within the scope of Mission Landing Zone, e.g. multi-factor authentication and AAD Connect. These rows do not have a ✔️ in the Mission LZ column.
- Some of the controls are not implemented with Azure technologies, e.g. BCAP 2.1.1.7. These rows have "N/A" under the Azure Technologies column.

> NOTE: the mapping of controls to technologies and Mission Landing Zone implementation represents our opinion on how Mission Landing Zone implements SCCA controls. The mappings below are not defined by any DoD organization or Authorizing Official.

## BCAP Controls

<!-- markdownlint-disable MD033 -->
<!-- allow html for line breaks within table cells -->
REQ ID | BCAP Security Requirements | Azure Technologies | Mission LZ
-------|----------------------------|--------------------|------------
2.1.1.1 | The BCAP shall provide the capability to detect and prevent malicious code injection into the DISN originating from the CSE | Microsoft Defender for Cloud | ✔️
2.1.1.2 | The BCAP shall provide the capability to detect and thwart single and multiple node DOS attacks | Azure Firewall, Microsoft Defender for Cloud | ✔️
2.1.1.3 | The BCAP shall provide the ability to perform detection and prevention of traffic flow having unauthorized source and destination IP addresses, protocols, and Transmission Control Protocol (TCP)/User Datagram Protocol (UDP) ports | Azure Firewall, Microsoft Defender for Cloud| ✔️
2.1.1.4 | The BCAP shall provide the capability to detect and prevent IP Address Spoofing and IP Route Hijacking | Network Security Groups | ✔️
2.1.1.5 | The BCAP shall provide the capability to prevent device identity policy infringement (prevent rogue device access) | Microsoft Defender for Cloud and network route configuration | ✔️
2.1.1.6 | The BCAP shall provide the capability to detect and prevent passive and active network enumeration scanning originating from within the CSE | Microsoft Defender for Cloud | ✔️
2.1.1.7 | The BCAP shall provide the capability to detect and prevent unauthorized data exfiltration from the DISN to an end-point inside CSE | N/A |
2.1.1.8 | The BCAP and/or BCAP Management System shall provide the capability to sense, correlate, and warn on advanced persistent threats | Microsoft Defender for Cloud | ✔️
2.1.1.9 | The BCAP shall provide the capability to detect custom traffic and activity signatures | Microsoft Defender for Cloud | ✔️
2.1.1.10 | The BCAP shall provide an interface to conduct ports, protocols, and service management (PPSM) activities in order to provide control for BCND providers | Azure Firewall <br/> Network Security Groups <br/> Network Watcher | ✔️
2.1.1.11 | The BCAP shall provide full packet capture (FPC) for traversing communications | N/A |
2.1.1.12 | The BCAP shall provide network packet flow metrics and statistics for all traversing communications | Azure Firewall <br/> Log Analytics <br/> Network Watcher | ✔️
2.1.1.13 | The BCAP shall provide the capability to detect and prevent application session hijacking | N/A |

## VDSS Controls

REQ ID | VDSS Security Requirements | Azure Technologies | Mission LZ
-------|----------------------------|--------------------|-----------
2.1.2.1 | The VDSS shall maintain virtual separation of all management, user, and data traffic. | Azure Virtual Network <br/> Azure Firewall <br/> Network Security Groups | ✔️
2.1.2.2 | The VDSS shall allow the use of encryption for segmentation of management traffic. | Azure Virtual Network (default) | ✔️
2.1.2.3 | The VDSS shall provide a reverse proxy capability to handle access requests from client systems | N/A |
2.1.2.4 | The VDSS shall provide a capability to inspect and filter application layer conversations based on a predefined set of rules (including HTTP) to identify and block malicious content | N/A |
2.1.2.5 | The VDSS shall provide a capability that can distinguish and block unauthorized application layer traffic | N/A |
2.1.2.6 | The VDSS shall provide a capability that monitors network and system activities to detect and report malicious activities for traffic entering and exiting Mission Owner virtual private networks/enclaves | Azure Monitor <br/> Microsoft Defender for Cloud <br/> Network Watcher | ✔️
2.1.2.7 | The VDSS shall provide a capability that monitors network and system activities to stop or block detected malicious activity | Microsoft Defender for Cloud | ✔️
2.1.2.8 | The VDSS shall inspect and filter traffic traversing between mission owner virtual private networks/enclaves. | Azure Firewall <br/> Log Analytics | ✔️
2.1.2.9 | The VDSS shall perform break and inspection of SSL/TLS communication traffic supporting single and dual authentication for traffic destined to systems hosted within the CSE. | Azure Firewall | ✔️
2.1.2.10 | The VDSS shall provide an interface to conduct ports, protocols, and service management (PPSM) activities in order to provide control for MCD operators | Azure Firewall <br/> Network Security Groups Network Watcher | ✔️
2.1.2.11 | The VDSS shall provide a monitoring capability that captures log files and event data for cybersecurity analysis | Azure Monitor <br/> Azure Log Analytics <br/> Azure Activity Logs | ✔️
2.1.2.12 | The VDSS shall provide or feed security information and event data to an allocated archiving system for common collection, storage, and access to event logs by privileged users performing Boundary and Mission CND activities | Microsoft Defender for Cloud <br/> Azure Log Analytics | ✔️
2.1.2.13 | The VDSS shall provide a FIPS-140-2 compliant encryption key management system for storage of DoD generated and assigned server private encryption key credentials for access and use by the Web Application Firewall (WAF) in the execution of SSL/TLS break and inspection of encrypted communication sessions. | Azure Key Vault | ✔️
2.1.2.14 | The VDSS shall provide the capability to detect and identify application session hijacking | N/A |
2.1.2.15 | The VDSS shall provide a DoD DMZ Extension to support to support Internet Facing Applications (IFAs) | N/A |
2.1.2.16 | The VDSS shall provide full packet capture (FPC) or cloud service equivalent FPC capability for recording and interpreting traversing communications | Azure Firewall | ✔️
2.1.2.17 | The VDSS shall provide network packet flow metrics and statistics for all traversing communications | Azure Firewall <br/> Network Watcher | ✔️
2.1.2.18 | The VDSS shall provide for the inspection of traffic entering and exiting each mission owner virtual private network. | Azure Firewall <br/> Network Watcher | ✔️

## VDMS Controls

REQ ID | VDMS Security Requirements | Azure Technologies | Mission LZ
-------|----------------------------|--------------------|-----------
2.1.3.1 | The VDMS shall provide Assured Compliance Assessment Solution (ACAS), or approved equivalent, to conduct continuous monitoring for all enclaves within the CSE | Azure Policy <br/> Azure Blueprints |
2.1.3.2 | The VDMS shall provide Host Based Security System (HBSS), or approved equivalent, to manage endpoint security for all enclaves within the CSE | Microsoft Defender for Cloud | ✔️
2.1.3.3 | The VDMS shall provide identity services to include an Online Certificate Status Protocol (OCloud Workload Security) responder for remote system DoD Common Access Card (CAC) two-factor authentication of DoD privileged users to systems instantiated within the CSE | Multi-Factor Authentication |
2.1.3.4 | The VDMS shall provide a configuration and update management system to serve systems and applications for all enclaves within the CSE | N/A
2.1.3.5 | The VDMS shall provide logical domain services to include directory access, directory federation, Dynamic Host Configuration Protocol (DHCP), and Domain Name System (DNS) for all enclaves within the CSE | Azure Active Directory (AAD) <br/> Azure DNS | ✔️
2.1.3.6 | The VDMS shall provide a network for managing systems and applications within the CSE that is logically separate from the user and data networks. | Virtual Network <br/> Azure Subnets | ✔️
2.1.3.7 | The VDMS shall provide a system, security, application, and user activity event logging and archiving system for common collection, storage, and access to event logs by privileged users performing BCP and MCP activities. | Azure Log Analytics <br/> Microsoft Defender for Cloud | ✔️
2.1.3.8 | The VDMS shall provide for the exchange of DoD privileged user authentication and authorization attributes with the CSP's Identity and access management system to enable cloud system provisioning, deployment, and configuration | Azure Active Directory Connect |
2.1.3.9 | The VDMS shall implement the technical capabilities necessary to execute the mission and objectives of the TCCM role. | Azure Active Directory | ✔️

## TCCM Controls

REQ ID | TCCM Security Requirements | Azure Technologies | Mission LZ
-------|----------------------------|--------------------|-----------
2.1.4.1 | The TCCM shall develop and maintain a Cloud Credential Management Plan (CCMP)to address the implementation of policies, plans, and procedures that will be applied to mission owner customer portal account credential management | N/A |
2.1.4.2 | The TCCM shall collect, audit, and archive all Customer Portal activity logs and alerts  | Azure Log Analytics | ✔️
2.1.4.3 | The TCCM shall ensure activity log alerts are shared with, forwarded to, or retrievable by DoD privileged users engaged in MCP and BCP activities | Azure Log Analytics | ✔️
2.1.4.4 | The TCCM shall, as necessary for information sharing, create log repository access accounts for access to activity log data by privileged users performing both MCP and BCP activities | Azure Log Analytics | ✔️
2.1.4.5 | The TCCM shall recover and securely control customer portal account credentials prior to mission application connectivity to the DISN | Azure Active Directory | ✔️
2.1.4.6 | The TCCM shall create,issue, and revoke, as necessary,role based access least privileged customer portal credentials to mission owner application and system administrators (i.e., DoD privileged users). | Azure Active Directory/Role-Based Authorization | ✔️

<!-- markdownlint-enable MD033 -->
