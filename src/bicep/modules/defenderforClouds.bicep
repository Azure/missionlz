/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param defenderSkuTier string
param deploymentNameSuffix string
param emailSecurityContact string
param logAnalyticsWorkspaceResourceId string
param networks array
param defenderPlans array = ['VirtualMachines']

module defenderForCloud 'defenderForCloud.bicep' = [for network in networks: if (network.deployUniqueResources) {
  name: 'set-defender-${network.name}-${deploymentNameSuffix}'
  scope: subscription(network.subscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    emailSecurityContact: emailSecurityContact
    defenderSkuTier: defenderSkuTier
    defenderPlans: defenderPlans
  }
}]
