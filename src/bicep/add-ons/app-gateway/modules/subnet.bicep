@description('Resource ID of the existing Virtual Network')
param vnetResourceId string

@description('Name of the subnet to create or reference')
param subnetName string

@description('Address prefix for the subnet (e.g., 10.0.1.0/24)')
param subnetPrefix string

@description('Network security group resource ID (optional)')
param nsgId string = ''

@description('Route table resource ID (optional)')
param routeTableId string = ''

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: last(split(vnetResourceId, '/'))
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: subnetPrefix
    defaultOutboundAccess: false
    networkSecurityGroup: empty(nsgId) ? null : {
      id: nsgId
    }
    routeTable: empty(routeTableId) ? null : {
      id: routeTableId
    }
  }
}

output subnetResourceId string = subnet.id
output subnetProperties object = subnet.properties
