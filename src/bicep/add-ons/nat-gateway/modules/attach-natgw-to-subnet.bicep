@description('The name of the VNet containing the subnet.')
param vnetName string

@description('The name of the subnet to attach the NAT Gateway to.')
param subnetName string

@description('The resource ID of the NAT Gateway.')
param natGatewayId string

@description('The address prefix of the subnet.')
param addressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: addressPrefix
    natGateway: {
      id: natGatewayId
    }
  }
}
