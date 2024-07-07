/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deployActivityLogDiagnosticSetting bool
param deploymentNameSuffix string
param keyVaultDiagnosticLogs array
param keyVaultName string
param logAnalyticsWorkspaceResourceId string
param networkSecurityGroupDiagnosticsLogs array
param networkSecurityGroupDiagnosticsMetrics array
param networkSecurityGroupName string
param resourceGroupName string
param serviceToken string
param storageAccountResourceId string
param tier object
param virtualNetworkDiagnosticsLogs array
param virtualNetworkDiagnosticsMetrics array
param virtualNetworkName string

module activityLogDiagnosticSettings '../../../modules/activity-log-diagnostic-settings.bicep' =
  if (deployActivityLogDiagnosticSetting) {
    name: 'deploy-activity-diags-${tier.shortName}-${deploymentNameSuffix}'
    scope: subscription(tier.subscriptionId)
    params: {
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    }
  }

module keyvaultDiagnostics '../../../modules/key-vault-diagnostics.bicep' = {
  name: 'deploy-kv-diags-${tier.shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    keyVaultDiagnosticSettingName: replace(tier.namingConvention.keyVaultDiagnosticSetting, '${serviceToken}-', '')
    keyVaultName: keyVaultName
    keyVaultStorageAccountId: storageAccountResourceId
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: keyVaultDiagnosticLogs
  }
}  

module networkSecurityGroupDiagnostics '../../../modules/network-security-group-diagnostics.bicep' = {
  name: 'deploy-nsg-diags-${tier.shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: networkSecurityGroupDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceId
    metrics: networkSecurityGroupDiagnosticsMetrics
    networkSecurityGroupDiagnosticSettingName: tier.namingConvention.networkSecurityGroupDiagnosticSetting
    networkSecurityGroupName: networkSecurityGroupName
  }
}

module virtualNetworkDiagnostics '../../../modules/virtual-network-diagnostics.bicep' = {
  name: 'deploy-vnet-diags-${tier.shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: virtualNetworkDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceId
    metrics: virtualNetworkDiagnosticsMetrics
    virtualNetworkDiagnosticSettingName: tier.namingConvention.virtualNetworkDiagnosticSetting
    virtualNetworkName: virtualNetworkName
  }
}
