/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@description('An array of additional subnets to support the tier3 workload.')
param additionalSubnets array = []

@description('An array of Blob Diagnostic Logs categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/storage/blobs/monitor-blob-storage?tabs=azure-portal#enable-diagnostic-logging.')
param blobDiagnosticsLogs array = [
  {
    categoryGroup: 'allLogs'
    enabled: true
  }
]

@description('An array of Blob Diagnostic Metrics categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/storage/blobs/monitor-blob-storage?tabs=azure-portal#enable-metrics.')
param blobDiagnosticsMetrics array = [
  {
    category: 'Transaction'
    enabled: true
  }
]

@description('The custom firewall rule collection groups that override the default firewall rule collection groups.')
param customFirewallRuleCollectionGroups array = []

@description('Choose whether to deploy a diagnostic setting for the Activity Log.')
param deployActivityLogDiagnosticSetting bool

@description('Choose whether to deploy Defender for Cloud.')
param deployDefender bool

@description('The suffix to append to the deployment name. It defaults to the current UTC date and time.')
param deploymentNameSuffix string = utcNow()

@description('When set to true, deploys Network Watcher Traffic Analytics. It defaults to "false".')
param deployNetworkWatcherTrafficAnalytics bool = false

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

@description('An array of File Diagnostic Logs categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/storage/files/monitor-file-storage?tabs=azure-portal#enable-diagnostic-logging.')
param fileDiagnosticsLogs array = [
  {
    categoryGroup: 'allLogs'
    enabled: true
  }
]

@description('An array of File Diagnostic Metrics categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/storage/files/monitor-file-storage?tabs=azure-portal#enable-metrics.')
param fileDiagnosticsMetrics array = [
  {
    category: 'Transaction'
    enabled: true
  }
]

@description('The resource ID of the Azure Firewall in the HUB.')
param firewallResourceId string

@description('The resource ID of the HUB Storage Account.')
param hubStorageAccountResourceId string

@description('The resource ID of the HUB Virtual Network.')
param hubVirtualNetworkResourceId string

@maxLength(3)
@description('The identifier for the resource names. This value should represent the workload, project, or business unit.')
param identifier string

@description('An array of Key Vault Diagnostic Logs categories to collect. See "https://learn.microsoft.com/en-us/azure/key-vault/general/logging?tabs=Vault" for valid values.')
param keyVaultDiagnosticLogs array = [
  {
    category: 'AuditEvent'
    enabled: true
  }
  {
    category: 'AzurePolicyEvaluationDetails'
    enabled: true
  }
]

@description('The Key Vault Diagnostic Metrics to collect. See the following URL for valid settings: "https://learn.microsoft.com/azure/key-vault/general/logging?tabs=Vault".')
param keyVaultDiagnosticMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('The location for the deployment. It defaults to the location of the deployment.')
param location string = deployment().location

@description('The resource ID of the Log Analytics Workspace to use for log storage.')
param logAnalyticsWorkspaceResourceId string

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param logStorageSkuName string = 'Standard_GRS'

@description('An array of metrics to enable on the diagnostic setting for network interfaces.')
param networkInterfaceDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

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

@description('The rules to apply to the Network Security Group.')
param networkSecurityGroupRules array = []

@description('The number of days to retain Network Watcher Flow Logs. It defaults to "30".')  
param networkWatcherFlowLogsRetentionDays int = 30

@allowed([
  'NetworkSecurityGroup'
  'VirtualNetwork'
])
@description('When set to "true", enables Virtual Network Flow Logs. It defaults to "true" as its required by MCSB.')
param networkWatcherFlowLogsType string = 'VirtualNetwork'

@description('An array of Queue Diagnostic Logs categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/storage/queues/monitor-queue-storage?tabs=azure-portal#enable-diagnostic-logging.')
param queueDiagnosticsLogs array = [
  {
    categoryGroup: 'allLogs'
    enabled: true
  }
]

@description('An array of Queue Diagnostic Metrics categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/storage/queues/monitor-queue-storage?tabs=azure-portal#enable-metrics.')
param queueDiagnosticsMetrics array = [
  {
    category: 'Transaction'
    enabled: true
  }
]

@description('The policy to assign to the workload.')
param policy string = 'NISTRev4'

@description('The stamp index allows for multiple deployments of a similar workload without naming conflicts.')
param stampIndex string = ''

