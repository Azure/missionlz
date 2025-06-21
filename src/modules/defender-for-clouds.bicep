/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param defenderPlans array = ['VirtualMachines']
param defenderSkuTier string
param deploymentNameSuffix string
param emailSecurityContact string
param tiers array

@batchSize(1)
module defenderForCloud 'defender-for-cloud.bicep' = [for tier in tiers: {
  name: 'set-defender-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    defenderPlans: defenderPlans
    defenderSkuTier: defenderSkuTier
    emailSecurityContact: emailSecurityContact
  }
}]
