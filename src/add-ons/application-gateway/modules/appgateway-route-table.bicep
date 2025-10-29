// moved from root: appgateway-route-table.bicep
param location string
param routeTableName string
param firewallPrivateIp string
param tags object = {}
param internalForcedRouteEntries array = []
param includeDefaultRoute bool = true
resource appgwRouteTable 'Microsoft.Network/routeTables@2024-05-01' = { name: routeTableName, location: location, tags: tags, properties: { disableBgpRoutePropagation: false } }
resource defaultRoute 'Microsoft.Network/routeTables/routes@2024-05-01' = if (includeDefaultRoute) { name: 'default-to-firewall', parent: appgwRouteTable, properties: { addressPrefix: '0.0.0.0/0', nextHopType: 'VirtualAppliance', nextHopIpAddress: firewallPrivateIp } }
resource internalForcedRoutes 'Microsoft.Network/routeTables/routes@2024-05-01' = [for (e,i) in internalForcedRouteEntries: if(!empty(e) && !empty(e.prefix)) { name: toLower('${substring(uniqueString(e.prefix),0,5)}-${substring(replace(replace(e.source, '/', '-'), '.', '-'), 0, min(27, length(replace(replace(e.source, '/', '-'), '.', '-'))))}-${i}'), parent: appgwRouteTable, properties: { addressPrefix: e.prefix, nextHopType: 'VirtualAppliance', nextHopIpAddress: firewallPrivateIp } }]
output routeTableId string = appgwRouteTable.id