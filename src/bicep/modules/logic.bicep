/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param environmentAbbreviation string
param location string
param networks array
param resourcePrefix string
param stampIndex string = ''

var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var environmentName = {
  dev: 'Development'
  prod: 'Production'
  test: 'Test'
}
var locations = loadJsonContent('../data/locations.json')[environment().name]
var mlzTags = {
  environment: environmentName[environmentAbbreviation]
  landingZoneName: 'MissionLandingZone'
  landingZoneVersion: loadTextContent('../data/version.txt')
  resourcePrefix: resourcePrefix
}
var resourceAbbreviations = loadJsonContent('../data/resourceAbbreviations.json')
var tokens = {
  resource: 'resource_token'
  service: 'service_token'
}

/*

  RESOURCE NAMES

*/

module namingConventions 'naming-convention.bicep' = [for network in networks: {
  name: 'naming-convention-${network.shortName}-${deploymentNameSuffix}'
  params: {
    locationAbbreviation: locations[location].abbreviation
    environmentAbbreviation: environmentAbbreviation
    networkName: network.name
    networkShortName: network.shortName
    resourceAbbreviations: resourceAbbreviations
    resourcePrefix: resourcePrefix
    stampIndex: stampIndex
    subscriptionId: network.subscriptionId
    tokens: tokens
  }
}]

/*

  PRIVATE DNS ZONE NAMES

*/

var privateDnsZoneNames = union([
  'privatelink.agentsvc.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudSuffix}' // Automation
  'privatelink.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudSuffix}' // Automation
  'privatelink.${privateDnsZoneSuffixes_AzureWebSites[environment().name] ?? 'appservice.${cloudSuffix}'}' // Web Apps & Function Apps
  'scm.privatelink.${privateDnsZoneSuffixes_AzureWebSites[environment().name] ?? 'appservice.${cloudSuffix}'}' // Web Apps & Function Apps
  'privatelink.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name] ?? cloudSuffix}' // Azure Virtual Desktop
  'privatelink-global.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name] ?? cloudSuffix}' // Azure Virtual Desktop
  'privatelink.file.${environment().suffixes.storage}' // Azure Files
  'privatelink.queue.${environment().suffixes.storage}' // Azure Queues
  'privatelink.table.${environment().suffixes.storage}' // Azure Tables
  'privatelink.blob.${environment().suffixes.storage}' // Azure Blobs
  'privatelink${replace(environment().suffixes.keyvaultDns, 'vault', 'vaultcore')}' // Key Vault
  'privatelink.monitor.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudSuffix}' // Azure Monitor
  'privatelink.ods.opinsights.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudSuffix}' // Azure Monitor
  'privatelink.oms.opinsights.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudSuffix}' // Azure Monitor
], privateDnsZoneNames_Backup) // Recovery Services
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
var privateDnsZoneSuffixes_AzureWebSites = {
  AzureCloud: 'azurewebsites.net'
  AzureUSGovernment: 'azurewebsites.us'
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

output locationProperties object = locations[location]
output mlzTags object = mlzTags
output privateDnsZones array = privateDnsZoneNames
output tiers array = [for (network, i) in networks: {
  name: network.name
  shortName: network.shortName
  deployUniqueResources: network.deployUniqueResources
  subscriptionId: network.subscriptionId
  nsgDiagLogs: network.nsgDiagLogs
  nsgDiagMetrics: network.nsgDiagMetrics
  nsgRules: network.nsgRules
  vnetAddressPrefix: network.vnetAddressPrefix
  vnetDiagLogs: network.vnetDiagLogs
  vnetDiagMetrics: network.vnetDiagMetrics
  subnetAddressPrefix: network.subnetAddressPrefix
  namingConvention: namingConventions[i].outputs.names
}]
output tokens object = tokens
