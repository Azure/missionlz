@description('Name of the Azure Firewall (optional)')
param azureFirewallName string = ''

@description('Name of the subnet (optional)')
param subnetName string = ''

@description('The resource ID of the existing spoke virtual network (optional)')
param vnetResourceId string = ''

@description('The name of the route table associated with the hub virtual network (optional)')
param routeTableName string = ''

resource vnetRouteTable 'Microsoft.Network/routeTables@2020-11-01' existing = if (!empty(routeTableName) && !empty(vnetResourceId)) {
  scope: resourceGroup()
  name: routeTableName
}

// Retrieve internal address of the firewall, conditionally
resource azureFirewall 'Microsoft.Network/azureFirewalls@2020-11-01' existing = if (!empty(azureFirewallName) && !empty(vnetResourceId)) {
  scope: resourceGroup(split(vnetResourceId, '/')[2], split(vnetResourceId, '/')[4])
  name: azureFirewallName
}

// Reference the existing Virtual Network using its resource ID, conditionally
resource vnetInfo 'Microsoft.Network/virtualNetworks@2020-11-01' existing = if (!empty(vnetResourceId)) {
  scope: resourceGroup()
  name: last(split(vnetResourceId, '/')) // Extract the VNet name from the resource ID
}

// Loop through the subnets to find the specified subnet, conditionally
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = if (!empty(subnetName) && !empty(vnetResourceId)) {
  parent: vnetInfo
  name: subnetName
}

// Output the route table ID of the hub virtual network, if the route table name is provided
output routeTableId string = !empty(routeTableName) ? vnetRouteTable.id : 'N/A'

// Output the internal IP address of the firewall, if firewall parameters are provided
output firewallPrivateIp string = (!empty(azureFirewallName) && !empty(vnetResourceId)) ? azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress : 'N/A'

// Output the firewall policy id attached to the firewall
output firewallPolicyId string = !empty(azureFirewallName) ? azureFirewall.properties.firewallPolicy.id : 'N/A'

// Output the address prefix of the GatewaySubnet, if the parameters are provided
output subnetAddressPrefix string = (!empty(subnetName) && !empty(vnetResourceId)) ? subnet.properties.addressPrefix : 'N/A'

// Output the address space of the VNet, if the VNet resource ID is provided
output vnetAddressSpace array = !empty(vnetResourceId) ? vnetInfo.properties.addressSpace.addressPrefixes : []

// Output the list of peerings from the VNet, if the VNet resource ID is provided
output peeringsData object = !empty(vnetResourceId) ? {
  vnetResourceId: vnetResourceId
  peeringsList: vnetInfo.properties.virtualNetworkPeerings
} : {
  vnetResourceId: 'N/A'
  peeringsList: []
}
