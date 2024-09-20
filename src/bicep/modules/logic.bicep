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

var environmentName = {
  dev: 'Development'
  prod: 'Production'
  test: 'Test'
}
var mlzTags = {
  environment: environmentName[environmentAbbreviation]
  landingZoneName: 'MissionLandingZone'
  landingZoneVersion: loadTextContent('../data/version.txt')
  resourcePrefix: resourcePrefix
}

/*

  RESOURCE NAMES

*/

module namingConventions 'naming-convention.bicep' = [for network in networks: {
  name: 'naming-convention-${network.shortName}-${deploymentNameSuffix}'
  params: {
    environmentAbbreviation: environmentAbbreviation
    location: location
    networkName: network.name
    networkShortName: network.shortName
    resourcePrefix: resourcePrefix
    stampIndex: stampIndex
  }
}]

module privateDnsZones 'private-dns-zones.bicep' = {
  name: 'private-dns-zones-${deploymentNameSuffix}'
  params: {
    locations: namingConventions[0].outputs.locations
  }
}

output locationProperties object = namingConventions[0].outputs.locations[location]
output mlzTags object = mlzTags
output privateDnsZones array = privateDnsZones.outputs.names
output resourceAbbreviations object = namingConventions[0].outputs.resourceAbbreviations
output tiers array = [for (network, i) in networks: {
  name: network.name
  shortName: network.shortName
  deployUniqueResources: network.deployUniqueResources
  subscriptionId: network.subscriptionId
  nsgDiagLogs: network.?nsgDiagLogs ?? []
  nsgDiagMetrics: network.?nsgDiagMetrics ?? []
  nsgRules: network.?nsgRules ?? []
  vnetAddressPrefix: network.?vnetAddressPrefix ?? ''
  vnetDiagLogs: network.?vnetDiagLogs ?? []
  vnetDiagMetrics: network.?vnetDiagMetrics ?? []
  subnetAddressPrefix: network.?subnetAddressPrefix ?? ''
  namingConvention: namingConventions[i].outputs.names
}]
output tokens object = namingConventions[0].outputs.tokens
