@description('The name of the VNet containing the subnet.')
param vnetName string

@description('The name of the subnet.')
param subnetName string

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: subnetName
  parent: vnet
}

output vnetName string = vnet.name
output subnetName string = subnet.name
output addressPrefix string = subnet.properties.addressPrefix
output defaultOutboundAccess bool = subnet.properties.defaultOutboundAccess
output privateEndpointNetworkPolicies string = subnet.properties.privateEndpointNetworkPolicies
output privateLinkServiceNetworkPolicies string = subnet.properties.privateLinkServiceNetworkPolicies
output delegations array = subnet.properties.?delegations ?? []
output networkSecurityGroupId string = subnet.properties.?networkSecurityGroup.?id ?? ''
output routeTableId string = subnet.properties.?routeTable.?id ?? ''
output serviceEndpoints array = subnet.properties.?serviceEndpoints ?? []
output serviceEndpointPolicies array = subnet.properties.?serviceEndpointPolicies ?? []
