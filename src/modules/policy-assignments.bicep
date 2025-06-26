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
param windowsAdministratorsGroupMembership string

module policyAssignment 'policy-assignment.bicep' = [for (tier, i) in tiers: {
  name: 'assign-policy-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupNames[i])
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    location: location
    deployRemediation: false
    // Network Watcher Resource Group
    // The value is first derived from the networkWatcherResourceId parameter if provided. 
    // This is only applicable when MLZ has been deployed multiple times to the same subscription and location.
    // If the networkWatcherResourceId parameter is not provided, the deployUniquesResources bool 
    // is used to determine if the MLZ deployment is spread across multiple subscriptions. 
    // If so, the tier's resource group is used. If neither of those conditions are met, the hub resource group is used.
    windowsAdministratorsGroupMembership: windowsAdministratorsGroupMembership
  }
}]
