/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bastionHostSubnetAddressPrefix string
param deployIdentity bool
param deploymentNameSuffix string
param deployNetworkWatcher bool
param deployRemoteAccess bool
param dnsServers array
param enableProxy bool
param firewallSettings object
param hubNetworkSecurityGroupRules array
param hubSubnetAddressPrefix string
param hubVirtualNetworkAddressPrefix string
param location string
param mlzTags object
param networks array
param tags object

var hub = first(filter(networks, network => network.name == 'hub'))
var identity = deployIdentity ? first(filter(networks, network => network.name == 'identity')) : {}
var spokes  = filter(networks, network => network.name != 'hub')

module hubNetwork 'hub-network.bicep' = {
  name: 'deploy-vnet-hub-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hub.resourceGroupName)
  params: {
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    deployNetworkWatcher: deployNetworkWatcher
    deployRemoteAccess: deployRemoteAccess
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallClientIpConfigurationName: hub.firewallClientIpConfigurationName
    firewallClientPrivateIpAddress: firewallSettings.clientPrivateIpAddress
    firewallClientPublicIPAddressAvailabilityZones: firewallSettings.clientPublicIPAddressAvailabilityZones
    firewallClientPublicIPAddressName: hub.firewallClientPublicIPAddressName
    firewallClientPublicIPAddressSkuName: 'Standard'
    firewallClientPublicIpAllocationMethod: 'Static'
    firewallClientSubnetAddressPrefix: firewallSettings.clientSubnetAddressPrefix
    firewallClientSubnetName: 'AzureFirewallSubnet' // this value is required
    firewallIntrusionDetectionMode: firewallSettings.intrusionDetectionMode
    firewallManagementIpConfigurationName: hub.firewallManagementIpConfigurationName
    firewallManagementPublicIPAddressAvailabilityZones: firewallSettings.managementPublicIPAddressAvailabilityZones
    firewallManagementPublicIPAddressName: hub.firewallManagementPublicIPAddressName
    firewallManagementPublicIPAddressSkuName: firewallSettings.publicIpAddressSkuName
    firewallManagementPublicIpAllocationMethod: firewallSettings.publicIpAddressAllocationMethod
    firewallManagementSubnetAddressPrefix: firewallSettings.managementSubnetAddressPrefix
    firewallManagementSubnetName: 'AzureFirewallManagementSubnet' // this value is required
    firewallName: hub.firewallName
    firewallPolicyName: hub.firewallPolicyName
    firewallSkuTier: firewallSettings.skuTier
    firewallSupernetIPAddress: firewallSettings.supernetIPAddress
    firewallThreatIntelMode: firewallSettings.threatIntelMode
    location: location
    mlzTags: mlzTags
    networkSecurityGroupName: hub.networkSecurityGroupName
    networkSecurityGroupRules: hubNetworkSecurityGroupRules
    networkWatcherName: hub.networkWatcherName
    routeTableName: hub.routeTableName
    subnetAddressPrefix: hubSubnetAddressPrefix
    subnetName: hub.subnetName
    tags: tags
    virtualNetworkAddressPrefix: hubVirtualNetworkAddressPrefix
    virtualNetworkName: hub.virtualNetworkName
    vNetDnsServers: [
      firewallSettings.clientPrivateIpAddress
    ]
  }
}

module spokeNetworks 'spoke-network.bicep' = [for spoke in spokes: {
  name: 'deploy-vnet-${spoke.name}-${deploymentNameSuffix}'
  scope: resourceGroup(spoke.subscriptionId, spoke.resourceGroupName)
  params: {
    deployNetworkWatcher: deployNetworkWatcher && spoke.deployUniqueResources
    firewallSkuTier: firewallSettings.skuTier
    location: location
    mlzTags: mlzTags
    networkSecurityGroupName: spoke.networkSecurityGroupName
    networkSecurityGroupRules: spoke.networkSecurityGroupRules
    networkWatcherName: spoke.networkWatcherName
    routeTableName: spoke.routeTableName
    routeTableRouteNextHopIpAddress: firewallSettings.clientPrivateIpAddress
    subnetAddressPrefix: spoke.subnetAddressPrefix
    subnetName: spoke.subnetName
    subnetPrivateEndpointNetworkPolicies: spoke.subnetPrivateEndpointNetworkPolicies
    subnetPrivateLinkServiceNetworkPolicies: spoke.subnetPrivateLinkServiceNetworkPolicies
    tags: tags
    virtualNetworkAddressPrefix: spoke.virtualNetworkAddressPrefix
    virtualNetworkName: spoke.virtualNetworkName
    vNetDnsServers: [ hubNetwork.outputs.firewallPrivateIPAddress ]
  }
}]

