targetScope = 'subscription'

param deploymentNameSuffix string
param deployNetworkWatcher bool
param firewallSkuTier string
param hubVirtualNetworkResourceId string
param location string
param networkSecurityGroupName string
param networkSecurityGroupRules array
param networkWatcherName string
param resourceGroupName string
param routeTableName string
param routeTableRouteNextHopIpAddress string
param subnetAddressPrefix string
param subnetName string
param subscriptionId string
param tags object
param vNetDnsServers array
param virtualNetworkAddressPrefix string
param virtualNetworkName string
param workloadName string
param workloadShortName string

module spokeNetwork '../../../modules/spoke-network.bicep' = {
  name: 'spokeNetwork'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    tags: tags
    location:location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    vNetDnsServers: vNetDnsServers
    networkSecurityGroupName: networkSecurityGroupName
    networkSecurityGroupRules: networkSecurityGroupRules
    subnetName: subnetName
    subnetAddressPrefix: subnetAddressPrefix
    subnetPrivateEndpointNetworkPolicies: 'Disabled'
    subnetPrivateLinkServiceNetworkPolicies: 'Disabled'
    deployNetworkWatcher: deployNetworkWatcher
    firewallSkuTier: firewallSkuTier
    networkWatcherName: networkWatcherName
    routeTableName: routeTableName
    routeTableRouteNextHopIpAddress: routeTableRouteNextHopIpAddress
  }
}

module workloadVirtualNetworkPeerings '../../../modules/spoke-network-peering.bicep' = {
  name: 'deploy-vnet-peering-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    spokeName: workloadName
    spokeResourceGroupName: resourceGroupName
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName
    hubVirtualNetworkName: split(hubVirtualNetworkResourceId , '/')[8]
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
  }
}

module hubToWorkloadVirtualNetworkPeering '../../../modules/hub-network-peerings.bicep' = {
  name: 'deploy-vnet-peering-hub-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId , '/')[2], split(hubVirtualNetworkResourceId , '/')[4])
  params: {
    hubVirtualNetworkName: split(hubVirtualNetworkResourceId , '/')[8]
    spokes: [
      {
        type: workloadName
        virtualNetworkName: virtualNetworkName
        virtualNetworkResourceId: spokeNetwork.outputs.virtualNetworkResourceId
      }
    ]
  }
}

output subnetResourceId string = spokeNetwork.outputs.subnetResourceId
