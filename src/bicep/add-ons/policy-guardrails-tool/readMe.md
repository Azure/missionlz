# Policy Guardrails Tool

## Purpose

Policy guardrails in Azure go beyond "Audit" settings. They are more intrusive and must be planned, designed, and tested to avoid unexpected impacts on the production environment. They typically include the following effects:

- **DeployIfNotExists**: Remediation tasks configure resources to the state dictated by the policy, regardless of the initial deployment condition.
- **Deny**: Prevents the action defined by the policy, regardless of administrative permissions. Exceptions must be made temporarily or permanently excluded from the policy.
- **Append**: Similar to DeployIfNotExists, it appends or changes specific properties on a resource where a deployment isn't necessary.

Mission Landing Zone does not maintain any policies due to their significant operational impacts. Each organization should manage their implementation, including choosing and maintaining policies.

## Overview

The `deploy-policy-initiatives.ps1` script automates the deployment of Azure Policy Definitions, Policy Set Definitions (Initiatives), and Policy Assignments. It reads the directory structure and JSON files to create the necessary Azure resources. The directory structure and folder names must match the existing management group names in Azure.

The JSON files must be well-formed policy definitions and parameters. A good resource for discovering and reviewing Azure Policy definitions, initiatives, and aliases is Az Policy Advertiser. This tool helps users explore available policies and understand their applicability to different Azure environments.

This document does not cover custom policy design or construction. Organizations must curate and update policies based on their internal operational requirements.

## Directory Structure

The directory structure should be organized as follows:

```plaintext
root/
├── managementGroup1/
│   ├── policySet1/
│   │   ├── policyDefinition1.json
│   │   ├── policyDefinition2.json
│   │   └── policyDefinition2-parameters.json
│   └── policySet2/
│       ├── policyDefinition3.json
│       └── policyDefinition3-parameters.json
└── managementGroup2/
    ├── policySet3/
    │   ├── policyDefinition4.json
    └── policySet4/
        ├── policyDefinition5.json
        └── policyDefinition5-parameters.json
```

### Explanation

- **Root Directory**: Contains subdirectories for each management group.
- **Management Group Directories**: Contain subdirectories for each policy set (initiative).
- **Policy Set Directories**: Contain JSON files for policy definitions and their associated parameter files, if required.

## Script Functionality

1. **Initialize Variables**: The script initializes the root folder path.
2. **Iterate Through Management Groups**: The script iterates through the directories in the root folder, treating each directory as a management group. The folder names must match the corresponding management group ID in the Azure tenant.
3. **Process Policy Sets**: For each management group, the script iterates through the subdirectories, treating each subdirectory as a policy set.
4. **Read Policy Definitions and Parameters**: The script reads the JSON files for policy definitions and their associated parameter files, if they exist.
5. **Create Policy Definitions**: The script creates policy definitions in Azure directly from the JSON files.
6. **Create Policy Set Definitions**: The script creates policy set definitions (initiatives) in Azure using the policy definitions, adding the parameters to the set, if they exist.
7. **Create Policy Assignments**: The script creates policy assignments in Azure, with the parameter values from the parameter JSON files, then assigns the policy sets to the management groups with a system-assigned managed identity.
8. **Role Assignments**: Role assignments from the policy definitions are added to the system-assigned managed identity.

### Script usage

> [!IMPORTANT]
> Global Administrator permissions are required

1. Open PowerShell.
2. Install the Azure PowerShell modules if missing: `Install-Module -Name Az -Repository PSGallery -Force`.
3. Run `Connect-AzAccount -Environment '<Azure Cloud Environment Name>'` and login when prompted.
4. Change directory to the script folder.
5. Run the script with parameters:  

```powershell
.\deploy-policy-initiatives.ps1 -RootFolderPath 'C:\Path\To\Your\RootFolder' -Location '<Azure location>'
```

### Azure Resources

- **Management Group: managementGroup1**
  - **Policy Set: policySet1**
    - **Policy Definitions**:
      - `policyDefinition1`
      - `policyDefinition2`
    - **Policy Assignment**: Assigns `policySet1` to `managementGroup1`
  - **Policy Set: policySet2**
    - **Policy Definitions**:
      - `policyDefinition3`
    - **Policy Assignment**: Assigns `policySet2` to `managementGroup1`

- **Management Group: managementGroup2**
  - **Policy Set: policySet3**
    - **Policy Definitions**:
      - `policyDefinition4`
    - **Policy Assignment**: Assigns `policySet3` to `managementGroup2`
  - **Policy Set: policySet4**
    - **Policy Definitions**:
      - `policyDefinition5`
    - **Policy Assignment**: Assigns `policySet4` to `managementGroup2`

## Notes

- **Policy Parameters**: Policy definitions that require custom values when assigned should have a `-parameters.json` file associated with them in the directory structure. Parameter JSON files are only needed if required for the policy definition to be assigned.
- **Assignment Names**: The script shortens the assignment names to ensure they do not exceed 24 characters. The assignment name is derived from the policy set folder name + "Assign". For example, if the policy set folder name is `LongPolicySetNameExample`, the assignment name will be truncated to `LongPolicySetNameExAssign`.

## Step by Step

