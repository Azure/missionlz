/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param deploySentinel bool
param enableEntityBehavior bool
param deployEntityBehaviorSetting bool
param useEntityBehaviorScript bool = false
param enableUeba bool
param deployUebaSetting bool = true
param useUebaScript bool = false
param uebaDataSources array
param enableAnomalies bool
param deploySentinelAutomationScript bool = true
param enableEntraDiagnostics bool = true
param entraDiagnosticName string = 'diag-entra'
param entraLogCategories array = []
param enableEntraIdDataConnector bool = true
param enableAzureActivityDataConnector bool = true
param entraConnectorDataTypeStates object
param tenantId string
param sentinelAutomationPrincipalId string = ''
param location string
param logAnalyticsWorkspaceCappingDailyQuotaGb int
param logAnalyticsWorkspaceRetentionInDays int
param logAnalyticsWorkspaceSkuName string
param mlzTags object
param privateDnsZoneResourceIds object
param tags object
param tier object
param securityResourceGroupName string = ''
param securityNamingConvention object = {}

@description('Toggle to deploy Content Hub analytic rules as active scheduled rules.')
param deployAnalyticRules bool = true

@description('URL to the analytic rules manifest JSON file.')
param analyticRulesManifestUrl string = 'https://raw.githubusercontent.com/Azure/missionlz/main/sentinel/analytic-rules-manifest.json'

var targetResourceGroupName = !empty(securityResourceGroupName) ? securityResourceGroupName : tier.resourceGroupName
var targetWorkspaceName = !empty(securityNamingConvention) ? securityNamingConvention.logAnalyticsWorkspace : tier.namingConvention.logAnalyticsWorkspace
var targetPrivateLinkScopeName = !empty(securityNamingConvention) ? securityNamingConvention.privateLinkScope : tier.namingConvention.privateLinkScope

module logAnalyticsWorkspace 'log-analytics-workspace.bicep' = {
  name: 'deploy-law-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, targetResourceGroupName)
  params: {
    deploySentinel: deploySentinel
    location: location
    mlzTags: mlzTags
    name: targetWorkspaceName
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    skuName: logAnalyticsWorkspaceSkuName
    tags: tags
    workspaceCappingDailyQuotaGb: logAnalyticsWorkspaceCappingDailyQuotaGb
  }
}


module privateLinkScope 'private-link-scope.bicep' = {
  name: 'deploy-private-link-scope-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, targetResourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    name: targetPrivateLinkScopeName
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
    name: tier.namingConvention.privateLinkScopePrivateEndpoint
    networkInterfaceName: tier.namingConvention.privateLinkScopeNetworkInterface
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

module sentinelSettings 'sentinel-settings.bicep' = if (deploySentinel) {
  name: 'configure-sentinel-settings-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, targetResourceGroupName)
  params: {
    workspaceName: targetWorkspaceName
    location: location
    enableEntityBehavior: enableEntityBehavior
    deployEntityBehaviorSetting: deployEntityBehaviorSetting
    useEntityBehaviorScript: useEntityBehaviorScript
    enableUeba: enableUeba
    deployUebaSetting: deployUebaSetting
    useUebaScript: useUebaScript
    uebaDataSources: uebaDataSources
    enableAnomalies: enableAnomalies
    deploySentinelAutomationScript: deploySentinelAutomationScript
    sentinelAutomationPrincipalId: sentinelAutomationPrincipalId
    enableEntraDiagnostics: enableEntraDiagnostics
    entraDiagnosticName: entraDiagnosticName
    entraWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    entraLogCategories: entraLogCategories
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}

module sentinelConnectors 'sentinel-connectors.bicep' = if (deploySentinel && (enableEntraIdDataConnector || enableAzureActivityDataConnector)) {
  name: 'configure-sentinel-connectors-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, targetResourceGroupName)
  params: {
    workspaceName: targetWorkspaceName
    tenantId: tenantId
    enableAzureActivityConnector: enableAzureActivityDataConnector
    enableEntraIdConnector: enableEntraIdDataConnector
    entraDataTypeStates: entraConnectorDataTypeStates
  }
  dependsOn: [
    sentinelSettings
  ]
}

module sentinelAnalyticRules 'sentinel-analytic-rules.bicep' = if (deploySentinel && deployAnalyticRules) {
  name: 'deploy-sentinel-analytic-rules-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, targetResourceGroupName)
  params: {
    workspaceName: targetWorkspaceName
    location: location
    deployAnalyticRules: deployAnalyticRules
    analyticRulesManifestUrl: analyticRulesManifestUrl
  }
  dependsOn: [
    sentinelSettings
  ]
}

output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId
output networkInterfaceResourceIds array = [
  privateEndpoint.outputs.networkInterfaceResourceId
]
output privateLinkScopeResourceId string = privateLinkScope.outputs.resourceId
