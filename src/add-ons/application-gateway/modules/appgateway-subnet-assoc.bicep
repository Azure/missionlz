// appgateway-subnet-assoc.bicep
// Associates route table and optional NSG to existing App Gateway subnet (redefines subnet)

targetScope = 'resourceGroup'

@description('Hub VNet resource ID')
param hubVnetResourceId string
@description('Subnet name')
param subnetName string
@description('Subnet address prefix (for idempotent redefinition)')
param addressPrefix string
@description('Route table ID to associate')
param routeTableId string
@description('Optional NSG ID (empty string for none)')
param nsgId string = ''

var hubVnetName = last(split(hubVnetResourceId, '/'))

resource hubVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: hubVnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: subnetName
  parent: hubVnet
  properties: {
    addressPrefix: addressPrefix
    networkSecurityGroup: empty(nsgId) ? null : {
      id: nsgId
    }
    routeTable: {
      id: routeTableId
    }
    delegations: [
      {
        name: 'appgwDelegation'
        properties: {
          serviceName: 'Microsoft.Network/applicationGateways'
        }
      }
    ]
  }
}

output subnetId string = subnet.id
