/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bastionDiagnosticsLogs array
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
param serviceToken string
param storageAccountResourceIds array
param supportedClouds array
param tiers array

var hub = (filter(tiers, tier => tier.name == 'hub'))[0]
var hubResourceGroupName = filter(resourceGroupNames, name => contains(name, 'hub'))[0]
var operations = first(filter(tiers, tier => tier.name == 'operations'))
var operationsResourceGroupName = filter(resourceGroupNames, name => contains(name, 'operations'))[0]
var publicIPAddresses = union([
  {
    name: hub.namingConvention.azureFirewallClientPublicIPAddress
    diagName: hub.namingConvention.azureFirewallClientPublicIPAddressDiagnosticSetting
  }
  {
    name: hub.namingConvention.azureFirewallManagementPublicIPAddress
    diagName: hub.namingConvention.azureFirewallManagementPublicIPAddressDiagnosticSetting
  }
], deployBastion ? [
  {
    name: hub.namingConvention.bastionHostPublicIPAddress
    diagName: hub.namingConvention.bastionHostPublicIPAddressDiagnosticSetting
  }
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
    logAnalyticsWorkspaceDiagnosticSettingName: operations.namingConvention.logAnalyticsWorkspaceDiagnosticSetting
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
    networkSecurityGroupDiagnosticSettingName: tier.namingConvention.networkSecurityGroupDiagnosticSetting
    networkSecurityGroupName: tier.namingConvention.networkSecurityGroup
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
    virtualNetworkDiagnosticSettingName: tier.namingConvention.virtualNetworkDiagnosticSetting
    virtualNetworkName: tier.namingConvention.virtualNetwork
  }
}]

module publicIpAddressDiagnostics '../modules/public-ip-address-diagnostics.bicep' = [for publicIPAddress in publicIPAddresses: {
  name: 'deploy-pip-diags-${split(publicIPAddress.name, '-')[2]}-${split(publicIPAddress.name, '-')[3]}-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    hubStorageAccountResourceId: storageAccountResourceIds[0]
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    publicIPAddressDiagnosticSettingName: publicIPAddress.diagName
    publicIPAddressDiagnosticsLogs: publicIPAddressDiagnosticsLogs
    publicIPAddressDiagnosticsMetrics: publicIPAddressDiagnosticsMetrics
    publicIPAddressName: publicIPAddress.name
  }
}]

module firewallDiagnostics '../modules/firewall-diagnostics.bicep' = {
  name: 'deploy-afw-diags-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    firewallDiagnosticSettingsName: hub.namingConvention.azureFirewallDiagnosticSetting
    firewallName: hub.namingConvention.azureFirewall
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: firewallDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceIds[0]
    metrics: firewallDiagnosticsMetrics
  }
}

module keyvaultDiagnostics '../modules/key-vault-diagnostics.bicep' = {
  name: 'deploy-kv-diags-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    keyVaultDiagnosticSettingName: replace(hub.namingConvention.keyVaultDiagnosticSetting, serviceToken, '')
    keyVaultName: keyVaultName
    keyVaultStorageAccountId: storageAccountResourceIds[0]
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: keyVaultDiagnosticLogs
  }
}

module bastionDiagnostics '../modules/bastion-diagnostics.bicep' = {
  name: 'deploy-bastion-diags-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    bastionDiagnosticSettingName: replace(hub.namingConvention.bastionHostPublicIPAddressDiagnosticSetting, serviceToken, '')
    bastionName: hub.namingConvention.bastionHost
    bastionStorageAccountId: storageAccountResourceIds[0]
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: bastionDiagnosticsLogs
  }
}
