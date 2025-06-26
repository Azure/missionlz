param vgwlocation string = resourceGroup().location
param localNetworkGatewayName string
param gatewayIpAddress string
param addressPrefixes array


// Local Network Gateway configuration
resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-02-01' = {
  name: localNetworkGatewayName
  location: vgwlocation
  properties: {
    gatewayIpAddress: gatewayIpAddress
    localNetworkAddressSpace: {
      addressPrefixes: addressPrefixes
    }
  }
}
