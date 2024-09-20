/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@description('An array of additional subnets to support the tier3 workload.')
param additionalSubnets array = []

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

@description('An array of Key Vault Diagnostic Logs categories to collect. See "https://learn.microsoft.com/en-us/azure/key-vault/general/logging?tabs=Vault" for valid values.')
param keyVaultDiagnosticsLogs array = [
  {
    category: 'AuditEvent'
    enabled: true
  }
  {
    category: 'AzurePolicyEvaluationDetails'
    enabled: true
  }
]

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
param policy string = 'NISTRev4'

@description('The stamp index allows for multiple AVD stamps with the same business unit or project to support different use cases.')
param stampIndex string = ''

@description('The address prefix for the workload subnet.')
param subnetAddressPrefix string = ''

@description('The custom name for the workload subnet if the naming convention is not desired. Subnets are child resources and do not require a unique name between virtual networks, only within the same virtual network.')
param subnetName string = ''

@description('The tags to apply to the resources.')
param tags object = {}

@description('The address prefix for the workload Virtual Network.')
param virtualNetworkAddressPrefix string = ''

@description('The diagnostic logs to apply to the workload Virtual Network.')
param virtualNetworkDiagnosticsLogs array = []

@description('The metrics to monitor for the workload Virtual Network.')
param virtualNetworkDiagnosticsMetrics array = []

@minLength(1)
@maxLength(10)
@description('The name for the workload.')
param workloadName string = 'tier3'

@minLength(1)
@maxLength(3)
@description('The short name for the workload.')
param workloadShortName string = 't3'

var hubResourceGroupName = split(hubVirtualNetworkResourceId, '/')[4]
var hubSubscriptionId = split(hubVirtualNetworkResourceId, '/')[2]
var subscriptionId = subscription().subscriptionId

resource azureFirewall 'Microsoft.Network/azureFirewalls@2020-11-01' existing = {
  name: split(firewallResourceId, '/')[8]
  scope: resourceGroup(split(firewallResourceId, '/')[2], split(firewallResourceId, '/')[4])
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: split(hubVirtualNetworkResourceId, '/')[8]
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
}

module logic '../../modules/logic.bicep' = {
  name: 'get-logic-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    location: location
    networks: [
      {
        name: workloadName
        shortName: workloadShortName
        deployUniqueResources: false
        subscriptionId: subscriptionId
        nsgDiagLogs: networkSecurityGroupDiagnosticsLogs
        nsgDiagMetrics: networkSecurityGroupDiagnosticsMetrics
        nsgRules: networkSecurityGroupRules
        vnetAddressPrefix: virtualNetworkAddressPrefix
        vnetDiagLogs: virtualNetworkDiagnosticsLogs
        vnetDiagMetrics: virtualNetworkDiagnosticsMetrics
        subnetAddressPrefix: subnetAddressPrefix
      }
    ]
    resourcePrefix: identifier
    stampIndex: stampIndex
  }
}

module rg '../../modules/resource-group.bicep' = if (!(empty(virtualNetworkAddressPrefix))) {
  name: 'deploy-rg-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: logic.outputs.mlzTags
    name: replace(logic.outputs.tiers[0].namingConvention.resourceGroup, logic.outputs.tokens.service, 'network')
    tags: tags
  }
}

module networking 'modules/networking.bicep' = if (!(empty(virtualNetworkAddressPrefix))) {
  name: 'deploy-network-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    additionalSubnets: additionalSubnets
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcher: deployNetworkWatcher
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    location: location
    mlzTags: logic.outputs.mlzTags
    networkSecurityGroupName: logic.outputs.tiers[0].namingConvention.networkSecurityGroup
    networkSecurityGroupRules: networkSecurityGroupRules
    networkWatcherName: logic.outputs.tiers[0].namingConvention.networkWatcher
    resourceGroupName: rg.outputs.name
    routeTableName: logic.outputs.tiers[0].namingConvention.routeTable
    routeTableRouteNextHopIpAddress: azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
    subnetAddressPrefix: subnetAddressPrefix
    subnetName: empty(subnetName) ? logic.outputs.tiers[0].namingConvention.subnet : subnetName
    subscriptionId: subscriptionId
    tags: tags
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkName: logic.outputs.tiers[0].namingConvention.virtualNetwork
    vNetDnsServers: virtualNetwork.properties.?dhcpOptions.dnsServers ?? [] 
    workloadShortName: workloadShortName
  }
  dependsOn: [
    rg
  ]
}

// This module deploys VNET links when the Azure Firewall SKU is "Basic".
module virtualNetworkLinks 'modules/virtual-network-links.bicep' = if (!(empty(virtualNetworkAddressPrefix))) {
  name: 'deploy-vnet-links-${workloadShortName}-sub-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    azureFirewallSku: azureFirewall.properties.sku.tier
    deploymentNameSuffix: deploymentNameSuffix
    privateDnsZoneNames: logic.outputs.privateDnsZones
    virtualNetworkName: networking.outputs.virtualNetworkName
    virtualNetworkResourceGroupName: rg.outputs.name
    virtualNetworkSubscriptionId: subscriptionId
    workloadShortName: workloadShortName
  }
}

