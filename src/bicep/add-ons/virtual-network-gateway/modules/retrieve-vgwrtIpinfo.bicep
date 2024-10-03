@description('Name of the Azure Firewall to retrieve the internal IP address from.')
param firewallName string 

@description('The resource ID of the virtual network.')
param vnetResourceId string

param subnetName string

// Reference the existing Azure Firewall resource
resource azureFirewall 'Microsoft.Network/azureFirewalls@2020-11-01' existing = {
  name: firewallName
}

// Reference the existing Virtual Network using its resource ID
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  scope: resourceGroup()
  name: last(split(vnetResourceId, '/')) // Extract the VNet name from the resource ID
}

// Loop through the subnets to find "GatewaySubnet"
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  parent: vnet
  name: subnetName
}


// Output the internal IP address of the firewall
output firewallPrivateIp string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress

// Output the address space of the virtual network
output vnetAddressPrefixes array = vnet.properties.addressSpace.addressPrefixes

// Output the address prefix of the GatewaySubnet (if found)
output gwSubnetAddressPrefix string = gatewaySubnet.properties.addressPrefix

