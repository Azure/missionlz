# SCCA

## Concepts

Mission LZ is intended to comply with the controls listed in the  [Secure Cloud Computing Architecture (SCCA) Functional Requirements Document (FRD)](https://dl.dod.cyber.mil/wp-content/uploads/cloud/pdf/SCCA_FRD_v2-9.pdf).

The SCCA has four components:

- [Boundary Cloud Access Point (BCAP)](#BCAP-Controls)
- [Virtual Datacenter Security Stack (VDSS)](VDSS-Controls)
- Virtual Datacenter Managed Services (VDMS)
- Trusted Cloud Credential Manager (TCCM)

Each component has a set of controls. The controls for each component are listed below, with a mapping to the technologies used in Mission LZ to implement each control.

## BCAP Controls

<!-- markdownlint-disable MD033 -->
<!-- allow html for line breaks within table cells -->
REQ ID | BCAP Security Requirements | Mission LZ
-------|----------------------------|------------
2.1.1.1 | The BCAP shall provide the capability to detect and prevent malicious code injection into the DISN originating from the CSE | Security Center
2.1.1.2 | The BCAP shall provide the capability to detect and thwart single and multiple node DOS attacks | Firewall, Security Center
2.1.1.3 | The BCAP shall provide the ability to perform detection and prevention of traffic flow having unauthorized source and destination IP addresses, protocols, and Transmission Control Protocol (TCP)/User Datagram Protocol (UDP) ports | Firewall, Security Center
2.1.1.4 | The BCAP shall provide the capability to detect and prevent IP Address Spoofing and IP Route Hijacking | NSG
2.1.1.5 | The BCAP shall provide the capability to prevent device identity policy infringement (prevent rogue device access) | Security Center and network route config
2.1.1.6 | The BCAP shall provide the capability to detect and prevent passive and active network enumeration scanning originating from within the CSE | Security Center
2.1.1.7 | The BCAP shall provide the capability to detect and prevent unauthorized data exfiltration from the DISN to an end-point inside CSE | N/A
2.1.1.8 | The BCAP and/or BCAP Management System shall provide the capability to sense, correlate, and warn on advanced persistent threats | Security Center
2.1.1.9 | The BCAP shall provide the capability to detect custom traffic and activity signatures | Security Center
2.1.1.10 | The BCAP shall provide an interface to conduct ports, protocols, and service management (PPSM) activities in order to provide control for BCND providers | Azure Firewall <br/> NSG <br/> Network Watcher
2.1.1.11 | The BCAP shall provide full packet capture (FPC) for traversing communications | N/A
2.1.1.12 | The BCAP shall provide network packet flow metrics and statistics for all traversing communications | Azure Firewall <br/> Log Analytics <br/> Network Watcher
2.1.1.13 | The BCAP shall provide the capability to detect and prevent application session hijacking | N/A

## VDSS Controls

REQ ID | VDSS Security Requirements | Mission LZ
-------|----------------------------|------------
2.1.2.1 | The VDSS shall maintain virtual separation of all management, user, and data traffic. | Az Virtual Network <br/> Az Firewall <br/> Az NSGs <br/> Az Virtual Network
2.1.2.2 | The VDSS shall allow the use of encryption for segmentation of management traffic. | Virtual Network (default)
2.1.2.3 | The VDSS shall provide a reverse proxy capability to handle access requests from client systems | N/A
2.1.2.4 | The VDSS shall provide a capability to inspect and filter application layer conversations based on a predefined set of rules (including HTTP) to identify and block malicious content | N/A
2.1.2.5 | The VDSS shall provide a capability that can distinguish and block unauthorized application layer traffic | N/A
2.1.2.6 | The VDSS shall provide a capability that monitors network and system activities to detect and report malicious activities for traffic entering and exiting Mission Owner virtual private networks/enclaves | Az Monitor <br/> Az Security Center <br/> Az Network Watcher
2.1.2.7 | The VDSS shall provide a capability that monitors network and system activities to stop or block detected malicious activity | Security Center
2.1.2.8 | The VDSS shall inspect and filter traffic traversing between mission owner virtual private networks/enclaves. | Azure Firewall <br/> Log Analytics
2.1.2.9 | The VDSS shall perform break and inspection of SSL/TLS communication traffic supporting single and dual authentication for traffic destined to systems hosted within the CSE. | Firewall
2.1.2.10 | The VDSS shall provide an interface to conduct ports, protocols, and service management (PPSM) activities in order to provide control for MCD operators | Azure Firewall <br/> NSG Network Watcher
2.1.2.11 | The VDSS shall provide a monitoring capability that captures log files and event data for cybersecurity analysis | Az Monitor <br/> Az Log Analytics <br/> Az Activity Logs
2.1.2.12 | The VDSS shall provide or feed security information and event data to an allocated archiving system for common collection, storage, and access to event logs by privileged users performing Boundary and Mission CND activities | Azure Security Center <br/> Log Analytics
2.1.2.13 | The VDSS shall provide a FIPS-140-2 compliant encryption key management system for storage of DoD generated and assigned server private encryption key credentials for access and use by the Web Application Firewall (WAF) in the execution of SSL/TLS break and inspection of encrypted communication sessions. | Key Vault
2.1.2.14 | The VDSS shall provide the capability to detect and identify application session hijacking | N/A
2.1.2.15 | The VDSS shall provide a DoD DMZ Extension to support to support Internet Facing Applications (IFAs) | N/A
2.1.2.16 | The VDSS shall provide full packet capture (FPC) or cloud service equivalent FPC capability for recording and interpreting traversing communications | Firewall
2.1.2.17 | The VDSS shall provide network packet flow metrics and statistics for all traversing communications | Firewall, Network Watcher
2.1.2.18 | The VDSS shall provide for the inspection of traffic entering and exiting each mission owner virtual private network. | Firewall, Network Watcher

<!-- markdownlint-enable MD033 -->