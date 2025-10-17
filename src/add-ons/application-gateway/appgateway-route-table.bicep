// appgateway-route-table.bicep - Dedicated Application Gateway route table
@description('Deployment location')
param location string
@description('Pre-computed route table name (from naming convention module).')
param routeTableName string
@description('Default route next hop IP (Firewall private IP)')
param firewallPrivateIp string
@description('Tags object')
param tags object = {}
@description('Optional list of internal prefix route entries: objects { prefix: CIDR, source: app/listener name }. Used to force east-west traffic through Firewall.')
param internalForcedRouteEntries array = []
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

resource internalForcedRoutes 'Microsoft.Network/routeTables/routes@2024-05-01' = [for (e, i) in internalForcedRouteEntries: if(!empty(e) && !empty(e.prefix)) {
  // Deterministic route name pattern: <hash>-<source>-<idx>
  // hash = first 5 chars of uniqueString(prefix) (stable per prefix)
  // source truncated to 27 chars, sanitized for name safety; index ensures uniqueness when same prefix/source repeats
  // This keeps names stable (idempotent) across redeploys as long as prefix & source ordering stay consistent.
  name: toLower('${substring(uniqueString(e.prefix),0,5)}-${substring(replace(replace(e.source, '/', '-'), '.', '-'), 0, min(27, length(replace(replace(e.source, '/', '-'), '.', '-'))))}-${i}')
  parent: appgwRouteTable
  properties: {
    addressPrefix: e.prefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: firewallPrivateIp
  }
}]

output routeTableId string = appgwRouteTable.id
