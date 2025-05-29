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

@description('Backend pool configuration for the Application Gateway')
param backendPools array = [
  {
    name: 'example-backend'
    properties: {
      backendAddresses: [
        { ipAddress: '10.0.4.4' }
        { ipAddress: '10.0.4.5' }
      ]
    }
  }
]

@description('Frontend private IP configuration for the Application Gateway')
param frontendPrivateIpConfigs array = [
  {
    name: 'feip1'
    privateIPAddress: '10.0.2.10'
    privateIPAllocationMethod: 'Static'
  }
]

module appGatewayModule './modules/app-gateway.bicep' = {
  name: 'deploy-appGateway-${deploymentNameSuffix}'
  params: {
    agwName: agwName
    location: location
    subnetName: agwSubnetName
    addressPrefix: agwSubnetPrefix
    vnetResourceId: hubVnetResourceId
    backendAddressPools: backendPools
    frontendPrivateIpConfigs: frontendPrivateIpConfigs
  }
}
