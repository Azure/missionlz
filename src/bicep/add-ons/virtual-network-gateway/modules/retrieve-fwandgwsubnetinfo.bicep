@description('Hub virtual network resource ID')
param hubVirtualNetworkResourceId string

@description('Name of the Azure Firewall')
param azureFirewallName string

@description('Name of the subnet')
param subnetName string

//retrieve internal address of the firewall
resource azureFirewall 'Microsoft.Network/azureFirewalls@2020-11-01' existing = {
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  name: azureFirewallName
}

// Reference the existing Virtual Network using its resource ID
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  scope: resourceGroup()
  name: last(split(hubVirtualNetworkResourceId, '/')) // Extract the VNet name from the resource ID
}

// Loop through the subnets to find "GatewaySubnet"
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  parent: vnet
  name: subnetName
}

// Output the internal IP address of the firewall
output firewallPrivateIp string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress

// Output the address prefix of the GatewaySubnet (if found)
output gwSubnetAddressPrefix string = gatewaySubnet.properties.addressPrefix
