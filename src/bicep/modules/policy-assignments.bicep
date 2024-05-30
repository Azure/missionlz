/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param location string
param logAnalyticsWorkspaceResourceId string
param policy string
param resourceGroupNames array
param tiers array

module policyAssignment 'policy-assignment.bicep' = [for (tier, i) in tiers: {
  name: 'assign-policy-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupNames[i])
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    location: location
  }
}]
