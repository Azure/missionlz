/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param location string
param logAnalyticsWorkspaceResourceId string
param networks array
param policy string

module policyAssignment 'policy-assignment.bicep' = [for network in networks: {
  name: 'assign-policy-${network.name}-${deploymentNameSuffix}'
  scope: resourceGroup(network.subscriptionId, network.resourceGroupName)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    location: location
  }
}]