1. **Evaluate Policies**: Evaluate potential guardrail policies based on organizational needs. While this document does not include a list of recommended policies, you can explore Azure Policy definitions and initiatives using resources like Az Policy Advertiser. Note that this MLZ repository does not maintain or prescribe specific policy definitions.
2. **Set Values**: Set the proper values to be used in the `-parameters.json` files for policies that require specific values.
3. **Organize Files**: Rename or move files into a new directory structure, ensuring the root folder contains folders that match the names of existing management group IDs in Azure and that the names of the initiatives are as short as possible, as assignment names are limited to 24 characters.
4. **Log into Azure**: Use `Connect-AzAccount -Environment 'AzureUSGovernment'`, or another preferred cloud, to log into Azure with a user that has Global Administrator permissions. This will be used to create and assign the policies, in addition to setting the proper role definitions for the system-assigned managed identity for policies that require it.

## Running the Script

To run the script, set the root folder path to your directory structure location and execute the following command in PowerShell:

```powershell
.\deploy-policy-initiatives.ps1 -RootFolderPath 'C:\Path\To\Your\RootFolder' -Location '<Azure location>'
```

Ensure that the directory structure and JSON files are correctly set up before running the script. The script will create the necessary Azure resources based on the directory structure and JSON files.

## Example Policy Definition JSON

## Important Notes

**Policies, like this one, may contain specific hardcoded DNS names, locations, role definition GUIDs, etc. They will need to be changed to match the cloud it is being deployed into.**

```json
{
  "name": "Deploy-ASC-SecurityContacts-enterprise",
  "type": "Microsoft.Authorization/policyDefinitions",
  "apiVersion": "2023-04-01",
  "scope": null,
  "properties": {
    "policyType": "Custom",
    "mode": "All",
    "displayName": "Deploy Microsoft Defender for Cloud Security Contacts",
    "description": "Deploy Microsoft Defender for Cloud Security Contacts",
    "metadata": {
      "version": "1.1.0",
      "category": "Security Center",
      "source": "https://github.com/Azure/Enterprise-Scale/",
      "alzCloudEnvironments": [
        "AzureCloud",
        "AzureUSGovernment"
      ]
    },
    "parameters": {
      "emailSecurityContact": {
        "type": "string",
        "metadata": {
          "displayName": "Security contacts email address",
          "description": "Provide email address for Azure Security Center contact details"
        }
      },
      "effect": {
        "type": "string",
        "defaultValue": "DeployIfNotExists",
        "allowedValues": [
          "DeployIfNotExists",
          "Disabled"
        ],
        "metadata": {
          "displayName": "Effect",
          "description": "Enable or disable the execution of the policy"
        }
      },
      "minimalSeverity": {
        "type": "string",
        "defaultValue": "High",
        "allowedValues": [
          "High",
          "Medium",
          "Low"
        ],
        "metadata": {
          "displayName": "Minimal severity",
          "description": "Defines the minimal alert severity which will be sent as email notifications"
        }
      }
    },
    "policyRule": {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Resources/subscriptions"
          }
        ]
      },
      "then": {
        "effect": "[parameters('effect')]",
        "details": {
          "type": "Microsoft.Security/securityContacts",
          "deploymentScope": "subscription",
          "existenceScope": "subscription",
          "roleDefinitionIds": [
            "/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd"
          ],
          "existenceCondition": {
            "allOf": [
              {
                "field": "Microsoft.Security/securityContacts/email",
                "contains": "[parameters('emailSecurityContact')]"
              },
              {
                "field": "Microsoft.Security/securityContacts/alertNotifications.minimalSeverity",
                "contains": "[parameters('minimalSeverity')]"
              },
              {
                "field": "type",
                "equals": "Microsoft.Security/securityContacts"
              },
              {
                "field": "Microsoft.Security/securityContacts/alertNotifications",
                "equals": "On"
              },
              {
                "field": "Microsoft.Security/securityContacts/alertsToAdmins",
                "equals": "On"
              }
            ]
          },
          "deployment": {
            "location": "northeurope",
            "properties": {
              "mode": "incremental",
              "parameters": {
                "emailSecurityContact": {
                  "value": "[parameters('emailSecurityContact')]"
                },
                "minimalSeverity": {
                  "value": "[parameters('minimalSeverity')]"
                }
              },
              "template": {
                "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "parameters": {
                  "emailSecurityContact": {
                    "type": "string",
                    "metadata": {
                      "description": "Security contacts email address"
                    }
                  },
                  "minimalSeverity": {
                    "type": "string",
                    "metadata": {
                      "description": "Minimal severity level reported"
                    }
                  }
                },
                "variables": {},
                "resources": [
                  {
                    "type": "Microsoft.Security/securityContacts",
                    "name": "default",
                    "apiVersion": "2020-01-01-preview",
                    "properties": {
                      "emails": "[parameters('emailSecurityContact')]",
                      "notificationsByRole": {
                        "state": "On",
                        "roles": [
                          "Owner"
                        ]
                      },
                      "alertNotifications": {
                        "state": "On",
                        "minimalSeverity": "[parameters('minimalSeverity')]"
                      }
                    }
                  }
                ],
                "outputs": {}
              }
            }
          }
        }
      }
    }
  }
}
```

## Example Policy Parameter JSON for the Above Policy Definition

```json
{
  "emailSecurityContact": {
    "type": "string",
    "metadata": {
      "value": "<mailto:who@where.com>" // Replace this placeholder with an actual email address
    },
    "value": "<mailto:who@where.com>"
  }
}
```

Policy Repository:

- Azure Landing Zone: <https://github.com/Azure/Enterprise-Scale>
  Navigate to: src/resources/Microsoft.Authorization/policyDefinitions
- Az Policy Advertizer: <https://www.azadvertizer.net/azpolicyadvertizer_all.html>
  Custom policy library available and maintained by the community.
