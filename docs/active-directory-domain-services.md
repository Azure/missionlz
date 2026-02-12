# Mission Landing Zone - Active Directory Domain Services (ADDS) IaaS Option

[**Home**](../README.md) | [**Design**](./design.md) | [**Add-Ons**](../src/add-ons/README.md) | [**Resources**](./resources.md) | [**Costs**](./costs.md)

Mission Landing Zone now supports optional deployment of Active Directory Domain Services domain controllers in the identity tier. This feature enables single-click deployment scenarios that require ADDS, such as Azure NetApp Files integration with the ArcGIS Accelerator.

## Overview

When enabled, this option deploys:

- 2 Windows Server 2022 virtual machines in an availability set
- Active Directory Domain Services role installation via PowerShell DSC
- Domain controller promotion (new forest or join existing domain)
- DNS forwarding configuration
- Management subnet firewall rules

## Parameters

### Basic ADDS Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `deployActiveDirectoryDomainServices` | Enable ADDS deployment | `false` | No |
| `deployIdentity` | Must be `true` to enable ADDS | `false` | Yes (when using ADDS) |

### Domain Configuration

| Parameter | Description | Example | Required |
|-----------|-------------|---------|----------|
| `addsDomainName` | Active Directory DNS domain name | `contoso.local` | Yes |

### VM Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `addsVmSize` | VM size | `Standard_DS2_v2` | No |

### Credentials

| Parameter | Description | Required |
|-----------|-------------|----------|
| `addsSafeModeAdminPassword` | Safe mode administrator password | Yes |

## Example Usage

### PowerShell Deployment

```powershell
# Deploy MLZ with ADDS
New-AzSubscriptionDeployment -Name "mlz-with-adds" `
  -TemplateFile "mlz.bicep" `
  -Location "East US" `
  -identifier "myorg" `
  -environmentAbbreviation "dev" `
  -deployIdentity $true `
  -deployActiveDirectoryDomainServices $true `
  -addsDomainName "myorg.local" `
  -addsSafemodeAdminPassword "<Safe Mode Admin Password>"
```

### Azure CLI Deployment

```bash
# Deploy MLZ with ADDS
az deployment sub create \
  --name "mlz-with-adds" \
  --template-file "mlz.bicep" \
  --location "East US" \
  --parameters \
    identifier="myorg" \
    environmentAbbreviation="dev" \
    deployIdentity=true \
    deployActiveDirectoryDomainServices=true \
    addsDomainName="myorg.local" \
    addsSafeModeAdminPassword="C<Safe Mode Admin Password>"
```

### Parameters File Example

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "identifier": {
      "value": "myorg"
    },
    "environmentAbbreviation": {
      "value": "dev"
    },
    "deployIdentity": {
      "value": true
    },
    "deployActiveDirectoryDomainServices": {
      "value": true
    },
    "addsDomainName": {
      "value": "myorg.local"
    },
    "addsSafeModeAdminPassword": {
      "value": "<Safe Mode Admin Password>"
    },
  }
}
```

## Post-Deployment Configuration

After deployment, you may need to:

1. Configure additional DNS zones
2. Set up trust relationships with existing domains
3. Configure Group Policy settings
4. Add additional domain controllers for geographic redundancy
