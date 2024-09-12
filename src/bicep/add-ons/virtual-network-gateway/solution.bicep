targetScope = 'subscription'

@description('The name of the VPN Gateway.')
param vgwName string

@description('The Azure region location of the VPN Gateway.')
param vgwLocation string

@description('The names of the public IP addresses to use for the VPN Gateway.')
param vgwPublicIpAddressNames array

@description( 'The SKU of the VPN Gateway.')
@allowed(['VpnGw2', 'VpnGw3', 'VpnGw4', 'VpnGw5'])
param vgwSku string = 'VpnGw2'

@description('Local Network Gateway Name')
param localNetworkGatewayName string

@description('IP Address of the Local Network Gateway, must be a public IP address or be able to be connected to from MLZ network')
param localGatewayIpAddress string

@description('Address prefixes of the Local Network which will be routable through the VPN Gateway')
param localAddressPrefixes array

@description('The shared key to use for the VPN connection. If provided, the keyVaultCertificateUri parameter is ignored.')
@secure()
param sharedKey string = ''

@description('The URI of the Key Vault certificate to use for the VPN connection. If provided, the sharedKey parameter is ignored.')
param keyVaultCertificateUri string = ''

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param deploymentNameSuffix string = utcNow()

@description('The resource ID of the hub virtual network.')
param hubVirtualNetworkResourceId string

@description('List of peered networks that should use the VPN Gateway once configured.')
param vnetResourceIdList array

// Extracting the resource group name and virtual network name from the hub virtual network resource ID
var hubResourceGroupName = split(hubVirtualNetworkResourceId, '/')[4]
var hubVnetName = split(hubVirtualNetworkResourceId, '/')[8]
// var hubSubcriptionId = split(hubVirtualNetworkResourceId, '/')[2]

// calling Virtual Network Gateway Module
module vpnGatewayModule 'modules/vpn-gateway.bicep' = {
  name: 'vpnGatewayModule-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    vgwname: vgwName
    vgwlocation: vgwLocation
    publicIpAddressNames: vgwPublicIpAddressNames
    vgwsku: vgwSku
    vnetName: hubVnetName
  }
}

// calling Local Network Gateway Module
module localNetworkGatewayModule 'modules/local-network-gateway.bicep' = {
  name: 'localNetworkGatewayModule-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    vgwlocation: vgwLocation
    localNetworkGatewayName: localNetworkGatewayName
    gatewayIpAddress: localGatewayIpAddress
    addressPrefixes: localAddressPrefixes
  }
}

// calling VPN Connection Module
module vpnConnectionModule 'modules/vpn-connection.bicep' = {
  name: 'vpnConnectionModule-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    vpnConnectionName: '${vgwName}-to-${localNetworkGatewayName}'
    vgwlocation: vgwLocation
    vpnGatewayName: vgwName
    vpnGatewayResourceGroupName: hubResourceGroupName
    sharedKey: sharedKey
    keyVaultCertificateUri: keyVaultCertificateUri
    localNetworkGatewayName: localNetworkGatewayName
  }
  dependsOn: [
    vpnGatewayModule
    localNetworkGatewayModule
  ]
}

// Create a new array that includes both the original list and the hub VNet ID
var extendedVnetResourceIdList = union(vnetResourceIdList, [hubVirtualNetworkResourceId])

// Loop through the vnetResourceIdList and call the fetchVnetPeerings module for each VNet
module retrieveVnetPeerings 'modules/retrieve-vnet-peerings.bicep' = [for (vnetId, i) in extendedVnetResourceIdList: {
  name: 'retrieveVnetPeerings-${deploymentNameSuffix}-${i}'
  scope: resourceGroup(split(vnetId, '/')[2], split(vnetId, '/')[4]) // Resource group is at index 4 in the resource ID
  params: {
    vnetResourceId: vnetId
  }
}]

// Call the second module to update the peerings using the output from the first module
module updatePeerings 'modules/update-vnet-peerings.bicep' = [for (vnetId, i) in extendedVnetResourceIdList: {
  name: 'updatePeerings-${deploymentNameSuffix}-${i}'
  scope: resourceGroup(split(vnetId, '/')[2], split(vnetId, '/')[4])
  params: {
    vnetResourceId: retrieveVnetPeerings[i].outputs.peeringsData.vnetResourceId
    peeringsList: retrieveVnetPeerings[i].outputs.peeringsData.peeringsList
  }
}]






