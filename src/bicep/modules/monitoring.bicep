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
param operationsProperties object
param privateDnsZoneResourceIds object
param subnetResourceId string
param tags object

module logAnalyticsWorkspace 'log-analytics-workspace.bicep' = {
  name: 'deploy-law-${deploymentNameSuffix}'
  scope: resourceGroup(operationsProperties.subscriptionId, operationsProperties.resourceGroupName)
  params: {
    deploySentinel: deploySentinel
    location: location
    name: operationsProperties.logAnalyticsWorkspaceName
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    skuName: logAnalyticsWorkspaceSkuName
    tags: tags
    workspaceCappingDailyQuotaGb: logAnalyticsWorkspaceCappingDailyQuotaGb
  }
}


module privateLinkScope 'private-link-scope.bicep' = {
  name: 'deploy-private-link-scope-${deploymentNameSuffix}'
  scope: resourceGroup(operationsProperties.subscriptionId, operationsProperties.resourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    name: operationsProperties.privateLinkScopeName
  }
}

module privateEndpoint 'private-endpoint.bicep' = {
  name: 'deploy-private-endpoint-${deploymentNameSuffix}'
  scope: resourceGroup(operationsProperties.subscriptionId, operationsProperties.resourceGroupName)
  params: {
    groupIds: [
      'azuremonitor'
    ]
    location: location
    name: operationsProperties.privateLinkScopePrivateEndpointName
    networkInterfaceName: operationsProperties.privateLinkScopeNetworkInterfaceName
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
    ]
    privateLinkServiceId: privateLinkScope.outputs.resourceId
    subnetResourceId: subnetResourceId
    tags: tags
  }
}

output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId
