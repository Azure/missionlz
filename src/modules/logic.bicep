/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param delimiter string
param deploymentNameSuffix string
param environmentAbbreviation string
param identifier string
param location string
param networks array
param stampIndex string = ''

var directionShortNames = {
  east: 'e'
  eastcentral: 'ec'
  north: 'n'
  northcentral: 'nc'
  south: 's'
  southcentral: 'sc'
  west: 'w'
  westcentral: 'wc'
}
var environmentName = {
  dev: 'Development'
  prod: 'Production'
  test: 'Test'
}
var locations = loadJsonContent('../data/locations.json')[?environment().name] ?? {
  '${location}': {
    abbreviation: directionShortNames[skip(location, length(location) - 4)]
    timeDifference: contains(location, 'east') ? '-5:00' : contains(location, 'west') ? '-8:00' : '0:00'
    timeZone: contains(location, 'east') ? 'Eastern Standard Time' : contains(location, 'west') ? 'Pacific Standard Time' : 'GMT Standard Time'
  }
}
var mlzTags = {
  environment: environmentName[environmentAbbreviation]
  identifier: identifier
  landingZoneName: 'MissionLandingZone'
  landingZoneVersion: loadTextContent('../data/version.txt')
}
var resourceAbbreviations = loadJsonContent('../data/resource-abbreviations.json')

module namingConventions 'naming-convention.bicep' = [for network in networks: {
  name: 'naming-convention-${network.shortName}-${deploymentNameSuffix}'
  params: {
    delimiter: delimiter
    environmentAbbreviation: environmentAbbreviation
    identifier: identifier
    locationAbbreviation: locations[location].abbreviation
    networkName: network.name
    resourceAbbreviations: resourceAbbreviations
    stampIndex: stampIndex
  }
}]

module privateDnsZones 'private-dns-zone-names.bicep' = {
  name: 'private-dns-zones-${deploymentNameSuffix}'
  params: {
    // locations: namingConventions[0].outputs.locations // This is only needed for Recovery Services which has been disabled for now.
  }
}

output delimiter string = delimiter
output locationProperties object = locations[location]
output mlzTags object = mlzTags
output privateDnsZones array = privateDnsZones.outputs.names
output resourceAbbreviations object = resourceAbbreviations
output tiers array = [for (network, i) in networks: {
  name: network.name
  namingConvention: namingConventions[i].outputs.names
  nsgDiagLogs: network.?nsgDiagLogs ?? []
  nsgRules: network.?nsgRules ?? []
  shortName: network.shortName
  subnetAddressPrefix: network.?subnetAddressPrefix ?? ''
  subscriptionId: network.subscriptionId
  vnetAddressPrefix: network.?vnetAddressPrefix ?? ''
  vnetDiagLogs: network.?vnetDiagLogs ?? []
  vnetDiagMetrics: network.?vnetDiagMetrics ?? []
}]
