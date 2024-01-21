param firewallDiagnosticsLogs array
param firewallDiagnosticsMetrics array
param firewallName string
param hubStorageAccountResourceId string
param logAnalyticsWorkspaceResourceId string
param networkSecurityGroupDiagnosticsLogs array
param networkSecurityGroupDiagnosticsMetrics array
param networkSecurityGroupName string
param publicIPAddressDiagnosticsLogs array
param publicIPAddressDiagnosticsMetrics array
param publicIPAddressNames array
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

module publicIpAddressDiagnostics '../modules/public-ip-address-diagnostics.bicep' = [for publicIPAddressName in publicIPAddressNames: {
  name: 'publicIPAddressDiagnostics_${publicIPAddressName}'
  params: {
    hubStorageAccountResourceId: hubStorageAccountResourceId
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    name: publicIPAddressName
    publicIPAddressDiagnosticsLogs: publicIPAddressDiagnosticsLogs
    publicIPAddressDiagnosticsMetrics: publicIPAddressDiagnosticsMetrics
  }
}]

module firewallDiagnostics '../modules/firewall-diagnostics.bicep' = {
  name: 'firewallDiagnostics'
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: firewallDiagnosticsLogs
    logStorageAccountResourceId: hubStorageAccountResourceId
    metrics: firewallDiagnosticsMetrics
    name: firewallName
  }
}
