targetScope = 'subscription'

@description('Azure address prefixes allowed to communicate to VPN Gateway to on-premises network')
param allowedAzureAddressPrefixes array = [
  '10.0.130.0/24'
  '10.0.131.0/24'
  '10.0.132.0/24'
  '10.0.128.0/23'
]

@description('The name of the Azure Firewall to retrieve the internal IP address from.')
param azureFirewallResourceId string

@description('The firewall rules that will be applied to the Azure Firewall.')
param customFirewallRuleCollectionGroups array = []

@description('A suffix to use for naming deployments uniquely.')
param deploymentNameSuffix string = utcNow()

@description('The name of the gateway subnet')
param gatewaySubnetName string = 'GatewaySubnet'

@description('The resource ID of the hub virtual network.')
param hubVirtualNetworkResourceId string

@description('The name of the hub virtual network route table')
param hubVnetRouteTableResourceId string

@description('Address prefixes of the Local Network which will be routable through the VPN Gateway')
param localAddressPrefixes array

@description('IP Address of the Local Network Gateway, must be a public IP address or be able to be connected to from MLZ network')
param localGatewayIpAddress string

@description('Local Network Gateway Name')
param localNetworkGatewayName string

@description('The URI of the Key Vault certificate to use for the VPN connection. If using a Key Vault certificate, this must be a valid URI.')
param keyVaultCertificateUri string = ''

@description('The shared key to use for the VPN connection. If using the shared key, this must be provided.')
@secure()
param sharedKey string

@description('Choose whether to use a shared key or Key Vault certificate URI for the VPN connection.')
param useSharedKey bool

@description('The Azure region location of the VPN Gateway.')
param vgwLocation string

@description('The name of the VPN Gateway.')
param vgwName string

@description('The names of the public IP addresses to use for the VPN Gateway.')
param vgwPublicIpAddressNames array

@description('The name of the vgw route table to create')
param vgwRouteTableName string

@description('The SKU of the VPN Gateway.')
@allowed(['VpnGw2', 'VpnGw3', 'VpnGw4', 'VpnGw5'])
param vgwSku string

@description('List of peered networks that should use the VPN Gateway once configured.')
param vnetResourceIdList array

var azureFirewallName = split(azureFirewallResourceId, '/')[8]
var hubResourceGroupName = split(hubVirtualNetworkResourceId, '/')[4]
var hubVnetName = split(hubVirtualNetworkResourceId, '/')[8]
var hubVnetRouteTableName = split(hubVnetRouteTableResourceId, '/')[8]
var isValidUri = contains(keyVaultCertificateUri, 'https://') && contains(keyVaultCertificateUri, '/secrets/')
var vpnKeyVaultUri = !useSharedKey ? keyVaultCertificateUri : ''
var vpnSharedKey = useSharedKey ? sharedKey : ''

resource azureFirewall 'Microsoft.Network/azureFirewalls@2020-11-01' existing = {
  name: split(azureFirewallResourceId, '/')[8]
  scope: resourceGroup(split(azureFirewallResourceId, '/')[2], split(azureFirewallResourceId, '/')[4])
}

// Retrieve the Firewall Policy Resource ID
var firewallPolicyResourceId = azureFirewall.properties.firewallPolicy.id
module firewallRules '../../modules/firewall-rules.bicep' = {
  name: 'deploy-vgw-firewall-rules-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    firewallPolicyName: split(firewallPolicyResourceId, '/')[8]
    firewallRuleCollectionGroups: empty(customFirewallRuleCollectionGroups) ? [
      {
        name: 'VGW-NetworkCollectionGroup'
        properties: {
          priority: 300
          ruleCollections: [
            {
              name: 'AllowAllTraffic'
              priority: 150
              ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
              action: {
                type: 'Allow'
              }
              rules: [
                {
                  name: 'AllowAzureToOnPrem'
                  ruleType: 'NetworkRule'
                  ipProtocols: ['Any']
                  sourceAddresses: localAddressPrefixes
                  destinationAddresses: allowedAzureAddressPrefixes
                  destinationPorts: ['*']
                  sourceIpGroups: []
                  destinationIpGroups: []
                  destinationFqdns: []
                }
                {
                  name: 'AllowOnPremToAzure'
                  ruleType: 'NetworkRule'
                  ipProtocols: ['Any']
                  sourceAddresses: allowedAzureAddressPrefixes
                  destinationAddresses: localAddressPrefixes
                  destinationPorts: ['*']
                  sourceIpGroups: []
                  destinationIpGroups: []
                  destinationFqdns: []
                }
              ]
            }
          ]
        }
      }
    ] : customFirewallRuleCollectionGroups
  }
}

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