@description('An array of Storage Account Diagnostic Logs categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/storage/common/monitor-storage?tabs=azure-portal#enable-diagnostic-logging.')
param storageAccountDiagnosticsLogs array = []

@description('An array of Storage Account Diagnostic Metrics categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/storage/common/monitor-storage?tabs=azure-portal#enable-metrics.')
param storageAccountDiagnosticsMetrics array = [
  {
    category: 'Transaction'
    enabled: true
  }
]

@description('The address prefix for the workload subnet.')
param subnetAddressPrefix string = ''

@description('The custom name for the workload subnet if the naming convention is not desired. Subnets are child resources and do not require a unique name between virtual networks, only within the same virtual network.')
param subnetName string = ''

@description('An array of Table Diagnostic Logs categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/storage/tables/monitor-table-storage?tabs=azure-portal#enable-diagnostic-logging.')
param tableDiagnosticsLogs array = [
  {
    categoryGroup: 'allLogs'
    enabled: true
  }
]

@description('An array of Table Diagnostic Metrics categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/storage/tables/monitor-table-storage?tabs=azure-portal#enable-metrics.')
param tableDiagnosticsMetrics array = [
  {
    category: 'Transaction'
    enabled: true
  }
]

@description('The tags to apply to the resources.')
param tags object = {}

@description('The address prefix for the workload Virtual Network.')
param virtualNetworkAddressPrefix string = ''

@description('The diagnostic logs to apply to the workload Virtual Network.')
param virtualNetworkDiagnosticsLogs array = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]

@description('The metrics to monitor for the workload Virtual Network.')
param virtualNetworkDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('The local administrator username for Windows virtual machines. This value is needed if you plan to deploy the following Azure Policy initiatives: CMMC Level 3, DoD Impact Level 5, or NIST SP 800-53 Rev. 4 It defaults to "xadmin".')
param windowsAdministratorsGroupMembership string = 'xadmin'

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
var deploymentIndex = empty(stampIndex) ? '' : '${stampIndex}-'
var subscriptionId = subscription().subscriptionId

resource azureFirewall 'Microsoft.Network/azureFirewalls@2020-11-01' existing = {
  name: split(firewallResourceId, '/')[8]
  scope: resourceGroup(split(firewallResourceId, '/')[2], split(firewallResourceId, '/')[4])
}

resource virtualNetwork_hub 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: split(hubVirtualNetworkResourceId, '/')[8]
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
}

module firewallRules '../../modules/firewall-rules.bicep' = if (!empty(customFirewallRuleCollectionGroups)) {
  name: 'deploy-firewall-rules-${workloadShortName}-${deploymentIndex}${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    firewallPolicyName: split(azureFirewall.properties.firewallPolicy.id, '/')[8]
    firewallRuleCollectionGroups: customFirewallRuleCollectionGroups
  }
}

// Virtual Network Peers
// This module outputs all the subscription IDs from the virtual network peerings of the 
// hub virtual network to determine if the target subscription for this deployment is unique.
module virtualNetworkPeerings 'modules/virtual-network-peerings.bicep' = {
  name: 'get-vnet-peerings-${workloadShortName}-${deploymentIndex}${deploymentNameSuffix}'
  params: {
    virtualNetworkPeerings: virtualNetwork_hub.properties.virtualNetworkPeerings
  }
}

module networking 'modules/networking.bicep' = {
  name: 'deploy-network-${workloadShortName}-${deploymentIndex}${deploymentNameSuffix}'
  params: {
    additionalSubnets: additionalSubnets
    deploymentIndex: deploymentIndex
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    identifier: identifier
    location: location
    network: {
      name: workloadName
      nsgDiagLogs: networkSecurityGroupDiagnosticsLogs
      nsgRules: networkSecurityGroupRules
      shortName: workloadShortName
      subnetAddressPrefix: subnetAddressPrefix
      subscriptionId: subscriptionId
      vnetAddressPrefix: virtualNetworkAddressPrefix
      vnetDiagLogs: virtualNetworkDiagnosticsLogs
      vnetDiagMetrics: virtualNetworkDiagnosticsMetrics
    }
    routeTableRouteNextHopIpAddress: azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
    stampIndex: stampIndex
    subnetName: subnetName
    tags: tags
    vNetDnsServers: virtualNetwork_hub.properties.?dhcpOptions.dnsServers ?? []
  }
}

