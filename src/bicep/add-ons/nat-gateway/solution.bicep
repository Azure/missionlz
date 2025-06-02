targetScope = 'subscription'

@description('Array of NAT Gateway deployment settings. Each object must include subnetResourceId, zone, tcpIdleTimeout, and publicIpPrefixLength.')
/*
Example parameter structure for natGatewayDeployments:

param natGatewayDeployments = [
  {
    subnetResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/my-subnet'
    zone: '1'
    tcpIdleTimeout: 10
    publicIpPrefixLength: 30
  }
  {
    subnetResourceId: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/another-rg/providers/Microsoft.Network/virtualNetworks/another-vnet/subnets/another-subnet'
    zone: ''
    tcpIdleTimeout: 4
    publicIpPrefixLength: 30
  }
]
*/
param natGatewayDeployments array

@description('A suffix to use for naming deployments uniquely.')
param deploymentNameSuffix string = utcNow()

// Loop through each deployment settings object in the array
module natGatewayDeployment './modules/main-deploy.bicep' = [for (settings, i) in natGatewayDeployments: {
  name: 'natGatewayDeployment-${i}-${deploymentNameSuffix}'
  scope: subscription()
  params: {
    subnetResourceId: settings.subnetResourceId
    zone: settings.zone
    tcpIdleTimeout: settings.tcpIdleTimeout
    publicIpPrefixLength: settings.publicIpPrefixLength
    // Add any additional parameters as needed
    deploymentNameSuffix: deploymentNameSuffix
  }
}]
