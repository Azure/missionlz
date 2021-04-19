# SCCA

## Concepts

Mission LZ is intended to comply with the controls listed in the  [Secure Cloud Computing Architecture (SCCA) Functional Requirements Document (FRD)](https://dl.dod.cyber.mil/wp-content/uploads/cloud/pdf/SCCA_FRD_v2-9.pdf).

The SCCA has four components:

- Boundary Cloud Access Point (BCAP)
- Virtual Datacenter Security Stack (VDSS)
- Virtual Datacenter Managed Services (VDMS)
- Trusted Cloud Credential Manager (TCCM)

Each component has a set of controls. The controls for each component are listed below, with a mapping to the technologies used in Mission LZ to implement each control.

## BCAP Controls

REQ ID | VDSS Security Requirements | Mission LZ
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
