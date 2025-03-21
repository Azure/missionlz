/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param deploySentinel bool
param location string
param logAnalyticsWorkspaceCappingDailyQuotaGb int
param logAnalyticsWorkspaceRetentionInDays int
param logAnalyticsWorkspaceSkuName string
param mlzTags object
param ops object
param opsResourceGroupName string
param privateDnsZoneResourceIds object
param subnetResourceId string
param tags object

module logAnalyticsWorkspace 'log-analytics-workspace.bicep' = {
  name: 'deploy-law-${deploymentNameSuffix}'
  scope: resourceGroup(ops.subscriptionId, opsResourceGroupName)
  params: {
    deploySentinel: deploySentinel
    location: location
    mlzTags: mlzTags
    name: ops.namingConvention.logAnalyticsWorkspace
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    skuName: logAnalyticsWorkspaceSkuName
    tags: tags
    workspaceCappingDailyQuotaGb: logAnalyticsWorkspaceCappingDailyQuotaGb
  }
}


module privateLinkScope 'private-link-scope.bicep' = {
  name: 'deploy-private-link-scope-${deploymentNameSuffix}'
  scope: resourceGroup(ops.subscriptionId, opsResourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    name: ops.namingConvention.privateLinkScope
  }
}

module privateEndpoint 'private-endpoint.bicep' = {
  name: 'deploy-private-endpoint-${deploymentNameSuffix}'
  scope: resourceGroup(ops.subscriptionId, opsResourceGroupName)
  params: {
    groupIds: [
      'azuremonitor'
    ]
    location: location
    mlzTags: mlzTags
    name: ops.namingConvention.privateLinkScopePrivateEndpoint
    networkInterfaceName: ops.namingConvention.privateLinkScopeNetworkInterface
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
    subnetResourceId: subnetResourceId
    tags: tags
  }
}

output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId
output networkInterfaceResourceIds array = [
  privateEndpoint.outputs.networkInterfaceResourceId
]
output privateLinkScopeResourceId string = privateLinkScope.outputs.resourceId
