// appgateway-route-table.bicep - Dedicated Application Gateway route table
@description('Deployment location')
param location string
@description('Pre-computed route table name (from naming convention module).')
param routeTableName string
@description('Default route next hop IP (Firewall private IP)')
param firewallPrivateIp string
@description('Tags object')
param tags object = {}
@description('Optional list of internal CIDR prefixes (spoke/application VNets) to force through the firewall for east-west traffic from the App Gateway.')
param internalForcedPrefixes array = []
@description('Include the default 0.0.0.0/0 route to firewall')
param includeDefaultRoute bool = true

// NOTE: Child route resources are used instead of inline routes array with reference() to avoid compile-time evaluation restrictions.

resource appgwRouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
  }
}

// Default route
resource defaultRoute 'Microsoft.Network/routeTables/routes@2024-05-01' = if (includeDefaultRoute) {
  name: 'default-to-firewall'
  parent: appgwRouteTable
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: firewallPrivateIp
  }
}

// NOTE: Explicit per-spoke routes removed. Peered VNet address spaces will take the system peering route (more specific) and bypass firewall for east-west unless separate UDRs are authored elsewhere.
// Reintroduced (alternative) explicit prefix forcing: any provided internalForcedPrefixes will create UDRs to override system peering routes.

resource internalForcedRoutes 'Microsoft.Network/routeTables/routes@2024-05-01' = [for (p, i) in internalForcedPrefixes: if(!empty(p)) {
  name: format('int-{0}', i)
  parent: appgwRouteTable
  properties: {
    addressPrefix: p
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: firewallPrivateIp
  }
}]

output routeTableId string = appgwRouteTable.id
