// appgateway-route-table.bicep - Dedicated Application Gateway route table
@description('Deployment location')
param location string
@description('Pre-computed route table name (from naming convention module).')
param routeTableName string
@description('Default route next hop IP (Firewall private IP)')
param firewallPrivateIp string
@description('Tags object')
param tags object = {}
@description('Optional list of peered VNet resource IDs whose address space prefixes will be forced through the firewall (duplicates ignored).')
param peeredVnetResourceIds array = []
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

// Dedupe and create one route per unique VNet (first prefix only due to ARM/Bicep limitations on iterating dynamic addressSpace at compile time)
var uniqueVnetIds = [for (vnetId, i) in peeredVnetResourceIds: (!empty(vnetId) && indexOf(peeredVnetResourceIds, vnetId) == i) ? vnetId : '']

resource peeredRoutes 'Microsoft.Network/routeTables/routes@2024-05-01' = [for (vnetId, i) in uniqueVnetIds: if(!empty(vnetId)) {
  name: toLower(replace(replace(format('{0}-spoke-{1}', last(split(vnetId,'/')), string(i)), '.', '-'), '--', '-'))
  parent: appgwRouteTable
  properties: {
    addressPrefix: reference(vnetId, '2024-05-01').properties.addressSpace.addressPrefixes[0]
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: firewallPrivateIp
  }
}]

output routeTableId string = appgwRouteTable.id
