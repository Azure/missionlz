targetScope = 'subscription'

@description('The name of the VPN Gateway.')
param vgwName string

@description('The Azure region location of the VPN Gateway.')
param vgwLocation string

@description('The names of the public IP addresses to use for the VPN Gateway.')
param vgwPublicIpAddressNames array

@description('The SKU of the VPN Gateway.')
@allowed(['VpnGw2', 'VpnGw3', 'VpnGw4', 'VpnGw5'])
param vgwSku string = 'VpnGw2'

@description('Local Network Gateway Name')
param localNetworkGatewayName string

@description('IP Address of the Local Network Gateway, must be a public IP address or be able to be connected to from MLZ network')
param localGatewayIpAddress string

@description('Address prefixes of the Local Network which will be routable through the VPN Gateway')
param localAddressPrefixes array

@description('Choose whether to use a shared key or Key Vault certificate URI for the VPN connection.')
param useSharedKey bool

@description('The shared key to use for the VPN connection. If using the shared key, this must be provided.')
@secure()
param sharedKey string

@description('The URI of the Key Vault certificate to use for the VPN connection. If using a Key Vault certificate, this must be a valid URI.')
param keyVaultCertificateUri string = ''

@description('A suffix to use for naming deployments uniquely.')
param deploymentNameSuffix string = utcNow()

@description('The resource ID of the hub virtual network.')
param hubVirtualNetworkResourceId string

@description('List of peered networks that should use the VPN Gateway once configured.')
param vnetResourceIdList array

@description('The name of the Azure Firewall to retrieve the internal IP address from.')
param azureFirewallName string

@description('The name of the vgw route table to create')
param vgwRouteTableName string

// Parameter validation
var isValidUri = contains(keyVaultCertificateUri, 'https://') && contains(keyVaultCertificateUri, '/secrets/')

// Conditional validation to ensure either sharedKey or keyVaultCertificateUri is used correctly
resource validateKeyOrUri 'Microsoft.Resources/deployments@2021-04-01' = if (!useSharedKey && !isValidUri) {
  name: 'InvalidKeyVaultCertificateUri-${deploymentNameSuffix}'
  properties: {
    mode: 'Incremental'
    parameters: {
      message: {
        value: 'Invalid Key Vault Certificate URI. It must start with "https://" and contain "/secrets/".'
      }
    }
    templateLink: {
      uri: 'https://validatemessage.com' // Placeholder for validation message, replace if needed
    }
  }
}

// Extracting the resource group name and virtual network name from the hub virtual network resource ID
var hubResourceGroupName = split(hubVirtualNetworkResourceId, '/')[4]
var hubVnetName = split(hubVirtualNetworkResourceId, '/')[8]

// Conditional parameter assignment for VPN connection module
var vpnSharedKey = useSharedKey ? sharedKey : ''
var vpnKeyVaultUri = !useSharedKey ? keyVaultCertificateUri : ''

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
    sharedKey: vpnSharedKey
    keyVaultCertificateUri: vpnKeyVaultUri
    localNetworkGatewayName: localNetworkGatewayName
  }
  dependsOn: [
    vpnGatewayModule
    localNetworkGatewayModule
    validateKeyOrUri
  ]
}

// Loop through the vnetResourceIdList and to retrieve the peerings for each VNet
module retrieveVnetPeerings 'modules/retrieve-vnet-peerings.bicep' = [for (vnetId, i) in vnetResourceIdList: {
  name: 'retrieveVnetPeerings-${deploymentNameSuffix}-${i}'
  scope: resourceGroup(split(vnetId, '/')[2], split(vnetId, '/')[4])
  params: {
    vnetResourceId: vnetId
  }
  dependsOn: [
    vpnConnectionModule
  ]
}]

// Get the hub virtual network peerings
module retrieveHubVnetPeerings 'modules/retrieve-vnet-peerings.bicep' = {
  name: 'retrieveHubVnetPeerings-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: hubVirtualNetworkResourceId
  }
  dependsOn: [
    vpnConnectionModule
  ]
}

// Call update the Hub peerings first to enable spokes to use the VPN Gateway, if not done first, spokes will fail their update
module updateHubPeerings 'modules/update-vnet-peerings.bicep' = {
  name: 'updateHubPeerings-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: retrieveHubVnetPeerings.outputs.peeringsData.vnetResourceId
    peeringsList: retrieveHubVnetPeerings.outputs.peeringsData.peeringsList
  }
  dependsOn: [
    retrieveHubVnetPeerings
    retrieveVnetPeerings
  ]
}


// Update the peerings for each spoke VNet to use the VPN Gateway
module updatePeerings 'modules/update-vnet-peerings.bicep' = [for (vnetId, i) in vnetResourceIdList: {
  name: 'updatePeerings-${deploymentNameSuffix}-${i}'
  scope: resourceGroup(split(vnetId, '/')[2], split(vnetId, '/')[4])
  params: {
    vnetResourceId: retrieveVnetPeerings[i].outputs.peeringsData.vnetResourceId
    peeringsList: retrieveVnetPeerings[i].outputs.peeringsData.peeringsList
  }
  dependsOn: [
    updateHubPeerings
  ]
}]

module retrieveRouteTableInfo 'modules/retrieve-vgwrtIpinfo.bicep' = {
  name: 'retrieveRouteTableInfo-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: hubVirtualNetworkResourceId
    firewallName: azureFirewallName
    subnetName: 'GatewaySubnet'
  }
  dependsOn: [
    updatePeerings
  ]
}


module createRouteDef 'modules/create-routedef.bicep' = {
  name: 'createRouteDef-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    hubVnetAddressSpace: retrieveRouteTableInfo.outputs.vnetAddressPrefixes
    firewallPrivateIp: retrieveRouteTableInfo.outputs.firewallPrivateIp
  }
  dependsOn: [
    retrieveRouteTableInfo
  ]
}

module createRouteTable 'modules/route-table.bicep' = {
  name: 'createRouteTable-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    routes: createRouteDef.outputs.routes // Pass the variable containing the routes
    routeTableName: vgwRouteTableName
  }
  dependsOn: [
    createRouteDef
  ]
}

module associateRouteTable 'modules/associate-rttosubnet.bicep' = {
  name: 'associateRouteTable-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: hubVirtualNetworkResourceId
    routeTableResourceId: createRouteTable.outputs.routeTableId
    subnetName: 'GatewaySubnet'
    gwSubnetAddressPrefix: retrieveRouteTableInfo.outputs.gwSubnetAddressPrefix
  }
  dependsOn: [
    createRouteTable
  ]
}

