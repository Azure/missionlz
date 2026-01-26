/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param blobDiagnosticsLogs array
param blobDiagnosticsMetrics array
param delimiter string
param deployActivityLogDiagnosticSetting bool
param deploymentNameSuffix string
param deployNetworkWatcherTrafficAnalytics bool
param fileDiagnosticsLogs array
param fileDiagnosticsMetrics array
param hubStorageAccountResourceId string
param keyVaultDiagnosticLogs array
param keyVaultDiagnosticMetrics array
param keyVaultName string
param location string
param logAnalyticsWorkspaceResourceId string
param networkInterfaceDiagnosticsMetrics array
param networkInterfaceResourceIds array
param networkSecurityGroupDiagnosticsLogs array
param networkWatcherFlowLogsRetentionDays int
param networkWatcherFlowLogsType string
param queueDiagnosticsLogs array
param queueDiagnosticsMetrics array
param storageAccountDiagnosticsLogs array
param storageAccountDiagnosticsMetrics array
param storageAccountResourceId string
param tableDiagnosticsLogs array
param tableDiagnosticsMetrics array
param tier object
param tokens object
param virtualNetworkDiagnosticsLogs array
param virtualNetworkDiagnosticsMetrics array
param virtualNetworkName string

module activityLogDiagnosticSettings '../../../modules/activity-log-diagnostic-setting.bicep' =
  if (deployActivityLogDiagnosticSetting) {
    name: 'deploy-activity-diags-${tier.shortName}-${deploymentNameSuffix}'
    scope: subscription(tier.subscriptionId)
    params: {
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    }
  }

module storageAccountDiagnosticSettings '../../../modules/storage-account-diagnostic-settings.bicep' = {
  name: 'deploy-sa-diag-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    blobDiagnosticSettingName: tier.namingConvention.storageAccountBlobDiagnosticSetting
    blobDiagnosticsLogs: blobDiagnosticsLogs
    blobDiagnosticsMetrics: blobDiagnosticsMetrics
    fileDiagnosticSettingName: tier.namingConvention.storageAccountFileDiagnosticSetting
    fileDiagnosticsLogs: fileDiagnosticsLogs
    fileDiagnosticsMetrics: fileDiagnosticsMetrics
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: hubStorageAccountResourceId
    queueDiagnosticSettingName: tier.namingConvention.storageAccountQueueDiagnosticSetting
    queueDiagnosticsLogs: queueDiagnosticsLogs
    queueDiagnosticsMetrics: queueDiagnosticsMetrics
    storageAccountDiagnosticSettingName: tier.namingConvention.storageAccountDiagnosticSetting
    storageAccountDiagnosticsLogs: storageAccountDiagnosticsLogs
    storageAccountDiagnosticsMetrics: storageAccountDiagnosticsMetrics
    storageAccountName: split(storageAccountResourceId, '/')[8]
    tableDiagnosticSettingName: tier.namingConvention.storageAccountTableDiagnosticSetting
    tableDiagnosticsLogs: tableDiagnosticsLogs
    tableDiagnosticsMetrics: tableDiagnosticsMetrics
  }
}

module keyvaultDiagnostics '../../../modules/key-vault-diagnostic-setting.bicep' = {
  name: 'deploy-kv-diags-${tier.shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    keyVaultDiagnosticSettingName: tier.namingConvention.keyVaultDiagnosticSetting
    keyVaultName: keyVaultName
    keyVaultStorageAccountId: storageAccountResourceId
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: keyVaultDiagnosticLogs
    metrics: keyVaultDiagnosticMetrics
  }
}  

module networkSecurityGroupDiagnostics '../../../modules/network-security-group-diagnostic-setting.bicep' = {
  name: 'deploy-nsg-diags-${tier.shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: tier.namingConvention.networkWatcherFlowLogsNetworkSecurityGroup
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticSettingName: tier.namingConvention.networkSecurityGroupDiagnosticSetting
    networkSecurityGroupName: split(tier.networkSecurityGroupResourceId, '/')[8]
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    storageAccountResourceId: storageAccountResourceId
    tiername: tier.name
  }
}

module virtualNetworkDiagnostics '../../../modules/virtual-network-diagnostic-setting.bicep' = {
  name: 'deploy-vnet-diags-${tier.shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: tier.namingConvention.networkWatcherFlowLogsVirtualNetwork
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: virtualNetworkDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceId
    metrics: virtualNetworkDiagnosticsMetrics
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    tiername: tier.name
    virtualNetworkDiagnosticSettingName: tier.namingConvention.virtualNetworkDiagnosticSetting
    virtualNetworkName: virtualNetworkName
  }
}

module networkInterfaceDiagnostics '../../../modules/network-interface-diagnostic-setting.bicep' = [for (networkInterfaceResourceId, i) in networkInterfaceResourceIds: {
  name: 'deploy-nic-diags-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(split(networkInterfaceResourceId, '/')[2], split(networkInterfaceResourceId, '/')[4])
  params: {
    delimiter: delimiter
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: []
    metrics: networkInterfaceDiagnosticsMetrics
    networkInterfaceResourceId: networkInterfaceResourceId
    storageAccountResourceIds: [
      storageAccountResourceId
    ]
    tiers: [
      tier
    ]
    tokens: tokens
  }
}]
