/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
targetScope = 'resourceGroup'
/*

  PARAMETERS

  Here are all the parameters a user can override.

  These are the required parameters that Mission LZ Tier 3 workload does not provide a default for:
    - resourcePrefix

*/

// REQUIRED PARAMETERS

@minLength(3)
@maxLength(10)
@description('A prefix, 3 to 10 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".')
param resourcePrefix string = 'zta'

@minLength(3)
@maxLength(6)
@description('A suffix, 3 to 6 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".')
param resourceSuffix string = 'mlz'

param deployDefender bool
param deploymentNameSuffix string = utcNow()
param deployPolicy bool
param emailSecurityContact string
param existingResourceGroup bool
param firewallPrivateIPAddress string
param hubResourceGroupName string
param hubSubscriptionId string
param hubVirtualNetworkName string
param hubVirtualNetworkResourceId string
param location string
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceResourceId string
param logStorageSkuName string = 'Standard_GRS'
param networkSecurityGroupDiagnosticsMetrics array = []
param networkSecurityGroupRules array = []
param policy string
param resourceGroupName string
param subnetAddressPrefix string
param subnetServiceEndpoints array = []
param tags object = {}
param virtualNetworkAddressPrefix string
param virtualNetworkDiagnosticsLogs array = []
param virtualNetworkDiagnosticsMetrics array = []
param vNetDnsServers array = [firewallPrivateIPAddress]
param workloadLogStorageAccountNameParameter string = 'null'
param workloadName string = 'zta'
param workloadSubscriptionId string
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


/*

  NAMING CONVENTION

  Here we define a naming conventions for resources.

  First, we take `resourcePrefix` and `resourceSuffix` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.

*/

var resourceToken = 'resource_token'
var nameToken = 'name_token'
var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${nameToken}-${toLower(resourceSuffix)}'
var virtualNetworkNamingConvention = replace(namingConvention, resourceToken, 'vnet')
var networkSecurityGroupNamingConvention = replace(namingConvention, resourceToken, 'nsg')
var storageAccountNamingConvention = toLower('${resourcePrefix}st${nameToken}unique_storage_token')
var subnetNamingConvention = replace(namingConvention, resourceToken, 'snet')
var workloadLogStorageAccountNameTemplate = replace(storageAccountNamingConvention, nameToken, toLower(workloadName))
var workloadLogStorageAccountUniqueName = replace(workloadLogStorageAccountNameTemplate, 'unique_storage_token', uniqueString(resourcePrefix, resourceSuffix, workloadSubscriptionId))
var workloadLogStorageAccountNameVariable = take(workloadLogStorageAccountUniqueName, 23)
var workloadVirtualNetworkName = replace(virtualNetworkNamingConvention, nameToken, workloadName)
var workloadNetworkSecurityGroupName = replace(networkSecurityGroupNamingConvention, nameToken, workloadName)
var workloadSubnetName = replace(subnetNamingConvention, nameToken, workloadName)
var logAnalyticsWorkspaceResourceId_split = split(logAnalyticsWorkspaceResourceId, '/')
var workloadLogStorageAccountName = 'null' != workloadLogStorageAccountNameParameter ? workloadLogStorageAccountNameParameter : workloadLogStorageAccountNameVariable
var defaultTags = {
  DeploymentType: 'MissionLandingZoneARM'
}
var calculatedTags = union(tags, defaultTags)


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' existing =  {
  name: resourceGroupName
  scope: subscription(workloadSubscriptionId)
}

module spokeNetwork '../../../core/spoke-network.bicep' = {
  name: 'spokeNetwork'
  scope: az.resourceGroup(workloadSubscriptionId, (existingResourceGroup ? rg.name : resourceGroupName))
  params: {
    tags: calculatedTags
    location:location
    logStorageAccountName: workloadLogStorageAccountName
    logStorageSkuName: logStorageSkuName
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    firewallPrivateIPAddress: firewallPrivateIPAddress
    virtualNetworkName: workloadVirtualNetworkName
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    vNetDnsServers: vNetDnsServers
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics
    networkSecurityGroupName: workloadNetworkSecurityGroupName
    networkSecurityGroupRules: networkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: networkSecurityGroupDiagnosticsMetrics
    subnetName: workloadSubnetName
    subnetAddressPrefix: subnetAddressPrefix
    subnetServiceEndpoints: subnetServiceEndpoints
    subnetPrivateEndpointNetworkPolicies: 'Disabled'
    subnetPrivateLinkServiceNetworkPolicies: 'Disabled'
  }
}

module workloadVirtualNetworkPeerings './spoke-network-peering.bicep' = {
  name: take('${workloadName}-to-hub-vnet-peering', 64)
  scope: subscription(workloadSubscriptionId)
  params: {
    spokeName: workloadName
    spokeResourceGroupName: (existingResourceGroup ? rg.name : resourceGroupName)
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName
    hubVirtualNetworkName: hubVirtualNetworkName
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
  }
}

module hubToWorkloadVirtualNetworkPeering './hub-network-peering.bicep' = {
  scope: az.resourceGroup(workloadSubscriptionId, (existingResourceGroup ? rg.name : resourceGroupName))
  name: take('hub-to-${workloadName}-vnet-peering', 64)
  params: {
    hubVirtualNetworkName: hubVirtualNetworkName
    hubResourceGroupName: hubResourceGroupName
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName
    spokeVirtualNetworkResourceId: spokeNetwork.outputs.virtualNetworkResourceId
  }
}

module workloadSubscriptionActivityLogging '../../../modules/central-logging.bicep' = if (workloadSubscriptionId != hubSubscriptionId) {
  name: 'activity-logs-${spokeNetwork.name}-${resourceSuffix}'
  scope: subscription(workloadSubscriptionId)
  params: {
    diagnosticSettingName: 'log-${spokeNetwork.name}-sub-activity-to-${logAnalyticsWorkspaceName}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
  }
  dependsOn: [
    spokeNetwork
  ]
}

module workloadPolicyAssignment '../../../modules/policy-assignment.bicep' = if (deployPolicy) {
  name: 'assign-policy-${workloadName}-${deploymentNameSuffix}'
  scope:  az.resourceGroup(workloadSubscriptionId, (existingResourceGroup ? rg.name : resourceGroupName))
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceResourceId_split[8]
    logAnalyticsWorkspaceResourceGroupName: logAnalyticsWorkspaceResourceId_split[4]
    location: location
    operationsSubscriptionId: logAnalyticsWorkspaceResourceId_split[2]
   }
  }

module spokeDefender '../../../modules/defender.bicep' = if (deployDefender) {
  name: 'set-${workloadName}-sub-defender'
  scope: subscription(workloadSubscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    emailSecurityContact: emailSecurityContact
  }
}

output rg string = (existingResourceGroup ? rg.name : resourceGroupName)
output location string = location
output virtualNetworkName string = spokeNetwork.outputs.virtualNetworkName
output virtualNetworkAddressPrefix string = spokeNetwork.outputs.virtualNetworkAddressPrefix
output virtualNetworkResourceId string = spokeNetwork.outputs.virtualNetworkResourceId
output subnetName string = spokeNetwork.outputs.subnetName
output subnetAddressPrefix string = spokeNetwork.outputs.subnetAddressPrefix
output subnetResourceId string = spokeNetwork.outputs.subnetResourceId
output networkSecurityGroupName string = spokeNetwork.outputs.networkSecurityGroupName
output networkSecurityGroupResourceId string = spokeNetwork.outputs.networkSecurityGroupResourceId
