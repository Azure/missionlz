/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param location string
param networks array
param tags object

module resourceGroups 'resource-group.bicep' = [for network in networks: {
  name: 'deploy-rg-${network.name}-${deploymentNameSuffix}'
  scope: subscription(network.subscriptionId)
  params: {
    name: network.resourceGroupName
    location: location
    tags: tags
  }
}]