// calling Virtual Network Gateway Module
module vpnGatewayModule 'modules/vpn-gateway.bicep' = {
  name: 'vpnGateway-${deploymentNameSuffix}'
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
  name: 'localNetworkGateway-${deploymentNameSuffix}'
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
  name: 'vpnConnection-${deploymentNameSuffix}'
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
module retrieveVnetInfo 'modules/retrieve-existing.bicep' = [for (vnetId, i) in vnetResourceIdList: {
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
module retrieveHubVnetInfo 'modules/retrieve-existing.bicep' = {
  name: 'retrieveHubVnetPeerings-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: hubVirtualNetworkResourceId
  }
  dependsOn: [
    vpnConnectionModule
  ]
}

// retrieve the route table information for the hub vnet including the firewall private IP and gateway subnet address space info to be used for the new vgw route table and routes
module retrieveRouteTableInfo 'modules/retrieve-existing.bicep' = {
  name: 'retrieveRouteTableInfo-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: hubVirtualNetworkResourceId
    azureFirewallName: azureFirewallName
    subnetName: gatewaySubnetName
  }
  dependsOn: [
    updatePeerings
  ]
}

// Call update the Hub peerings first to enable spokes to use the VPN Gateway, if not done first, spokes will fail their update
module updateHubPeerings 'modules/vnet-peerings.bicep' = {
  name: 'updateHubPeerings-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: retrieveHubVnetInfo.outputs.peeringsData.vnetResourceId
    peeringsList: retrieveHubVnetInfo.outputs.peeringsData.peeringsList
  }
  dependsOn: [
    retrieveVnetInfo
  ]
}


// Update the peerings for each spoke VNet to use the VPN Gateway
module updatePeerings 'modules/vnet-peerings.bicep' = [for (vnetId, i) in vnetResourceIdList: {
  name: 'updatePeerings-${deploymentNameSuffix}-${i}'
  scope: resourceGroup(split(vnetId, '/')[2], split(vnetId, '/')[4])
  params: {
    vnetResourceId: retrieveVnetInfo[i].outputs.peeringsData.vnetResourceId
    peeringsList: retrieveVnetInfo[i].outputs.peeringsData.peeringsList
  }
  dependsOn: [
    retrieveVnetInfo
    updateHubPeerings
  ]
}]

// Create the route table for the VPN Gateway subnet, will route spoke vnets to through the firewall, overriding default behavior
module createRouteTable 'modules/route-table.bicep' = {
  name: 'createVgwRouteTable-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    routeTableName: vgwRouteTableName
  }
  dependsOn: [
    retrieveVnetInfo
    retrieveRouteTableInfo
    updateHubPeerings
    updatePeerings
  ]
}

// Create the routes to the firewall for the spoke vnets, if vnet is not provided in the "allowedAzureAddressPrefixes" then the spoke will not be able to use the VPN Gateway
module createRoutes 'modules/routes.bicep' = [for (vnetResourceId, i) in vnetResourceIdList: {
  name: 'createRoute-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    routeTableName: vgwRouteTableName
    addressSpace: retrieveVnetInfo[i].outputs.vnetAddressSpace
    routeName: 'route-${i}'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: retrieveRouteTableInfo.outputs.firewallPrivateIp
  }
  dependsOn: [
    createRouteTable
  ]
}]

// Create the routes to the firewall for the hub vnet as and override to the onprem networks
module createHubRoutesToOnPrem 'modules/routes.bicep' = {
  name: 'createOverrideRoutes-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    routeTableName: hubVnetRouteTableName
    addressSpace: localAddressPrefixes
    routeName: 'route-onprem-override'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: retrieveRouteTableInfo.outputs.firewallPrivateIp
  }
  dependsOn: [
    createRouteTable
  ]
}


// Associate the vgw route table with the gateway subnet so the gateway routes traffic destined for spokes through the firewall
module associateRouteTable 'modules/associate-route-table.bicep' = {
  name: 'associateRouteTable-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: hubVirtualNetworkResourceId
    routeTableResourceId: createRouteTable.outputs.routeTableId
    subnetName: gatewaySubnetName
    subnetAddressPrefix: retrieveRouteTableInfo.outputs.subnetAddressPrefix
  }
}

