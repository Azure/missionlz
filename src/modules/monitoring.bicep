/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param delimiter string
param deploymentNameSuffix string
param deploySentinel bool
param location string
param logAnalyticsWorkspaceCappingDailyQuotaGb int
param logAnalyticsWorkspaceRetentionInDays int
param logAnalyticsWorkspaceSkuName string
param mlzTags object
param privateDnsZoneResourceIds object
param tags object
param tier object
param tokens object

module logAnalyticsWorkspace 'log-analytics-workspace.bicep' = {
  name: 'deploy-law-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    deploySentinel: deploySentinel
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.logAnalyticsWorkspace, '${delimiter}${tokens.purpose}', '')
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    skuName: logAnalyticsWorkspaceSkuName
    tags: tags
    workspaceCappingDailyQuotaGb: logAnalyticsWorkspaceCappingDailyQuotaGb
  }
}


module privateLinkScope 'private-link-scope.bicep' = {
  name: 'deploy-private-link-scope-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    name: replace(tier.namingConvention.privateLinkScope, '${delimiter}${tokens.purpose}', '')
  }
}

module privateEndpoint 'private-endpoint.bicep' = {
  name: 'deploy-private-endpoint-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    groupIds: [
      'azuremonitor'
    ]
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.privateLinkScopePrivateEndpoint, '${delimiter}${tokens.purpose}', '')
    networkInterfaceName: replace(tier.namingConvention.privateLinkScopeNetworkInterface, '${delimiter}${tokens.purpose}', '')
    privateDnsZoneConfigs: [
      {
        name: 'monitor'
        properties: {
          privateDnsZoneId: privateDnsZoneResourceIds.monitor
        }
      }
      {
        name: 'oms'
        properties: {
          privateDnsZoneId: privateDnsZoneResourceIds.oms
        }
      }
      {
        name: 'ods'
        properties: {
          privateDnsZoneId: privateDnsZoneResourceIds.ods
        }
      }
      {
        name: 'agentsvc'
        properties: {
          privateDnsZoneId: privateDnsZoneResourceIds.agentsvc
        }
      }
      {
        name: 'blob'
        properties: {
          privateDnsZoneId: privateDnsZoneResourceIds.blob
        }
      }
    ]
    privateLinkServiceId: privateLinkScope.outputs.resourceId
    subnetResourceId: tier.subnetResourceId
    tags: tags
  }
}

output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId
output networkInterfaceResourceIds array = [
  privateEndpoint.outputs.networkInterfaceResourceId
]
output privateLinkScopeResourceId string = privateLinkScope.outputs.resourceId
