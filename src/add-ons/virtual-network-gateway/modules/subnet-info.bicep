@description('Resource ID of the existing virtual network')
param vnetResourceId string
@description('Name of the subnet to inspect')
param subnetName string

var vnetSubscriptionId = split(vnetResourceId, '/')[2]
var vnetResourceGroupName = split(vnetResourceId, '/')[4]
var vnetName = split(vnetResourceId, '/')[8]

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  scope: resourceGroup(vnetSubscriptionId, vnetResourceGroupName)
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: vnet
  name: subnetName
}

output subnetAddressPrefix string = subnet.properties.addressPrefix
