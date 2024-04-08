targetScope = 'subscription'

param deploymentNameSuffix string
param firewallDiagnosticsLogs array
param firewallDiagnosticsMetrics array
param KeyVaultName string
param keyVaultDiagnosticLogs array
param logAnalyticsWorkspaceResourceId string
param networks array
param networkSecurityGroupDiagnosticsLogs array
param networkSecurityGroupDiagnosticsMetrics array
param publicIPAddressDiagnosticsLogs array
param publicIPAddressDiagnosticsMetrics array
param storageAccountResourceIds array
param supportedClouds array
param virtualNetworkDiagnosticsLogs array
param virtualNetworkDiagnosticsMetrics array

var hub = first(filter(networks, network => network.name == 'hub'))
var hubResourceGroupName = hub.resourceGroupName
var hubSubscriptionId = hub.subscriptionId
var operations = first(filter(networks, network => network.name == 'operations'))
var publicIPAddressNames = [
  hub.firewallClientPublicIPAddressName
  hub.firewallManagementPublicIPAddressName
]

module activityLogDiagnosticSettings 'activity-log-diagnostic-settings.bicep' = [for (network, i) in networks: if (network.deployUniqueResources) {
  name: 'deploy-activity-diags-${network.name}-${deploymentNameSuffix}'
  scope: subscription(network.subscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
  }
}]

module logAnalyticsWorkspaceDiagnosticSetting 'log-analytics-diagnostic-setting.bicep' = {
  name: 'deploy-law-diag-${deploymentNameSuffix}'
  scope: resourceGroup(operations.subscriptionId, operations.resourceGroupName)
  params: {
    diagnosticStorageAccountName: operations.logStorageAccountName
    logAnalyticsWorkspaceName: split(logAnalyticsWorkspaceResourceId, '/')[8]
    supportedClouds: supportedClouds
  }
}

module networkSecurityGroupDiagnostics '../modules/network-security-group-diagnostics.bicep' = [for (network, i) in networks: {
  name: 'deploy-nsg-diags-${network.name}-${deploymentNameSuffix}'
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
  name: 'deploy-vnet-diags-${network.name}-${deploymentNameSuffix}'
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
  name: 'deploy-pip-diags-${split(publicIPAddressName, '-')[2]}-${split(publicIPAddressName, '-')[3]}-${deploymentNameSuffix}'
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
  name: 'deploy-afw-diags-${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: firewallDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceIds[0]
    metrics: firewallDiagnosticsMetrics
    name: hub.firewallName
  }
}

module keyvaultDiagnostics '../modules/key-vault-diagnostics.bicep' = {
  name: 'deploy-kv-diags-${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: keyVaultDiagnosticLogs
    keyVaultstorageAccountId: storageAccountResourceIds[0]
    name: KeyVaultName
  }
}
