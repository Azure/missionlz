targetScope = 'subscription'

param defenderSkuTier string
param deploymentNameSuffix string
param emailSecurityContact string
param logAnalyticsWorkspaceResourceId string
param networks array

module defenderForCloud 'defenderForCloud.bicep' = [for network in networks: if (network.deployUniqueResources) {
  name: 'set-defender-${network.name}-${deploymentNameSuffix}'
  scope: subscription(network.subscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    emailSecurityContact: emailSecurityContact
    defenderSkuTier: defenderSkuTier
  }
}]
