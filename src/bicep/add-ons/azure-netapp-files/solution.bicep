/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'



@description('The resource ID of the Azure Firewall in the HUB.')
param azureFirewallResourceId string

@description('The address prefix for the workload subnet.')
param azureNetAppFilesSubnetAddressPrefix string = '10.0.161.0/24'

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

@secure()
@description('The password for the account to domain join the AVD session hosts.')
param domainJoinPassword string

@description('The user principal name for the account to domain join the AVD session hosts.')
param domainJoinUserPrincipalName string

@description('The name of the domain that provides ADDS to the AVD session hosts.')
param domainName string

@description('The email address to use for Defender for Cloud notifications.')
param emailSecurityContact string

@allowed([
  'dev'
  'prod'
  'test'
])
@description('The abbreviation for the environment.')
param environmentAbbreviation string = 'dev'

@description('The name of the file share')
param fileShareName string

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

@description('The resource ID for an existing network watcher for the desired deployment location. Only one network watcher per location can exist in a subscription. The value can be left empty to create a new network watcher resource.')
param networkWatcherResourceId string = ''

@description('The distinguished name for the target Organization Unit in Active Directory Domain Services.')
param organizationalUnitPath string = ''

@description('The policy to assign to the workload.')
param policy string = 'NISTRev4'

@allowed([
  'Premium'
  'Standard'
])
@description('The performance SKU for Azure NetApp Files.')
param sku string

@description('The address prefix for the subnet containing the private endpoints.')
param subnetAddressPrefix string = '10.0.160.0/24'

@description('The tags to apply to the resources.')
param tags object = {}

@description('The address prefix for the workload Virtual Network.')
param virtualNetworkAddressPrefix string = '10.0.160.0/23'

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

@minLength(1)
@maxLength(10)
@description('The name for the workload.')
param workloadName string = 'netAppFile'

@minLength(1)
@maxLength(3)
@description('The short name for the workload.')
param workloadShortName string = 'anf'

// Spoke network
module tier3 '../tier3/solution.bicep' = {
  name: 'deploy-tier3-${deploymentNameSuffix}'
  params: {
    additionalSubnets:[
      {
        name: 'AzureNetAppFiles'
        properties: {
          addressPrefix: azureNetAppFilesSubnetAddressPrefix
        }
      }
    ]
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deployDefender: deployDefender
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    deployPolicy:  deployPolicy
    emailSecurityContact: emailSecurityContact
    environmentAbbreviation: environmentAbbreviation
    firewallResourceId: azureFirewallResourceId
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    identifier: identifier
    keyVaultDiagnosticLogs: keyVaultDiagnosticLogs
    keyVaultDiagnosticMetrics: keyVaultDiagnosticMetrics
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageSkuName: logStorageSkuName
    networkInterfaceDiagnosticsMetrics: networkInterfaceDiagnosticsMetrics
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs 
    networkSecurityGroupRules: networkSecurityGroupRules
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    networkWatcherResourceId: networkWatcherResourceId
    policy: policy
    subnetAddressPrefix: subnetAddressPrefix
    tags: tags
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics
    workloadName: workloadName
    workloadShortName: workloadShortName
  }
}

// Resource group
module rg '../../modules/resource-group.bicep' = {
  name: 'deploy-rg-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: tier3.outputs.mlzTags
    name: replace(tier3.outputs.namingConvention.resourceGroup, tier3.outputs.tokens.service, 'netAppFiles')
    tags: tags
  }
}

// Azure NetApp Files
module netAppFiles 'modules/azureNetAppFiles.bicep' = {
  name: 'deploy-netapp-files-${deploymentNameSuffix}'
  params: {
    delegatedSubnetResourceId: filter(tier3.outputs.subnets, subnet => contains(subnet.name, 'AzureNetAppFiles'))[0].id
    deploymentNameSuffix: deploymentNameSuffix
    dnsServers: join(tier3.outputs.dnsServers, ',')
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    fileShareName: fileShareName
    location: location
    mlzTags: tier3.outputs.mlzTags
    netAppAccountName: tier3.outputs.namingConvention.netAppAccount
    netAppCapacityPoolName: tier3.outputs.namingConvention.netAppAccountCapacityPool
    organizationalUnitPath: organizationalUnitPath
    resourceGroupName: rg.outputs.name
    smbServerName: tier3.outputs.namingConvention.netAppAccountSmbServer
    sku: sku
    tags: tags
  }
}
