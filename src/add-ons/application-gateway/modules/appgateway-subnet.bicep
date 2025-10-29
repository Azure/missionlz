// moved from root: appgateway-subnet.bicep
param hubVnetResourceId string
param subnetName string = 'AppGateway'
param addressPrefix string = '10.100.0.0/24'
param defaultOutboundAccess bool = false
param disablePrivateEndpointNetworkPolicies bool = true
param routeTableId string
param nsgId string = ''
var vnetName = last(split(hubVnetResourceId, '/'))
resource hubVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = { name: vnetName }
resource appGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: subnetName
  parent: hubVnet
  properties: {
    addressPrefix: addressPrefix
    defaultOutboundAccess: defaultOutboundAccess
    privateEndpointNetworkPolicies: disablePrivateEndpointNetworkPolicies ? 'Disabled' : 'Enabled'
    networkSecurityGroup: empty(nsgId) ? null : { id: nsgId }
    routeTable: { id: routeTableId }
    delegations: [ { name: 'appgwDelegation', properties: { serviceName: 'Microsoft.Network/applicationGateways' } } ]
  }
}
output subnetId string = appGatewaySubnet.id
