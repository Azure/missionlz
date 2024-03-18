targetScope = 'subscription'

param azureNetAppFilesSubnetAddressPrefix string
param disableBgpRoutePropagation bool
param hubAzureFirewallResourceId string
param hubVirtualNetworkResourceId string
param index int
param location string
param networkSecurityGroupName string
param subnetAddressPrefixes array
param resourceGroupNetwork string
param routeTableName string
param timestamp string
param virtualNetworkAddressPrefixes array
param virtualNetworkName string

var hubSubscriptionId = split(hubVirtualNetworkResourceId, '/')[2]
var hubVirtualNetworkName = split(hubVirtualNetworkResourceId, '/')[8]
var hubVirtualNetworkResourceGroupName = split(hubVirtualNetworkResourceId, '/')[4]
var networkSecurityGroupSecurityRules = []
var spokeResourceGroup = resourceGroupNetwork
var spokeSubscriptionId = subscription().subscriptionId
var subnets = union(subnetWorkload, subnetAnf)
var subnetAnf = empty(azureNetAppFilesSubnetAddressPrefix) ? [] : [
  {
    name: 'AzureNetAppFiles'
    addressPrefix: azureNetAppFilesSubnetAddressPrefix
    delegations: [
      {
        name: 'Microsoft.Netapp.volumes'
        id: '${resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AzureNetAppFiles')}/delegations/Microsoft.Netapp.volumes'
        properties: {
          serviceName: 'Microsoft.Netapp/volumes'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
    networkSecurityGroupName: networkSecurityGroupName
  }
]
var subnetWorkload = [
  {
    name: 'AzureVirtualDesktop'
    addressPrefix: subnetAddressPrefixes[index]
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
    networkSecurityGroupName: networkSecurityGroupName
  }
]

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  scope: resourceGroup(hubSubscriptionId, hubVirtualNetworkResourceGroupName)
  name: hubVirtualNetworkName
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-05-01' existing = {
  scope: resourceGroup(split(hubAzureFirewallResourceId, '/')[2], split(hubAzureFirewallResourceId, '/')[4])
  name: split(hubAzureFirewallResourceId, '/')[8]
}

module userDefinedRoute 'userDefinedRoute.bicep' = {
  name: 'UserDefinedRoute_${index}_${timestamp}'
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroup)
  params: {
    azureFirewallIpAddress: azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
    disableBgpRoutePropagation: disableBgpRoutePropagation
    location: location
    udrName: routeTableName
  }
}

module networkSecurityGroup 'networkSecurityGroup.bicep' = {
  name: 'NetworkSecurityGroup_${index}_${timestamp}'
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroup)
  params: {
    location: location
    networkSecurityGroupName: networkSecurityGroupName
    networkSecurityGroupSecurityRules: networkSecurityGroupSecurityRules
  }
}

module spokeVirtualNetwork 'virtualNetwork.bicep' = {
  name: 'VirtualNetwork_${index}_${timestamp}'
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroup)
  params: {
    dnsServers: contains(hubVirtualNetwork.properties, 'dhcpOptions') ? hubVirtualNetwork.properties.dhcpOptions.dnsServers : []
    location: location
    subnets: subnets
    udrName: userDefinedRoute.outputs.name
    virtualNetworkName: virtualNetworkName
    vNetAddressPrefixes: [
      virtualNetworkAddressPrefixes[index]
    ]
  }
}

module virtualNetworkPeeringToHub 'virtualNetworkPeering.bicep' = {
  name: 'VirtualNetworkPeer_Hub_${index}_${timestamp}'
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroup)
  params: {
    existingLocalVirtualNetworkName: spokeVirtualNetwork.outputs.virtualNetworkName
    existingRemoteVirtualNetworkName: hubVirtualNetwork.name
    existingRemoteVirtualNetworkResourceGroupName: hubVirtualNetworkResourceGroupName
  }
}

module virtualNetworkPeeringToSpoke 'virtualNetworkPeering.bicep' = {
  name: 'VirtualNetworkPeer_Spoke_${index}_${timestamp}'
  scope: resourceGroup(hubSubscriptionId, hubVirtualNetworkResourceGroupName)
  params: {
    existingLocalVirtualNetworkName: hubVirtualNetwork.name
    existingRemoteVirtualNetworkName: spokeVirtualNetwork.outputs.virtualNetworkName
    existingRemoteVirtualNetworkResourceGroupName: spokeResourceGroup
  }
  dependsOn: [
    virtualNetworkPeeringToHub
  ]
}

output subnetResourceId string = spokeVirtualNetwork.outputs.subnetResourceId
