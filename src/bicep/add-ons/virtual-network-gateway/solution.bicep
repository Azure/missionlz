targetScope = 'subscription'

@description('The name of the VPN Gateway.')
param vgwname string

@description('The location of the VPN Gateway.')
param vgwlocation string

@description('The names of the public IP addresses to use for the VPN Gateway.')
param publicIpAddressNames array

@description( 'The SKU of the VPN Gateway.')
@allowed(['VpnGw1', 'VpnGw2', 'VpnGw3', 'VpnGw4', 'VpnGw5'])
param vgwsku string
param vnetName string
param localNetworkGatewayName string
param gatewayIpAddress string
param addressPrefixes array

@description('The shared key to use for the VPN connection. If provided, the keyVaultCertificateUri parameter is ignored.')
@secure()
param sharedKey string = ''

@description('The URI of the Key Vault certificate to use for the VPN connection. If provided, the sharedKey parameter is ignored.')
param keyVaultCertificateUri string = ''

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param deploymentNameSuffix string = utcNow()

@description('The resource ID of the hub virtual network.')
param hubVirtualNetworkResourceId string

@description('The name of the hub virtual network resource group.')
var hubResourceGroupName = split('/', hubVirtualNetworkResourceId)[4]

// calling Virtual Network Gateway Module
module vpnGatewayModule 'modules/vpn-gateway.bicep' = {
  name: 'vpnGatewayModule-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    vgwname: vgwname
    vgwlocation: vgwlocation
    publicIpAddressNames: publicIpAddressNames
    vgwsku: vgwsku
    vnetName: vnetName
  }
}

// calling Local Network Gateway Module
module localNetworkGatewayModule 'modules/local-network-gateway.bicep' = {
  name: 'localNetworkGatewayModule-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    vgwlocation: vgwlocation
    localNetworkGatewayName: localNetworkGatewayName
    gatewayIpAddress: gatewayIpAddress
    addressPrefixes: addressPrefixes
  }
}

// calling VPN Connection Module
module vpnConnectionModule 'modules/vpn-connection.bicep' = {
  name: 'vpnConnectionModule-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    vpnConnectionName: '${vgwname}-to-${localNetworkGatewayName}'
    vgwlocation: vgwlocation
    vpnGatewayName: vgwname
    vpnGatewayResourceGroupName: hubResourceGroupName
    sharedKey: sharedKey
    keyVaultCertificateUri: keyVaultCertificateUri
    localNetworkGatewayName: localNetworkGatewayName
  }
}
