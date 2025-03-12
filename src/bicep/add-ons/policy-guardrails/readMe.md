# Deploy Policy Initiatives Script Documentation

## Overview

The `deploy-policy-initiatives.ps1` script automates the deployment of Azure Policy Definitions, Policy Set Definitions (Initiatives), and Policy Assignments. The script reads the directory structure and JSON files to create the necessary Azure resources. The directory structure and folder names must match the existing management group names in Azure.

## Directory Structure

The directory structure should be organized as follows:

```
root/
├── managementGroup1/
│   ├── policySet1/
│   │   ├── policyDefinition1.json
│   │   ├── policyDefinition1-parameters.json
│   │   ├── policyDefinition2.json
│   │   └── policyDefinition2-parameters.json
│   └── policySet2/
│       ├── policyDefinition3.json
│       └── policyDefinition3-parameters.json
└── managementGroup2/
    ├── policySet3/
    │   ├── policyDefinition4.json
    │   └── policyDefinition4-parameters.json
    └── policySet4/
        ├── policyDefinition5.json
        └── policyDefinition5-parameters.json
```

### Explanation

- **Root Directory**: The root directory contains subdirectories for each management group.
- **Management Group Directories**: Each management group directory contains subdirectories for each policy set (initiative).
- **Policy Set Directories**: Each policy set directory contains JSON files for policy definitions and their associated parameter files.

## Script Functionality

1. **Initialize Variables**: The script initializes the root folder path and the location for the managed identity.
2. **Iterate Through Management Groups**: The script iterates through the directories in the root folder, treating each directory as a management group.
3. **Process Policy Sets**: For each management group, the script iterates through the subdirectories, treating each subdirectory as a policy set.
4. **Read Policy Definitions and Parameters**: The script reads the JSON files for policy definitions and their associated parameter files.
5. **Create Policy Definitions**: The script creates policy definitions in Azure using the information from the JSON files.
6. **Create Policy Set Definitions**: The script creates policy set definitions (initiatives) in Azure using the policy definitions.
7. **Create Policy Assignments**: The script creates policy assignments in Azure, assigning the policy sets to the management groups with a system-assigned managed identity.

## Example Directory Structure and Azure Resources

### Directory Structure

```
root/
├── managementGroup1/
│   ├── policySet1/
│   │   ├── policyDefinition1.json
│   │   ├── policyDefinition1-parameters.json
│   │   ├── policyDefinition2.json
│   │   └── policyDefinition2-parameters.json
│   └── policySet2/
│       ├── policyDefinition3.json
│       └── policyDefinition3-parameters.json
└── managementGroup2/
    ├── policySet3/
    │   ├── policyDefinition4.json
    │   └── policyDefinition4-parameters.json
    └── policySet4/
        ├── policyDefinition5.json
        └── policyDefinition5-parameters.json
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

- **Policy Parameters**: Policy definitions that require custom values when assigned should have a `-parameters.json` file associated with them in the directory structure.   Parameter.json files are not required for the script, they are only needed if they are required for the policy definition to be assigned.
- **Assignment Names**: The script shortens the assignment names to ensure they do not exceed 24 characters.

## Running the Script

To run the script, set the rootfolder path to your directory structure location and execute the following command in PowerShell:

```powershell
.\deploy-policy-initiatives.ps1
```

Ensure that the directory structure and JSON files are correctly set up before running the script. The script will create the necessary Azure resources based on the directory structure and JSON files.