// VIRTUAL NETWORK PEERINGS

module hubVirtualNetworkPeerings 'hub-network-peerings.bicep' = {
  name: 'deploy-vnet-peerings-hub-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hub.resourceGroupName)
  params: {
    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    spokes: [for (spoke, i) in spokes: {
      type: spoke.name
      virtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
      virtualNetworkResourceId: spokeNetworks[i].outputs.virtualNetworkResourceId
    }]
  }
}

module spokeVirtualNetworkPeerings 'spoke-network-peering.bicep' = [for (spoke, i) in spokes: {
  name: 'deploy-vnet-peerings-${spoke.name}-${deploymentNameSuffix}'
  scope: subscription(spoke.subscriptionId)
  params: {
    spokeName: spoke.name
    spokeResourceGroupName: spoke.resourceGroupName
    spokeVirtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    hubVirtualNetworkResourceId: hubNetwork.outputs.virtualNetworkResourceId
  }
}]

// PRIVATE DNS

module privateDnsZones 'private-dns.bicep' = {
  name: 'deploy-private-dns-zones-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hub.resourceGroupName)
  params: {
    deployIdentity: deployIdentity
    deploymentNameSuffix: deploymentNameSuffix
    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    hubVirtualNetworkResourceGroupName: hub.resourceGroupName
    hubVirtualNetworkSubscriptionId: hub.subscriptionId
    identityVirtualNetworkName: deployIdentity ? identity.virtualNetworkName : ''
    identityVirtualNetworkResourceGroupName: deployIdentity ? identity.resourceGroupName : ''
    identityVirtualNetworkSubscriptionId: deployIdentity ? identity.subscriptionId : ''
    mlzTags: mlzTags
    tags: tags
  }
  dependsOn: [
    spokeNetworks
  ]
}

output azureFirewallResourceId string = hubNetwork.outputs.firewallResourceId
output bastionHostSubnetResourceId string = hubNetwork.outputs.bastionHostSubnetResourceId
output hubSubnetResourceId string = hubNetwork.outputs.subnetResourceId
output hubNetworkSecurityGroupResourceId string = hubNetwork.outputs.networkSecurityGroupResourceId
output hubVirtualNetworkResourceId string = hubNetwork.outputs.virtualNetworkResourceId
output identitySubnetResourceId string = deployIdentity ? spokeNetworks[2].outputs.subnetResourceId : ''
output operationsSubnetResourceId string = spokeNetworks[0].outputs.subnetResourceId
output privateDnsZoneResourceIds object = {
  agentsvc: privateDnsZones.outputs.agentsvcPrivateDnsZoneId
  automation: privateDnsZones.outputs.automationPrivateDnsZoneId
  avdGlobal: privateDnsZones.outputs.avdGlobalPrivateDnsZoneId
  avd: privateDnsZones.outputs.avdPrivateDnsZoneId
  backups: privateDnsZones.outputs.backupPrivateDnsZoneIds
  blob: privateDnsZones.outputs.blobPrivateDnsZoneId
  file: privateDnsZones.outputs.filePrivateDnsZoneId
  keyvault: privateDnsZones.outputs.keyvaultDnsPrivateDnsZoneId
  monitor: privateDnsZones.outputs.monitorPrivateDnsZoneId
  ods: privateDnsZones.outputs.odsPrivateDnsZoneId
  oms: privateDnsZones.outputs.omsPrivateDnsZoneId
  queue: privateDnsZones.outputs.queuePrivateDnsZoneId
  table: privateDnsZones.outputs.tablePrivateDnsZoneId
}
