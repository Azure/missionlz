@description('Hub virtual network resource ID')
param hubVirtualNetworkResourceId string

@description('Name of the Azure Firewall')
param azureFirewallName string

//retrieve internal address of the firewall
resource azureFirewall 'Microsoft.Network/azureFirewalls@2020-11-01' existing = {
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  name: azureFirewallName
}
// Output the internal IP address of the firewall
output firewallPrivateIp string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress

// Reference the existing Virtual Network using its resource ID
resource hubVnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  name: last(split(hubVirtualNetworkResourceId, '/')) // Extract the VNet name from the resource ID
}
// Output the address space of the virtual network
output hubVnetAddressSpace array = hubVnet.properties.addressSpace.addressPrefixes

