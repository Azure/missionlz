/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param defenderPlans array = ['VirtualMachines']
param defenderSkuTier string
param deployDefender bool
param deployPolicy bool
param deploymentNameSuffix string
param emailSecurityContact string
param location string
param logAnalyticsWorkspaceResourceId string
param policy string
param tiers array
param windowsAdministratorsGroupMembership string

module policyAssignment 'policy-assignment.bicep' = [
  for (tier, i) in tiers: if (deployPolicy) {
    name: 'assign-policy-${tier.name}-${deploymentNameSuffix}'
    scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
    params: {
      builtInAssignment: policy
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
      location: location
      deployRemediation: false
      windowsAdministratorsGroupMembership: windowsAdministratorsGroupMembership
    }
  }
]

@batchSize(1)
module defenderForCloud 'defender-for-cloud.bicep' = [
  for tier in tiers: if (deployDefender) {
    name: 'set-defender-${tier.name}-${deploymentNameSuffix}'
    scope: subscription(tier.subscriptionId)
    params: {
      defenderPlans: defenderPlans
      defenderSkuTier: defenderSkuTier
      emailSecurityContact: emailSecurityContact
    }
  }
]