module storage 'modules/storage.bicep' = {
  name: 'deploy-storage-${workloadShortName}-${deploymentIndex}${deploymentNameSuffix}'
  params: {
    blobsPrivateDnsZoneResourceId: resourceId(hubSubscriptionId, hubResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.blob.${environment().suffixes.storage}')
    delimiter: networking.outputs.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    filesPrivateDnsZoneResourceId: resourceId(hubSubscriptionId, hubResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.file.${environment().suffixes.storage}')
    location: location
    logStorageSkuName: logStorageSkuName
    mlzTags: networking.outputs.mlzTags
    queuesPrivateDnsZoneResourceId: resourceId(hubSubscriptionId, hubResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.queue.${environment().suffixes.storage}')
    resourceAbbreviations: networking.outputs.resourceAbbreviations
    resourceGroupName: networking.outputs.tier.resourceGroupName
    subnetResourceId: networking.outputs.tier.subnetResourceId
    tablesPrivateDnsZoneResourceId: resourceId(hubSubscriptionId, hubResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.table.${environment().suffixes.storage}')
    tags: tags
    tier: networking.outputs.tier
    deploymentIndex: deploymentIndex
    environmentAbbreviation: environmentAbbreviation
    hubResourceGroupName: hubResourceGroupName
    hubSubscriptionId: hubSubscriptionId
    workloadShortName: workloadShortName
  }
}

module diagnostics 'modules/diagnostics.bicep' = {
  name: 'deploy-diag-${workloadShortName}-${deploymentIndex}${deploymentNameSuffix}'
  params: {
    blobDiagnosticsLogs: blobDiagnosticsLogs
    blobDiagnosticsMetrics: blobDiagnosticsMetrics
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    fileDiagnosticsLogs: fileDiagnosticsLogs
    fileDiagnosticsMetrics: fileDiagnosticsMetrics
    hubStorageAccountResourceId: hubStorageAccountResourceId
    keyVaultDiagnosticLogs: keyVaultDiagnosticLogs
    keyVaultDiagnosticMetrics: keyVaultDiagnosticMetrics
    keyVaultName: storage.outputs.keyVaultName
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    networkInterfaceDiagnosticsMetrics: networkInterfaceDiagnosticsMetrics
    networkInterfaceResourceIds: storage.outputs.networkInterfaceResourceIds
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    queueDiagnosticsLogs: queueDiagnosticsLogs
    queueDiagnosticsMetrics: queueDiagnosticsMetrics
    storageAccountDiagnosticsLogs: storageAccountDiagnosticsLogs
    storageAccountDiagnosticsMetrics: storageAccountDiagnosticsMetrics
    storageAccountResourceId: storage.outputs.storageAccountResourceId
    tableDiagnosticsLogs: tableDiagnosticsLogs
    tableDiagnosticsMetrics: tableDiagnosticsMetrics
    tier: networking.outputs.tier
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics
    virtualNetworkName: networking.outputs.virtualNetworkName
  }
}

module policyAssignments '../../modules/policy-assignments.bicep' =
  if (deployPolicy) {
    name: 'assign-policy-${workloadShortName}-${deploymentIndex}${deploymentNameSuffix}'
    params: {
      deploymentNameSuffix: deploymentNameSuffix
      location: location
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
      policy: policy
      tiers: [
        networking.outputs.tier
      ]
      windowsAdministratorsGroupMembership: windowsAdministratorsGroupMembership
    }
  }

module defenderForCloud '../../modules/defender-for-cloud.bicep' =
  if (deployDefender) {
    name: 'set-defender-${workloadShortName}-${deploymentIndex}${deploymentNameSuffix}'
    params: {
      emailSecurityContact: emailSecurityContact
    }
  }

output delimiter string = networking.outputs.delimiter
output locationProperties object = networking.outputs.locationProperties
output mlzTags object = networking.outputs.mlzTags
output privateDnsZones array = networking.outputs.privateDnsZones
output resourceAbbreviations object = networking.outputs.resourceAbbreviations
output tier object = union({
  dnsServers: virtualNetwork_hub.properties.?dhcpOptions.dnsServers ?? []
  logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
}, 
  networking.outputs.tier
)
