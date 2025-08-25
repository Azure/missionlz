@description('The resource ID of the virtual network where the GatewaySubnet should exist')
param vnetResourceId string

@description('Name of the subnet to ensure exists (defaults to GatewaySubnet)')
param subnetName string = 'GatewaySubnet'

@description('CIDR address prefix to use when creating the subnet')
param subnetAddressPrefix string

// Reference the existing Virtual Network
resource existingVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: last(split(vnetResourceId, '/'))
}

// Create the subnet if it does not exist. If it exists, this will ensure the configuration matches the provided address prefix.
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: existingVnet
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
  }
}

output id string = gatewaySubnet.id
