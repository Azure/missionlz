/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param delimiter string
param deploymentNameSuffix string
param location string
param mlzTags object
param tiers array
param tags object

module resourceGroups 'resource-group.bicep' = [for tier in tiers: {
  name: 'deploy-rg-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    mlzTags: mlzTags
    name: '${tier.namingConvention.resourceGroup}${delimiter}network'
    location: location
    tags: tags
  }
}]

output names array = [for (tier, i) in tiers: resourceGroups[i].outputs.name]
