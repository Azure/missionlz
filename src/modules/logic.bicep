/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param environmentAbbreviation string
param identifier string
param location string
param networks array
param stampIndex string = ''

var environmentName = {
  dev: 'Development'
  prod: 'Production'
  test: 'Test'
}
var mlzTags = {
  environment: environmentName[environmentAbbreviation]
  identifier: identifier
  landingZoneName: 'MissionLandingZone'
  landingZoneVersion: loadTextContent('../data/version.txt')
}

/*

  RESOURCE NAMES

*/

module namingConventions 'naming-convention.bicep' = [for network in networks: {
  name: 'naming-convention-${network.shortName}-${deploymentNameSuffix}'
  params: {
    environmentAbbreviation: environmentAbbreviation
    identifier: identifier
    location: location
    networkName: network.name
    stampIndex: stampIndex
  }
}]

module privateDnsZones 'private-dns-zone-names.bicep' = {
  name: 'private-dns-zones-${deploymentNameSuffix}'
  params: {
    // locations: namingConventions[0].outputs.locations // This is only needed for Recovery Services which has been disabled for now.
  }
}

output mlzTags object = mlzTags
output privateDnsZones array = privateDnsZones.outputs.names
output tiers array = [for (network, i) in networks: {
  delimiter: namingConventions[i].outputs.delimiter
  locationProperties: namingConventions[i].outputs.locations[location]
  name: network.name
  namingConvention: namingConventions[i].outputs.names
  nsgDiagLogs: network.?nsgDiagLogs ?? []
  nsgRules: network.?nsgRules ?? []
  resourceAbbreviations: namingConventions[i].outputs.resourceAbbreviations
  shortName: network.shortName
  subnetAddressPrefix: network.?subnetAddressPrefix ?? ''
  subscriptionId: network.subscriptionId
  vnetAddressPrefix: network.?vnetAddressPrefix ?? ''
  vnetDiagLogs: network.?vnetDiagLogs ?? []
  vnetDiagMetrics: network.?vnetDiagMetrics ?? []
}]
