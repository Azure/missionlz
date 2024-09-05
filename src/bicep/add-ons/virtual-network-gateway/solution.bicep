param vgwname string
param vgwlocation string = resourceGroup().location

// public ip address names can be auto generated using the naming generator in MLZ  so this is temporary for testing purposes
param publicIpAddressNames array
param vgwsku string
param vnetName string
param localNetworkGatewayName string
param gatewayIpAddress string
param addressPrefixes array

@description('The shared key to use for the VPN connection. If provided, the keyVaultCertificateUri parameter is ignored.')
param sharedKey string = ''

@description('The URI of the Key Vault certificate to use for the VPN connection. If provided, the sharedKey parameter is ignored.')
param keyVaultCertificateUri string = ''

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param deploymentNameSuffix string = utcNow()


// calling Virtual Network Gateway Module
module vpnGatewayModule 'modules/vpn-gateway.bicep' = {
  name: 'vpnGatewayModule-${deploymentNameSuffix}'
  scope: resourceGroup()
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
  scope: resourceGroup()
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
  scope: resourceGroup()
  params: {
    vpnConnectionName: '${vgwname}-to-${localNetworkGatewayName}'
    vgwlocation: vgwlocation
    vpnGatewayName: vgwname
    vpnGatewayResourceGroupName: resourceGroup().name
    sharedKey: sharedKey
    keyVaultCertificateUri: keyVaultCertificateUri
    localNetworkGatewayName: localNetworkGatewayName
  }
}
