/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@description('Choose whether to deploy a diagnostic setting for the Activity Log.')
param deployActivityLogDiagnosticSetting bool

@description('Choose whether to deploy Defender for Cloud.')
param deployDefender bool

@description('The suffix to append to the deployment name. It defaults to the current UTC date and time.')
param deploymentNameSuffix string = utcNow()

@description('Choose whether to deploy Network Watcher for the deployment location.')
param deployNetworkWatcher bool

@description('Choose whether to deploy a policy assignment.')
param deployPolicy bool

@description('The email address to use for Defender for Cloud notifications.')
param emailSecurityContact string

@allowed([
  'dev'
  'prod'
  'test'
])
@description('The abbreviation for the environment.')
param environmentAbbreviation string = 'dev'

@description('The resource ID of the Azure Firewall in the HUB.')
param firewallResourceId string

@description('The resource ID of the HUB Virtual Network.')
param hubVirtualNetworkResourceId string

@maxLength(3)
@description('The identifier for the resource names. This value should represent the workload, project, or business unit.')
param identifier string

@description('The location for the deployment. It defaults to the location of the deployment.')
param location string = deployment().location

@description('The resource ID of the Log Analytics Workspace to use for log storage.')
param logAnalyticsWorkspaceResourceId string

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param logStorageSkuName string = 'Standard_GRS'

@description('An array of Network Security Group diagnostic logs to apply to the workload Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param networkSecurityGroupDiagnosticsLogs array = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]

@description('The metrics to monitor for the Network Security Group.')
param networkSecurityGroupDiagnosticsMetrics array = []

@description('The rules to apply to the Network Security Group.')
param networkSecurityGroupRules array = []

@description('The policy to assign to the workload.')
param policy string

@description('The address prefix for the workload subnet.')
param subnetAddressPrefix string

@description('The tags to apply to the resources.')
param tags object = {}

@description('The address prefix for the workload Virtual Network.')
param virtualNetworkAddressPrefix string

@description('The diagnostic logs to apply to the workload Virtual Network.')
param virtualNetworkDiagnosticsLogs array = []

@description('The metrics to monitor for the workload Virtual Network.')
param virtualNetworkDiagnosticsMetrics array = []

@minLength(1)
@maxLength(10)
@description('The name for the workload.')
param workloadName string = 'Tier3'

@minLength(1)
@maxLength(3)
@description('The short name for the workload.')
param workloadShortName string = 't3'

var environmentName = {
  dev: 'Development'
  prod: 'Production'
  test: 'Test'
}
var mlzTags = {
  environment: environmentName[environmentAbbreviation]
  identifier: identifier
  workloadName: 'MissionLandingZone-${workloadName}'
  workloadVersion: loadTextContent('../../data/version.txt')
}
var hubResourceGroupName = split(hubVirtualNetworkResourceId, '/')[4]
var hubSubscriptionId = split(hubVirtualNetworkResourceId, '/')[2]
var subscriptionId = subscription().subscriptionId

resource azureFirewall 'Microsoft.Network/azureFirewalls@2020-11-01' existing = {
  name: split(firewallResourceId, '/')[8]
  scope: resourceGroup(split(firewallResourceId, '/')[2], split(firewallResourceId, '/')[4])
}

module namingConvention '../../modules/naming-convention.bicep' = {
  name: 'get-naming-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    environmentAbbreviation: environmentAbbreviation
    location: location
    resourcePrefix: identifier
  }
}

module logic 'modules/logic.bicep' = {
  name: 'get-logic-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    environmentAbbreviation: environmentAbbreviation
    resourcePrefix: identifier
    resources: namingConvention.outputs.resources
    subscriptionId: subscriptionId
    tokens: namingConvention.outputs.tokens
    workloadName: toLower(workloadName)
    workloadShortName: workloadShortName
  }
}

