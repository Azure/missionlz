targetScope = 'subscription'

@description('Resource ID of the target Virtual Network')
param vnetResourceId string

@description('Address prefix for the Application Gateway subnet (e.g., 10.0.1.0/24)')
param subnetPrefix string

@description('Backend address pool for the Application Gateway (must match ARM schema)')
param backendAddressPool object

@description('Frontend private IP configurations for the Application Gateway')
param frontendPrivateIpConfigs array

@description('Frontend port configurations (array of objects: { name, port })')
param frontendPorts array

@description('Web Application Firewall configuration for the Application Gateway')
param webApplicationFirewallConfiguration object

@description('Key Vault resource ID (required if using port 443)')
param keyVaultResourceId string = ''

@description('Name of the certificate in Key Vault (required if using port 443)')
param keyVaultCertName string = ''

@description('Optional deployment name suffix for uniqueness')
param deploymentNameSuffix string = ''

// --- Extract naming convention values from vnetResourceId ---
var vnetName = last(split(vnetResourceId, '/'))
var vnetNameParts = split(vnetName, '-')
var identifier = vnetNameParts[0]
var environmentAbbreviation = vnetNameParts[1]
var locationShort = vnetNameParts[2]
var networkName = vnetNameParts[3]
var delimiter = '-'

// --- Derive route table name and resource ID ---
var routeTableName = '${identifier}${delimiter}${environmentAbbreviation}${delimiter}${locationShort}${delimiter}${networkName}-rt'
var vnetResourceGroup = split(vnetResourceId, '/')[4]
var routeTableResourceId = resourceId('Microsoft.Network/routeTables', routeTableName)

// --- Call naming convention module ---
module naming '../../modules/naming-convention.bicep' = {
  name: 'get-naming-${deploymentNameSuffix}'
  params: {
    delimiter: delimiter
    environmentAbbreviation: environmentAbbreviation
    location: locationShort
    networkName: networkName
    identifier: identifier
    stampIndex: deploymentNameSuffix
  }
}

// --- Subnet module ---
module subnet 'modules/subnet.bicep' = {
  name: 'create-subnet-${deploymentNameSuffix}'
  scope: resourceGroup(vnetResourceGroup)
  params: {
    vnetResourceId: vnetResourceId
    subnetName: naming.outputs.names.subnet
    subnetPrefix: subnetPrefix
    routeTableId: routeTableResourceId
  }
}

// --- Determine if HTTPS/Key Vault is needed ---
var frontendPortNumbers = [for p in frontendPorts: p.port]
var hasPort443 = contains(frontendPortNumbers, 443)

// --- Key Vault/Identity module (only if port 443 is present) ---
module keyvault 'modules/keyvault.bicep' = if (hasPort443) {
  name: 'get-keyvault-certificate-${deploymentNameSuffix}'
  scope: resourceGroup(split(keyVaultResourceId, '/')[4])
  params: {
    keyVaultResourceId: keyVaultResourceId
    identityName: naming.outputs.names.userAssignedIdentity
    location: subnet.outputs.subnetProperties.location
    deployAccessPolicy: true
  }
}

// --- Application Gateway module ---
module appGateway 'modules/app-gateway.bicep' = {
  name: 'create-appGateway-${deploymentNameSuffix}'
  scope: resourceGroup(vnetResourceGroup)
  params: {
    agwName: naming.outputs.names.applicationGateway
    location: subnet.outputs.subnetProperties.location
    subnetResourceId: subnet.outputs.subnetResourceId
    backendAddressPool: backendAddressPool
    frontendPrivateIpConfigs: frontendPrivateIpConfigs
    frontendPorts: frontendPorts
    keyVaultResourceId: keyVaultResourceId
    keyVaultCertName: keyVaultCertName
    webApplicationFirewallConfiguration: webApplicationFirewallConfiguration
    identityResourceId: hasPort443 ? keyvault.outputs.identityResourceId : ''
  }
}

// --- Outputs ---
output appGatewayId string = appGateway.outputs.appGatewayId
output appGatewayName string = appGateway.outputs.appGatewayName
output subnetId string = subnet.outputs.subnetResourceId
output naming object = naming.outputs
