/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param defenderPlans array = ['VirtualMachines']
param defenderSkuTier string
param deploymentNameSuffix string
param emailSecurityContact string
param logAnalyticsWorkspaceResourceId string
param tiers array

module defenderForCloud 'defender-for-cloud.bicep' = [for tier in tiers: if (tier.deployUniqueResources) {
  name: 'set-defender-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    emailSecurityContact: emailSecurityContact
    defenderSkuTier: defenderSkuTier
    defenderPlans: defenderPlans
  }
}]
