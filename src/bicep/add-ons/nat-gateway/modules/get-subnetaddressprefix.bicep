@description('The name of the VNet containing the subnet.')
param vnetName string

@description('The name of the subnet.')
param subnetName string

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: subnetName
  parent: vnet
}

output addressPrefix string = subnet.properties.addressPrefix
