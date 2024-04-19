# DoD Security and Compliance features in MLZ

**The following security settings and compliance features are available during the Mission Landing Zone deployment process:**

## Azure Policy

Azure policy is a service that provides the ability to implement governance for resource consistency, regulatory compliance, security, cost, and management. Below are the available regulatory compliance policies that can be enabled during the deployment process:

**NIST SP 800-53 Rev4:** National Institute of Standards and Technology (NIST) SP 800-53 R4 provides a standardized approach for assessing, monitoring and authorizing cloud computing products and services to manage information security risk. These policies address a subset of NIST SP 800-53 R4 controls. For more information, visit [https://aka.ms/nist800-53r4-initiative](https://aka.ms/nist800-53r4-initiative).

**NIST SP 800-53 Rev5:** National Institute of Standards and Technology (NIST) SP 800-53 Rev. 5 provides a standardized approach for assessing, monitoring and authorizing cloud computing products and services to manage information security risk. These policies address a subset of NIST SP 800-53 R5 controls. For more information, visit [https://aka.ms/nist800-53r5-initiative](https://aka.ms/nist800-53r5-initiative).

**DoD IL5:** This initiative includes policies that address a subset of DoD Impact Level 5 (IL5) controls. These policies are only available for AzureUSGovernment and will switch to NISTRev4 if tried in Azure Commercial. For more information, visit [https://aka.ms/dodil5-initiative](https://aka.ms/dodil5-initiative).

**Cybersecurity Maturity Model Certification (CMMC):** This initiative includes policies that address a subset of Cybersecurity Maturity Model Certification (CMMC) Level 3 requirements. For more information, visit [https://aka.ms/cmmc-initiative](https://aka.ms/cmmc-initiative).

## Defender for Cloud

Defender for Cloud is a Cloud Security Posture Management (CSPM) solution that helps you find and fix security vulnerabilities. Defender for Cloud also applies access and application controls to block malicious activity, detect threats, and respond quickly when under attack.

MLZ can be deployed with the free Foundational Cloud Security Posture Management features. For enhanced protection, there is an option for activating paid features such as Defender for Cloud Security Posture Management and Workload Protection Plans for additional threat protection. Below are the additional features available for enabling:

- Defender for CSPM

- Defender for Servers

- Defender for API

- Defender for App Services

- Defender for Resource Manager

- Defender for Azure Cosmos DB

- Defender for Key Vault

- Defender for open-source relational databases

- Defender for SQL Server on machines

- Defender for Azure SQL

- Defender for Storage

- Defender for Containers

## Sentinel

Sentinel is Microsoft’s Security Information and event management (SIEM) and Security orchestration, automation, and response (SOAR) solution. With Microsoft Sentinel, you get a single solution for attack detection, threat visibility, proactive hunting, and threat response. A Log Analytics Workspace is created and deployed specifically for Sentinel to collect log data from multiple services.
A Data Connector is deployed to import data from Microsoft Entra to track resource activity.

**Log Analytics Workspace:**

- ***-log-operations-dev-va

**Data Connector:**

- Azure Activity: Azure Activity Log is a subscription log that provides insight into subscription-level events that occur in Azure, including events from Azure Resource Manager operational data,

## Customer Responsibilities

There are additional security best practices which should be implemented after deploying a Mission Landing Zone that are specific to each customer’s environment.

- [Deploy STIG-compliant Windows Virtual Machines](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-stig-windows-vm)

- [Centralize Identity Management](https://learn.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices?bc=%2Fazure%2Fcloud-adoption-framework%2F_bread%2Ftoc.json&toc=%2Fazure%2Fcloud-adoption-framework%2Ftoc.json#centralize-identity-management)

- [Enable Single Sign-On](https://learn.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices?bc=%2Fazure%2Fcloud-adoption-framework%2F_bread%2Ftoc.json&toc=%2Fazure%2Fcloud-adoption-framework%2Ftoc.json#enable-single-sign-on)

- [Turn on Conditional Access](https://learn.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices?bc=%2Fazure%2Fcloud-adoption-framework%2F_bread%2Ftoc.json&toc=%2Fazure%2Fcloud-adoption-framework%2Ftoc.json#turn-on-conditional-access)

- [Enable Password Management](https://learn.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices?bc=%2Fazure%2Fcloud-adoption-framework%2F_bread%2Ftoc.json&toc=%2Fazure%2Fcloud-adoption-framework%2Ftoc.json#enable-password-management)

- [Enforce Multifactor Verification for Users](https://learn.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices?bc=%2Fazure%2Fcloud-adoption-framework%2F_bread%2Ftoc.json&toc=%2Fazure%2Fcloud-adoption-framework%2Ftoc.json#enforce-multifactor-verification-for-users)

- [User Role-Based Access Control](https://learn.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices?bc=%2Fazure%2Fcloud-adoption-framework%2F_bread%2Ftoc.json&toc=%2Fazure%2Fcloud-adoption-framework%2Ftoc.json#use-role-based-access-control)

- [Lower Exposure of Privileged Accounts](https://learn.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices?bc=%2Fazure%2Fcloud-adoption-framework%2F_bread%2Ftoc.json&toc=%2Fazure%2Fcloud-adoption-framework%2Ftoc.json#lower-exposure-of-privileged-accounts)

- [Control Locations Where Resources are Created](https://learn.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices?bc=%2Fazure%2Fcloud-adoption-framework%2F_bread%2Ftoc.json&toc=%2Fazure%2Fcloud-adoption-framework%2Ftoc.json#control-locations-where-resources-are-created)

- [Actively Monitor for Suspicious Activities](https://learn.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices?bc=%2Fazure%2Fcloud-adoption-framework%2F_bread%2Ftoc.json&toc=%2Fazure%2Fcloud-adoption-framework%2Ftoc.json#actively-monitor-for-suspicious-activities)

- [Use Microsoft Entra ID for Storage Authentication](https://learn.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices?bc=%2Fazure%2Fcloud-adoption-framework%2F_bread%2Ftoc.json&toc=%2Fazure%2Fcloud-adoption-framework%2Ftoc.json#use-microsoft-entra-id-for-storage-authentication)

## Planned Changes

- DoD Zero Trust Workbook
