param hubStorageAccountResourceId string
param logAnalyticsWorkspaceResourceId string
param networkSecurityGroupDiagnosticsLogs array
param networkSecurityGroupDiagnosticsMetrics array
param networkSecurityGroupName string
param virtualNetworkDiagnosticsLogs array
param virtualNetworkDiagnosticsMetrics array
param virtualNetworkName string

module networkSecurityGroupDiagnostics '../modules/network-security-group-diagnostics.bicep' = {
  name: 'networkSecurityGroupDiagnostics'
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: networkSecurityGroupDiagnosticsLogs
    logStorageAccountResourceId: hubStorageAccountResourceId
    metrics: networkSecurityGroupDiagnosticsMetrics
    name: networkSecurityGroupName
  }
}

module virtualNetworkDiagnostics '../modules/virtual-network-diagnostics.bicep' = {
  name: 'virtualNetworkDiagnostics'
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: virtualNetworkDiagnosticsLogs
    logStorageAccountResourceId: hubStorageAccountResourceId
    metrics: virtualNetworkDiagnosticsMetrics
    name: virtualNetworkName
  }
}
