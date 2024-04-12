targetScope = 'subscription'

param deployActivityLogDiagnosticSetting bool
param deploymentNameSuffix string
param logAnalyticsWorkspaceResourceId string
param network object
param networkSecurityGroupDiagnosticsLogs array
param networkSecurityGroupDiagnosticsMetrics array
param storageAccountResourceId string
param virtualNetworkDiagnosticsLogs array
param virtualNetworkDiagnosticsMetrics array

module activityLogDiagnosticSettings '../../../modules/activity-log-diagnostic-settings.bicep' = if (deployActivityLogDiagnosticSetting) {
  name: 'deploy-activity-diags-${network.name}-${deploymentNameSuffix}'
  scope: subscription(network.subscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
  }
}

module networkSecurityGroupDiagnostics '../../../modules/network-security-group-diagnostics.bicep' = {
  name: 'deploy-nsg-diags-${network.name}-${deploymentNameSuffix}'
  scope: resourceGroup(network.subscriptionId, network.resourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: networkSecurityGroupDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceId
    metrics: networkSecurityGroupDiagnosticsMetrics
    name: network.networkSecurityGroupName
  }
}

module virtualNetworkDiagnostics '../../../modules/virtual-network-diagnostics.bicep' = {
  name: 'deploy-vnet-diags-${network.name}-${deploymentNameSuffix}'
  scope: resourceGroup(network.subscriptionId, network.resourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: virtualNetworkDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceId
    metrics: virtualNetworkDiagnosticsMetrics
    name: network.virtualNetworkName
  }
}
