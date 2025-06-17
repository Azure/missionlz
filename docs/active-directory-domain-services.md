# Active Directory Domain Services (ADDS) IaaS Option

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
| `addsDnsDomainName` | Active Directory DNS domain name | `contoso.local` | Yes |
| `addsNetbiosDomainName` | Active Directory NetBIOS domain name | `CONTOSO` | Yes |

### VM Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `addsVmNamePrefix` | VM name prefix | `{identifier}-adds` | No |
| `addsVmCount` | Number of domain controllers | `2` | No |
| `addsVmSize` | VM size | `Standard_DS2_v2` | No |
| `addsVmPrivateIPAddresses` | Static IP addresses for DCs | `[]` | Yes |

### Credentials

| Parameter | Description | Required |
|-----------|-------------|----------|
| `addsDomainAdminUsername` | Domain administrator username | Yes |
| `addsDomainAdminPassword` | Domain administrator password | Yes |
| `addsSafemodeAdminUsername` | Safe mode administrator username | Yes |
| `addsSafemodeAdminPassword` | Safe mode administrator password | Yes |
| `addsDomainJoinUsername` | Domain join service account username | Yes |
| `addsDomainJoinUserPassword` | Domain join service account password | Yes |

### Network Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `addsDnsForwarders` | DNS forwarder IP addresses | `["168.63.129.16"]` | No |
| `addsManagementSubnets` | Management subnets for firewall rules | `[]` | No |

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
  -addsDnsDomainName "myorg.local" `
  -addsNetbiosDomainName "MYORG" `
  -addsVmPrivateIPAddresses @("10.0.130.4", "10.0.130.5") `
  -addsDomainAdminUsername "administrator" `
  -addsDomainAdminPassword (ConvertTo-SecureString "ComplexPassword123!" -AsPlainText -Force) `
  -addsSafemodeAdminUsername "safemodeadmin" `
  -addsSafemodeAdminPassword (ConvertTo-SecureString "ComplexPassword123!" -AsPlainText -Force) `
  -addsDomainJoinUsername "domainjoin" `
  -addsDomainJoinUserPassword (ConvertTo-SecureString "ComplexPassword123!" -AsPlainText -Force) `
  -addsManagementSubnets @("10.0.128.0/24")
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
    addsDnsDomainName="myorg.local" \
    addsNetbiosDomainName="MYORG" \
    addsVmPrivateIPAddresses='["10.0.130.4", "10.0.130.5"]' \
    addsDomainAdminUsername="administrator" \
    addsDomainAdminPassword="ComplexPassword123!" \
    addsSafemodeAdminUsername="safemodeadmin" \
    addsSafemodeAdminPassword="ComplexPassword123!" \
    addsDomainJoinUsername="domainjoin" \
    addsDomainJoinUserPassword="ComplexPassword123!" \
    addsManagementSubnets='["10.0.128.0/24"]'
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
    "addsDnsDomainName": {
      "value": "myorg.local"
    },
    "addsNetbiosDomainName": {
      "value": "MYORG"
    },
    "addsVmPrivateIPAddresses": {
      "value": ["10.0.130.4", "10.0.130.5"]
    },
    "addsDomainAdminUsername": {
      "value": "administrator"
    },
    "addsDomainAdminPassword": {
      "value": "ComplexPassword123!"
    },
    "addsSafemodeAdminUsername": {
      "value": "safemodeadmin"
    },
    "addsSafemodeAdminPassword": {
      "value": "ComplexPassword123!"
    },
    "addsDomainJoinUsername": {
      "value": "domainjoin"
    },
    "addsDomainJoinUserPassword": {
      "value": "ComplexPassword123!"
    },
    "addsManagementSubnets": {
      "value": ["10.0.128.0/24"]
    }
  }
}
```

## Integration with Add-ons

### ArcGIS Accelerator

The ArcGIS Accelerator can now use the deployed ADDS domain controllers:

```bicep
// The MLZ deployment outputs can be used by add-ons
output activeDirectoryDomainServicesDeployed bool = deployActiveDirectoryDomainServices && deployIdentity
output addsDnsDomainName string = deployActiveDirectoryDomainServices && deployIdentity ? addsDnsDomainName : ''
output addsNetbiosDomainName string = deployActiveDirectoryDomainServices && deployIdentity ? addsNetbiosDomainName : ''
```

### Azure NetApp Files

When ADDS is deployed, Azure NetApp Files can be configured to use the domain for SMB share authentication.

## Security Considerations

1. **Credentials**: Store passwords securely using Azure Key Vault
2. **Network Security**: Domain controllers are deployed in the identity tier with appropriate network isolation
3. **Management Access**: Use the `addsManagementSubnets` parameter to limit administrative access
4. **DNS Configuration**: Configure proper DNS forwarding for hybrid connectivity

## Post-Deployment Configuration

After deployment, you may need to:

1. Configure additional DNS zones
2. Set up trust relationships with existing domains
3. Configure Group Policy settings
4. Add additional domain controllers for geographic redundancy

## Troubleshooting

### Common Issues

1. **IP Address Conflicts**: Ensure `addsVmPrivateIPAddresses` are available in the identity subnet
2. **DNS Resolution**: Verify DNS forwarding configuration for external connectivity
3. **DSC Configuration**: Check VM extension deployment logs for DSC configuration issues

### Logs and Monitoring

- VM extension logs: Available in Azure portal under VM > Extensions
- Event logs: Available via VM connection (Windows Event Viewer)
- Azure Monitor: Configure monitoring for domain controller health