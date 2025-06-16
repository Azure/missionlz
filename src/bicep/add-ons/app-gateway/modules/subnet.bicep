@description('Resource ID of the existing Virtual Network')
param vnetResourceId string

@description('Name of the subnet to create or reference')
param subnetName string

@description('Address prefix for the subnet (e.g., 10.0.1.0/24)')
param subnetPrefix string

@description('Delegations for the subnet (optional)')
param delegations array = []

@description('Network security group resource ID (optional)')
param nsgId string = ''

@description('Route table resource ID (optional)')
param routeTableId string = ''

@description('NAT Gateway resource ID (optional)')
param natGatewayId string = ''

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: split(vnetResourceId, '/')[8]
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetPrefix
    delegations: delegations
    networkSecurityGroup: empty(nsgId) ? null : {
      id: nsgId
    }
    routeTable: empty(routeTableId) ? null : {
      id: routeTableId
    }
    natGateway: empty(natGatewayId) ? null : {
      id: natGatewayId
    }
  }
}

output subnetResourceId string = subnet.id
output subnetProperties object = subnet.properties
