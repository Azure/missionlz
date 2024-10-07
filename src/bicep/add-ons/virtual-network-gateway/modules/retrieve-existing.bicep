@description('Hub virtual network resource ID (optional)')
param hubVirtualNetworkResourceId string = ''

@description('Name of the Azure Firewall (optional)')
param azureFirewallName string = ''

@description('Name of the subnet (optional)')
param subnetName string = ''

@description('The resource ID of the existing spoke virtual network (optional)')
param vnetResourceId string = ''

// Retrieve internal address of the firewall, conditionally
resource azureFirewall 'Microsoft.Network/azureFirewalls@2020-11-01' existing = if (!empty(azureFirewallName) && !empty(hubVirtualNetworkResourceId)) {
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  name: azureFirewallName
}

// Reference the existing Virtual Network using its resource ID, conditionally
resource vnetFromFirewall 'Microsoft.Network/virtualNetworks@2020-11-01' existing = if (!empty(hubVirtualNetworkResourceId)) {
  scope: resourceGroup()
  name: last(split(hubVirtualNetworkResourceId, '/')) // Extract the VNet name from the resource ID
}

// Loop through the subnets to find the specified subnet, conditionally
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = if (!empty(subnetName) && !empty(hubVirtualNetworkResourceId)) {
  parent: vnetFromFirewall
  name: subnetName
}

// Define the existing VNet resource for peerings, conditionally
resource vnetForPeerings 'Microsoft.Network/virtualNetworks@2022-07-01' existing = if (!empty(vnetResourceId)) {
  name: last(split(vnetResourceId, '/'))
  scope: resourceGroup(split(vnetResourceId, '/')[2], split(vnetResourceId, '/')[4])
}

// Outputs

// Output the internal IP address of the firewall, if firewall parameters are provided
output firewallPrivateIp string = (!empty(azureFirewallName) && !empty(hubVirtualNetworkResourceId)) ? azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress : 'N/A'

// Output the address prefix of the GatewaySubnet, if the parameters are provided
output gwSubnetAddressPrefix string = (!empty(subnetName) && !empty(hubVirtualNetworkResourceId)) ? gatewaySubnet.properties.addressPrefix : 'N/A'

// Output the list of peerings from the VNet, if the VNet resource ID is provided
output peeringsData object = !empty(vnetResourceId) ? {
  vnetResourceId: vnetResourceId
  peeringsList: vnetForPeerings.properties.virtualNetworkPeerings
} : {
  vnetResourceId: 'N/A'
  peeringsList: []
}
