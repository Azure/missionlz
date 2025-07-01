/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deployIdentity bool
param deploymentNameSuffix string
param hubVirtualNetworkResourceId string
param identityVirtualNetworkResourceId string
param mlzTags object
param privateDnsZoneNames array
param resourceGroupName string
param subscriptionId string
param tags object

var virtualNetworks = union([
  {
    name: split(hubVirtualNetworkResourceId, '/')[8]
    resourceGroupName: split(hubVirtualNetworkResourceId, '/')[4]
    subscriptionId: split(hubVirtualNetworkResourceId, '/')[2]
  }
], deployIdentity ? [
  {
    name: split(identityVirtualNetworkResourceId, '/')[8]
    resourceGroupName: split(identityVirtualNetworkResourceId, '/')[4]
    subscriptionId: split(identityVirtualNetworkResourceId, '/')[2]
  }
] : [])

module privateDnsZones 'private-dns-zone.bicep' = [for (name, i) in privateDnsZoneNames: {
  name: 'deploy-pvt-dns-zone-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    name: name
    tags: union(tags[?'Microsoft.Network/privateDnsZones'] ?? {}, mlzTags)
  }
}]

@batchSize(1)
module virtualNetworkLinks 'virtual-network-link.bicep' = [for (virtualNetwork, i) in virtualNetworks:{
  name: 'deploy-vnet-links-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(virtualNetwork.resourceGroupName, virtualNetwork.subscriptionId)
  params: {
    privateDnsZoneNames: privateDnsZoneNames
    virtualNetworkName: virtualNetwork.name
    virtualNetworkResourceGroupName: virtualNetwork.resourceGroupName
    virtualNetworkSubscriptionId: virtualNetwork.subscriptionId
  }
  dependsOn: [
    privateDnsZones
  ]
}]

output privateDnsZoneResourceIds object = {
  agentSvc: resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => startsWith(name, 'privatelink.agentsvc'))[0])
  blob: resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'blob'))[0])
  file: resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'file'))[0])
  keyVault: resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'vaultcore'))[0])
  monitor: resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'monitor'))[0])
  ods: resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'ods.opinsights'))[0])
  oms: resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'oms.opinsights'))[0])
  queue: resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'queue'))[0])
  table: resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'table'))[0])
}