module customerManagedKeys '../../modules/customer-managed-keys.bicep' = if (!(empty(virtualNetworkAddressPrefix))) {
  name: 'deploy-cmk-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyVaultPrivateDnsZoneResourceId: resourceId(
      hubSubscriptionId,
      hubResourceGroupName,
      'Microsoft.Network/privateDnsZones',
      replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
    )
    location: location
    mlzTags: logic.outputs.mlzTags
    resourceAbbreviations: logic.outputs.resourceAbbreviations
    resourceGroupName: rg.outputs.name
    subnetResourceId: networking.outputs.subnets[0].id
    tags: tags
    tier: logic.outputs.tiers[0]
    tokens: logic.outputs.tokens
    workloadShortName: workloadShortName
  }
}

module storage 'modules/storage.bicep' = if (!(empty(virtualNetworkAddressPrefix))) {
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
    mlzTags: logic.outputs.mlzTags
    network: logic.outputs.tiers[0]
    resourceGroupName: rg.outputs.name
    serviceToken: logic.outputs.tokens.service
    storageEncryptionKeyName: customerManagedKeys.outputs.storageKeyName
    subnetResourceId: networking.outputs.subnets[0].id
    tablesPrivateDnsZoneResourceId: resourceId(
      hubSubscriptionId,
      hubResourceGroupName,
      'Microsoft.Network/privateDnsZones',
      'privatelink.table.${environment().suffixes.storage}'
    )
    tags: tags
    tier: logic.outputs.tiers[0]
    userAssignedIdentityResourceId: customerManagedKeys.outputs.userAssignedIdentityResourceId
  }
}

module diagnostics 'modules/diagnostics.bicep' = if (!(empty(virtualNetworkAddressPrefix))) {
  name: 'deploy-diag-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deploymentNameSuffix: deploymentNameSuffix
    keyVaultDiagnosticLogs: keyVaultDiagnosticsLogs
    keyVaultName: customerManagedKeys.outputs.keyVaultName
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: networkSecurityGroupDiagnosticsMetrics
    networkSecurityGroupName: networking.outputs.networkSecurityGroupName
    resourceGroupName: rg.outputs.name
    serviceToken: logic.outputs.tokens.service
    storageAccountResourceId: storage.outputs.storageAccountResourceId
    tier: logic.outputs.tiers[0]
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics
    virtualNetworkName: networking.outputs.virtualNetworkName
  }
}

module policyAssignments '../../modules/policy-assignments.bicep' =
  if (deployPolicy && (!(empty(virtualNetworkAddressPrefix)))) {
    name: 'assign-policy-${workloadShortName}-${deploymentNameSuffix}'
    params: {
      deploymentNameSuffix: deploymentNameSuffix
      location: location
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
      tiers: logic.outputs.tiers
      policy: policy
      resourceGroupNames: [
        rg.outputs.name
      ]
    }
    dependsOn: [
      rg
    ]
  }

module defenderForCloud '../../modules/defender-for-cloud.bicep' =
  if (deployDefender && (!(empty(virtualNetworkAddressPrefix)))) {
    name: 'set-defender-${workloadShortName}-${deploymentNameSuffix}'
    params: {
      emailSecurityContact: emailSecurityContact
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    }
  }

output diskEncryptionSetResourceId string = !(empty(virtualNetworkAddressPrefix)) ? customerManagedKeys.outputs.diskEncryptionSetResourceId : ''
output dnsServers array = !(empty(virtualNetworkAddressPrefix)) ? virtualNetwork.properties.?dhcpOptions.dnsServers ?? [] : []
output keyVaultUri string = !(empty(virtualNetworkAddressPrefix)) ? customerManagedKeys.outputs.keyVaultUri : ''
output locationProperties object = logic.outputs.locationProperties
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspaceResourceId
output mlzTags object = logic.outputs.mlzTags
output namingConvention object = logic.outputs.tiers[0].namingConvention
output privateDnsZones array = logic.outputs.privateDnsZones
output resourceAbbreviations object = logic.outputs.resourceAbbreviations
output resourcePrefix string = azureFirewall.tags.resourcePrefix
output storageAccountResourceId string = !(empty(virtualNetworkAddressPrefix)) ? storage.outputs.storageAccountResourceId : ''
output storageEncryptionKeyName string = !(empty(virtualNetworkAddressPrefix)) ? customerManagedKeys.outputs.storageKeyName: ''
output subnets array = !(empty(virtualNetworkAddressPrefix)) ? networking.outputs.subnets : []
output tier object = logic.outputs.tiers[0]
output tokens object = logic.outputs.tokens
output userAssignedIdentityResourceId string = !(empty(virtualNetworkAddressPrefix)) ? customerManagedKeys.outputs.userAssignedIdentityResourceId : ''
