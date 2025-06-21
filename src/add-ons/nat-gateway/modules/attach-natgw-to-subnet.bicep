@description('The name of the VNet containing the subnet.')
param vnetName string

@description('The name of the subnet to attach the NAT Gateway to.')
param subnetName string

@description('The resource ID of the NAT Gateway.')
param natGatewayId string

@description('The address prefix of the subnet.')
param addressPrefix string

@description('The delegations on the subnet.')
param delegations array = []

@description('The service endpoints on the subnet.')
param serviceEndpoints array = []

@description('The service endpoint policies on the subnet.')
param serviceEndpointPolicies array = []

@description('The private endpoint network policies setting.')
param privateEndpointNetworkPolicies string = 'Enabled'

@description('The private link service network policies setting.')
param privateLinkServiceNetworkPolicies string = 'Enabled'

@description('The network security group resource ID.')
param networkSecurityGroupId string = ''

@description('The route table resource ID.')
param routeTableId string = ''

@description('The default outbound access setting.')
param defaultOutboundAccess bool = false

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: addressPrefix
    natGateway: {
      id: natGatewayId
    }
    delegations: delegations
    serviceEndpoints: serviceEndpoints
    serviceEndpointPolicies: serviceEndpointPolicies
    privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: privateLinkServiceNetworkPolicies
    defaultOutboundAccess: defaultOutboundAccess
    networkSecurityGroup: empty(networkSecurityGroupId) ? null : {
      id: networkSecurityGroupId
    }
    routeTable: empty(routeTableId) ? null : {
      id: routeTableId
    }
  }
}
