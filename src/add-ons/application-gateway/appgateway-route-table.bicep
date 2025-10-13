// appgateway-route-table.bicep - Dedicated Application Gateway route table
@description('Deployment location')
param location string
@description('Pre-computed route table name (from naming convention module).')
param routeTableName string
@description('Default route next hop IP (Firewall private IP)')
param firewallPrivateIp string
@description('Tags object')
param tags object = {}

resource appgwRouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

output routeTableId string = appgwRouteTable.id
