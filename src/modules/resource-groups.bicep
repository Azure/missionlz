/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param location string
param mlzTags object
param purpose string = ''
param tags object = {}
param tiers array
param tokens object

module resourceGroups 'resource-group.bicep' = [for tier in tiers: {
  name: 'deploy-rg-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    name: replace(tier.namingConvention.resourceGroup, tokens.purpose, purpose)
    location: location
    tags: union(tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
  }
}]

output names array = [for (tier, i) in tiers: resourceGroups[i].outputs.name]
