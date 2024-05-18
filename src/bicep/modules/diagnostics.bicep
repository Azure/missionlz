/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deployBastion bool
param deploymentNameSuffix string
param firewallDiagnosticsLogs array
param firewallDiagnosticsMetrics array
param keyVaultDiagnosticLogs array
param keyVaultName string
param logAnalyticsWorkspaceResourceId string
param publicIPAddressDiagnosticsLogs array
param publicIPAddressDiagnosticsMetrics array
param resourceGroupNames array
param storageAccountResourceIds array
param supportedClouds array
param tiers array

var hub = (filter(tiers, tier => tier.name == 'hub'))[0]
var hubResourceGroupName = filter(resourceGroupNames, name => contains(name, 'hub'))[0]
var operations = first(filter(tiers, tier => tier.name == 'operations'))
var operationsResourceGroupName = filter(resourceGroupNames, name => contains(name, 'operations'))[0]
var publicIPAddressNames = union([
  hub.namingConvention.azureFirewallClientPublicIPAddress
  hub.namingConvention.azureFirewallManagementPublicIPAddress
], deployBastion ? [
  hub.namingConvention.bastionPublicIPAddress
] : [])

module activityLogDiagnosticSettings 'activity-log-diagnostic-settings.bicep' = [for (tier, i) in tiers: if (tier.deployUniqueResources) {
  name: 'deploy-activity-diags-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
  }
}]

module logAnalyticsWorkspaceDiagnosticSetting 'log-analytics-diagnostic-setting.bicep' = {
  name: 'deploy-law-diag-${deploymentNameSuffix}'
  scope: resourceGroup(operations.subscriptionId, operationsResourceGroupName)
  params: {
    diagnosticStorageAccountName: operations.namingConvention.storageAccount
    logAnalyticsWorkspaceName: split(logAnalyticsWorkspaceResourceId, '/')[8]
    supportedClouds: supportedClouds
  }
}

module networkSecurityGroupDiagnostics '../modules/network-security-group-diagnostics.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-nsg-diags-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupNames[i])
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: tier.nsgDiagLogs
    logStorageAccountResourceId: storageAccountResourceIds[i]
    metrics: tier.nsgDiagMetrics
    name: tier.namingConvention.networkSecurityGroup
  }
}]

module virtualNetworkDiagnostics '../modules/virtual-network-diagnostics.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-vnet-diags-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupNames[i])
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: tier.vnetDiagLogs
    logStorageAccountResourceId: storageAccountResourceIds[i]
    metrics: tier.vnetDiagMetrics
    name: tier.namingConvention.virtualNetwork
  }
}]

module publicIpAddressDiagnostics '../modules/public-ip-address-diagnostics.bicep' = [for publicIPAddressName in publicIPAddressNames: {
  name: 'deploy-pip-diags-${split(publicIPAddressName, '-')[2]}-${split(publicIPAddressName, '-')[3]}-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
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
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: firewallDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceIds[0]
    metrics: firewallDiagnosticsMetrics
    name: hub.namingConvention.firewall
  }
}

module keyvaultDiagnostics '../modules/key-vault-diagnostics.bicep' = {
  name: 'deploy-kv-diags-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: keyVaultDiagnosticLogs
    keyVaultstorageAccountId: storageAccountResourceIds[0]
    name: keyVaultName
  }
}
