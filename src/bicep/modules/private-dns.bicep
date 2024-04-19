/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deployIdentity bool
param deploymentNameSuffix string
param hubVirtualNetworkName string
param hubVirtualNetworkResourceGroupName string
param hubVirtualNetworkSubscriptionId string
param identityVirtualNetworkName string
param identityVirtualNetworkResourceGroupName string
param identityVirtualNetworkSubscriptionId string
param mlzTags object
param tags object

var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.azure.', ''), '/', '')
var locations = (loadJsonContent('../data/locations.json'))[environment().name]
var privateDnsZoneNames = union([
  'privatelink.agentsvc.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudSuffix}'
  'privatelink.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudSuffix}'
  'privatelink.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name] ?? cloudSuffix}'
  'privatelink-global.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name] ?? cloudSuffix}'
  'privatelink.file.${environment().suffixes.storage}'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.table.${environment().suffixes.storage}'
  'privatelink.blob.${environment().suffixes.storage}'
  replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
  'privatelink.monitor.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudSuffix}'
  'privatelink.ods.opinsights.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudSuffix}'
  'privatelink.oms.opinsights.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudSuffix}'
], privateDnsZoneNames_Backup)
var privateDnsZoneNames_Backup = [for location in items(locations): 'privatelink.${location.value.recoveryServicesGeo}.backup.windowsazure.${privateDnsZoneSuffixes_Backup[environment().name] ?? cloudSuffix}']
var privateDnsZoneSuffixes_AzureAutomation = {
  AzureCloud: 'net'
  AzureUSGovernment: 'us'
  USNat: null
  USSec: null
}
var privateDnsZoneSuffixes_AzureVirtualDesktop = {
  AzureCloud: 'microsoft.com'
  AzureUSGovernment: 'azure.us'
  USNat: null
  USSec: null
}
var privateDnsZoneSuffixes_Backup = {
  AzureCloud: 'com'
  AzureUSGovernment: 'us'
  USNat: null
  USSec: null
}
var privateDnsZoneSuffixes_Monitor = {
  AzureCloud: 'azure.com'
  AzureUSGovernment: 'azure.us'
  USNat: null
  USSec: null
}
var virtualNetworks = union([
  {
    name: hubVirtualNetworkName
    resourceGroupName: hubVirtualNetworkResourceGroupName
    subscriptionId: hubVirtualNetworkSubscriptionId
  }
], deployIdentity ? [
  {
    name: identityVirtualNetworkName
    resourceGroupName: identityVirtualNetworkResourceGroupName
    subscriptionId: identityVirtualNetworkSubscriptionId
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

output agentsvcPrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.agentsvc.azure-automation'))[0])
output automationPrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.azure-automation'))[0])
output avdGlobalPrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink-global.wvd'))[0])
output avdPrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.wvd'))[0])
output backupPrivateDnsZoneIds array = [for name in privateDnsZoneNames_Backup: resourceId('Microsoft.Network/privateDnsZones', name)]
output blobPrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.blob'))[0])
output filePrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.file'))[0])
output keyvaultDnsPrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.vaultcore'))[0])
output monitorPrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.monitor'))[0])
output odsPrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.ods.opinsights'))[0])
output omsPrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.oms.opinsights'))[0])
output queuePrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.queue'))[0])
output tablePrivateDnsZoneId string = resourceId('Microsoft.Network/privateDnsZones', filter(privateDnsZoneNames, name => contains(name, 'privatelink.table'))[0])
