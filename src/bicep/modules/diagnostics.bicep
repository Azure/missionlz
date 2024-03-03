targetScope = 'subscription'

param firewallDiagnosticsLogs array
param firewallDiagnosticsMetrics array
param logAnalyticsWorkspaceResourceId string
param networks array
param networkSecurityGroupDiagnosticsLogs array
param networkSecurityGroupDiagnosticsMetrics array
param publicIPAddressDiagnosticsLogs array
param publicIPAddressDiagnosticsMetrics array
param storageAccountResourceIds array
param virtualNetworkDiagnosticsLogs array
param virtualNetworkDiagnosticsMetrics array

var hub = first(filter(networks, network => network.name == 'hub'))
var hubResourceGroupName = hub.resourceGroupName
var hubSubscriptionId = hub.subscriptionId
var publicIPAddressNames = [
  hub.firewallClientPublicIPAddressName
  hub.firewallManagementPublicIPAddressName
]

module networkSecurityGroupDiagnostics '../modules/network-security-group-diagnostics.bicep' = [for (network, i) in networks: {
  name: 'networkSecurityGroupDiagnostics'
  scope: resourceGroup(network.subscriptionId, network.resourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: networkSecurityGroupDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceIds[i]
    metrics: networkSecurityGroupDiagnosticsMetrics
    name: network.networkSecurityGroupName
  }
}]

module virtualNetworkDiagnostics '../modules/virtual-network-diagnostics.bicep' = [for (network, i) in networks: {
  name: 'virtualNetworkDiagnostics'
  scope: resourceGroup(network.subscriptionId, network.resourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: virtualNetworkDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceIds[i]
    metrics: virtualNetworkDiagnosticsMetrics
    name: network.virtualNetworkName
  }
}]

module publicIpAddressDiagnostics '../modules/public-ip-address-diagnostics.bicep' = [for publicIPAddressName in publicIPAddressNames: {
  name: 'publicIPAddressDiagnostics_${publicIPAddressName}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    hubStorageAccountResourceId: storageAccountResourceIds[0]
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    name: publicIPAddressName
    publicIPAddressDiagnosticsLogs: publicIPAddressDiagnosticsLogs
    publicIPAddressDiagnosticsMetrics: publicIPAddressDiagnosticsMetrics
  }
}]

module firewallDiagnostics '../modules/firewall-diagnostics.bicep' = {
  name: 'firewallDiagnostics'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: firewallDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceIds[0]
    metrics: firewallDiagnosticsMetrics
    name: hub.firewallName
  }
}
