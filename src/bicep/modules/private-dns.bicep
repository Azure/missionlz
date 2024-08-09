/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deployIdentity bool
param deploymentNameSuffix string
param hubVirtualNetworkResourceId string
param identityVirtualNetworkResourceId string
param mlzTags object
param privateDnsZoneNames array
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

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' = [for name in privateDnsZoneNames: {
  name: name
  location: 'global'
  tags: union(contains(tags, 'Microsoft.Network/privateDnsZones') ? tags['Microsoft.Network/privateDnsZones'] : {}, mlzTags)
}]

@batchSize(1)
module virtualNetworkLinks 'virtual-network-link.bicep' = [for (virtualNetwork, i) in virtualNetworks:{
  name: 'deploy-virtual-network-links-${i}-${deploymentNameSuffix}'
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
