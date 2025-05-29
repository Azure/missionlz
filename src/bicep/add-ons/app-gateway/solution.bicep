@description('A suffix to use for naming deployments uniquely. Default value = "utcNow()".')
param deploymentNameSuffix string = utcNow()

@description('Resource ID of the existing Virtual Network')
param hubVnetResourceId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/virtualNetworks/example-vnet'

@description('Name for the Application Gateway subnet')
param agwSubnetName string = 'agwSubnet'

@description('Subnet address prefix for the Application Gateway (must be part of the VNet address space)')
param agwSubnetPrefix string = '10.0.2.0/27'

@description('Name for the Application Gateway')
param agwName string = 'example-appgw'

@description('Location for the Application Gateway')
param location string = 'eastus'

@description('Backend address pool for the Application Gateway')
param backendAddressPool object = {
  name: 'example-backend'
  properties: {
    backendAddresses: [
      { ipAddress: '10.0.4.4' }
      { ipAddress: '10.0.4.5' }
    ]
  }
}

@description('Frontend private IP configuration for the Application Gateway')
param frontendPrivateIpConfig object = {
  name: 'feip1'
  privateIPAddress: '10.0.2.10'
  privateIPAllocationMethod: 'Static'
}

@description('Frontend port configuration')
param frontendPort object = {
  name: 'frontendPort80'
  port: 80
}

@description('Key Vault resource ID')
param keyVaultResourceId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.KeyVault/vaults/example-kv'

@description('Name of the certificate in Key Vault')
param keyVaultCertName string = 'example-cert'

@description('Version of the certificate in Key Vault (optional)')
param keyVaultCertVersion string = ''

module appGatewayModule './modules/app-gateway.bicep' = {
  name: 'deploy-appGateway-${deploymentNameSuffix}'
  params: {
    agwName: agwName
    location: location
    subnetName: agwSubnetName
    addressPrefix: agwSubnetPrefix
    vnetResourceId: hubVnetResourceId
    backendAddressPool: backendAddressPool
    frontendPrivateIpConfig: frontendPrivateIpConfig
    frontendPort: frontendPort
    keyVaultResourceId: keyVaultResourceId
    keyVaultCertName: keyVaultCertName
    keyVaultCertVersion: keyVaultCertVersion
  }
}
