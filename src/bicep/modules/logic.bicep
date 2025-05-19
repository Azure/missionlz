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

module privateDnsZones 'private-dns-zones.bicep' = {
  name: 'private-dns-zones-${deploymentNameSuffix}'
  params: {
    // locations: namingConventions[0].outputs.locations // This is only needed for Recovery Services which has been disabled for now.
  }
}

output delimiter string = namingConventions[0].outputs.delimiter
output locationProperties object = namingConventions[0].outputs.locations[location]
output mlzTags object = mlzTags
output privateDnsZones array = privateDnsZones.outputs.names
output resourceAbbreviations object = namingConventions[0].outputs.resourceAbbreviations
output tiers array = [for (network, i) in networks: {
  name: network.name
  shortName: network.shortName
  subscriptionId: network.subscriptionId
  nsgDiagLogs: network.?nsgDiagLogs ?? []
  nsgRules: network.?nsgRules ?? []
  vnetAddressPrefix: network.?vnetAddressPrefix ?? ''
  vnetDiagLogs: network.?vnetDiagLogs ?? []
  vnetDiagMetrics: network.?vnetDiagMetrics ?? []
  subnetAddressPrefix: network.?subnetAddressPrefix ?? ''
  namingConvention: namingConventions[i].outputs.names
}]
