param delimiter string
param location string
param publicIpAddressName string
param virtualNetworkGatewayName string
param virtualNetworkGatewaySku string
param virtualNetworkName string

// Existing Virtual Network and Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  name: virtualNetworkName
}

// Reference the existing subnet within the specified Virtual Network
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: vnet
  name: 'GatewaySubnet'
}

var gatewaySubnetId = gatewaySubnet.id

// Public IP Addresses
resource publicIpAddresses 'Microsoft.Network/publicIPAddresses@2023-02-01' = [
  for i in range(0, 2): {
    name: '${publicIpAddressName}${delimiter}${padLeft(i, 2, '0')}'
    location: location
    sku: {
      name: 'Standard'
    }
    properties: {
      publicIPAllocationMethod: 'Static'
    }
  }
]

var firstPublicIpAddressId = publicIpAddresses[0].id
var secondPublicIpAddressId = publicIpAddresses[1].id

// VPN Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-02-01' = {
  name: virtualNetworkGatewayName
  location: location
  properties: {
    gatewayType: 'Vpn'
    ipConfigurations: [
      {
        name: 'first'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: firstPublicIpAddressId
          }
        }
      }
      {
        name: 'second'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: secondPublicIpAddressId
          }
          subnet: {
            id: gatewaySubnetId
          }
        }
      }
    ]
    activeActive: true
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    enableBgp: false
    enablePrivateIpAddress: false
    sku: {
      name: virtualNetworkGatewaySku
      tier: virtualNetworkGatewaySku
    }
  }
}
