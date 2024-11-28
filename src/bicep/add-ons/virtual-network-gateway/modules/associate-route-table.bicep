
@description('virtual network resource ID that holds the subnet')
param vnetResourceId string

@description('route table resource ID to associate with the subnet')
param routeTableResourceId string

@description('name of the subnet to associate with the route table')
param subnetName string

@description('address prefix of the gateway subnet')
param subnetAddressPrefix string

// Reference the existing Virtual Network
resource existingVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: last(split(vnetResourceId, '/'))
}  

// Update the GatewaySubnet to associate the existing Route Table
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: existingVnet
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    routeTable: {
      id: resourceId('Microsoft.Network/routeTables', last(split(routeTableResourceId, '/')))
    }
  }
}
