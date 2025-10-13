// appgateway-route-table.bicep - Dedicated Application Gateway route table
@description('Deployment location')
param location string
@description('Pre-computed route table name (from naming convention module).')
param routeTableName string
@description('Default route next hop IP (Firewall private IP)')
param firewallPrivateIp string
@description('Tags object')
param tags object = {}
@description('Optional additional address prefixes (spoke VNets) to force through the firewall (one route per prefix).')
param peeredAddressPrefixes array = []

// Base default route
var baseRoutes = [
  {
    name: 'default-to-firewall'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: firewallPrivateIp
    }
  }
]

// Additional routes generated per provided prefix
var additionalRoutes = [for (prefix, i) in peeredAddressPrefixes: {
  name: length(format('spoke-{0}', replace(prefix, '/', '-'))) <= 80 ? format('spoke-{0}', replace(prefix, '/', '-')) : format('spk-{0}', i)
  properties: {
    addressPrefix: prefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: firewallPrivateIp
  }
}]

resource appgwRouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: concat(baseRoutes, additionalRoutes)
  }
}

output routeTableId string = appgwRouteTable.id