module rg '../../modules/resource-group.bicep' = {
  name: 'deploy-rg-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: mlzTags
    name: logic.outputs.network.resourceGroupName
    tags: tags
  }
}

module networking 'modules/networking.bicep' = {
  name: 'deploy-networking-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcher: deployNetworkWatcher
    firewallSkuTier: azureFirewall.properties.sku.tier
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    location: location
    mlzTags: mlzTags
    networkSecurityGroupName: logic.outputs.network.networkSecurityGroupName
    networkSecurityGroupRules: networkSecurityGroupRules
    networkWatcherName: logic.outputs.network.networkWatcherName
    resourceGroupName: logic.outputs.network.resourceGroupName
    routeTableName: logic.outputs.network.routeTableName
    routeTableRouteNextHopIpAddress: azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
    subnetAddressPrefix: subnetAddressPrefix
    subnetName: logic.outputs.network.subnetName
    subscriptionId: subscriptionId
    tags: tags
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkName: logic.outputs.network.virtualNetworkName
    vNetDnsServers: [
      azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
    ]
    workloadName: toLower(workloadName)
    workloadShortName: workloadShortName
  }
  dependsOn: [
    rg
  ]
}

module customerManagedKeys '../../modules/customer-managed-keys.bicep' = {
  name: 'deploy-cmk-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    keyVaultPrivateDnsZoneResourceId: resourceId(
      hubSubscriptionId,
      hubResourceGroupName,
      'Microsoft.Network/privateDnsZones',
      replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
    )
    location: location
    mlzTags: mlzTags
    networkProperties: logic.outputs.network
    subnetResourceId: networking.outputs.subnetResourceId
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  name: 'deploy-storage-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    blobsPrivateDnsZoneResourceId: resourceId(
      hubSubscriptionId,
      hubResourceGroupName,
      'Microsoft.Network/privateDnsZones',
      'privatelink.blob.${environment().suffixes.storage}'
    )
    keyVaultUri: customerManagedKeys.outputs.keyVaultUri
    location: location
    logStorageSkuName: logStorageSkuName
    mlzTags: mlzTags
    network: logic.outputs.network
    serviceToken: namingConvention.outputs.tokens.service
    storageEncryptionKeyName: customerManagedKeys.outputs.storageKeyName
    subnetResourceId: networking.outputs.subnetResourceId
    tablesPrivateDnsZoneResourceId: resourceId(
      hubSubscriptionId,
      hubResourceGroupName,
      'Microsoft.Network/privateDnsZones',
      'privatelink.table.${environment().suffixes.storage}'
    )
    tags: tags
    userAssignedIdentityResourceId: customerManagedKeys.outputs.userAssignedIdentityResourceId
  }
}

module diagnostics 'modules/diagnostics.bicep' = {
  name: 'deploy-diagnostics-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deploymentNameSuffix: deploymentNameSuffix
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    network: logic.outputs.network
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: networkSecurityGroupDiagnosticsMetrics
    storageAccountResourceId: storage.outputs.storageAccountResourceId
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics
  }
}

module policyAssignments '../../modules/policy-assignments.bicep' =
  if (deployPolicy) {
    name: 'assign-policy-${toLower(workloadName)}-${deploymentNameSuffix}'
    params: {
      deploymentNameSuffix: deploymentNameSuffix
      location: location
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
      networks: [
        logic.outputs.network
      ]
      policy: policy
    }
    dependsOn: [
      rg
    ]
  }

module defenderForCloud '../../modules/defenderForCloud.bicep' =
  if (deployDefender) {
    name: 'set-${toLower(workloadName)}-sub-defender'
    params: {
      emailSecurityContact: emailSecurityContact
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    }
  }

output diskEncryptionSetResourceId string = customerManagedKeys.outputs.diskEncryptionSetResourceId
output mlzTags object = mlzTags
output network object = logic.outputs.network
output subnetResourceId string = networking.outputs.subnetResourceId
output tokens object = namingConvention.outputs.tokens
