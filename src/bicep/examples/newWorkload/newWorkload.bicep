targetScope = 'subscription'

param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))

@minLength(3)
@maxLength(24)
param workloadName string

param resourceGroupName string = '${workloadName}-rg'
param location string = deployment().location

param hubSubscriptionId string = mlzDeploymentVariables.hub.Value.subscriptionId
param hubResourceGroupName string = mlzDeploymentVariables.hub.Value.resourceGroupName
param hubVirtualNetworkName string = mlzDeploymentVariables.hub.Value.virtualNetworkName
param hubVirtualNetworkResourceId string = mlzDeploymentVariables.hub.Value.virtualNetworkResourceId
param logAnalyticsWorkspaceResourceId string = mlzDeploymentVariables.logAnalyticsWorkspaceResourceId.Value
param firewallPrivateIPAddress string = mlzDeploymentVariables.firewallPrivateIPAddress.Value

param virtualNetworkName string = '${workloadName}-vnet'

@description('The address prefix for the network spoke vnet.')
param virtualNetworkAddressPrefix string = '10.0.125.0/26'
param virtualNetworkDiagnosticsLogs array = []
param virtualNetworkDiagnosticsMetrics array = []

param networkSecurityGroupName string = '${workloadName}-nsg'
param networkSecurityGroupRules array = []
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
param networkSecurityGroupDiagnosticsMetrics array = []

param subnetName string = '${workloadName}-subnet'

@description('The subnet address prefix for the network spoke vnet.')
param subnetAddressPrefix string = '10.0.125.0/27'
param subnetServiceEndpoints array = []

param logStorageAccountName string = toLower(take('logs${uniqueString(subscription().subscriptionId, workloadName)}', 24))
param logStorageSkuName string = 'Standard_GRS'

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {}
var defaultTags = {
  'DeploymentType': 'MissionLandingZoneARM'
}
var calculatedTags = union(tags, defaultTags)

module resourceGroup '../../modules/resourceGroup.bicep' = {
  name: resourceGroupName
  params: {
    name: resourceGroupName
    location: location
    tags: calculatedTags
  }
}

module spokeNetwork '../../modules/spokeNetwork.bicep' = {
  name: 'spokeNetwork'
  scope: az.resourceGroup(resourceGroup.name)
  params: {
    tags: calculatedTags

    logStorageAccountName: logStorageAccountName
    logStorageSkuName: logStorageSkuName

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId

    firewallPrivateIPAddress: firewallPrivateIPAddress

    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: networkSecurityGroupName
    networkSecurityGroupRules: networkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: networkSecurityGroupDiagnosticsMetrics

    subnetName: subnetName
    subnetAddressPrefix: subnetAddressPrefix
    subnetServiceEndpoints: subnetServiceEndpoints
  }
}

module workloadVirtualNetworkPeerings '../../modules/spokeNetworkPeering.bicep' = {
  name: take('${workloadName}--VNetPeerings', 64)
  params: {
    spokeName: workloadName
    spokeResourceGroupName: resourceGroup.name
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName

    hubVirtualNetworkName: hubVirtualNetworkName
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
  }
}

module hubToWorkloadVirtualNetworkPeering './modules/hubNetworkPeering.bicep' = {
  scope: subscription(hubSubscriptionId)
  name: 'hubToWorkloadVirtualNetworkPeering'
  params: {
    hubResourceGroupName: hubResourceGroupName
    hubVirtualNetworkName: hubVirtualNetworkName
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName
    spokeVirtualNetworkResourceId: spokeNetwork.outputs.virtualNetworkResourceId
  }
}

output resourceGroupName string = resourceGroup.outputs.name
output location string = resourceGroup.outputs.location
output tags object = resourceGroup.outputs.tags
output virtualNetworkName string = spokeNetwork.outputs.virtualNetworkName
output virtualNetworkAddressPrefix string = spokeNetwork.outputs.virtualNetworkAddressPrefix
output virtualNetworkResourceId string = spokeNetwork.outputs.virtualNetworkResourceId
output subnetName string = spokeNetwork.outputs.subnetName
output subnetAddressPrefix string = spokeNetwork.outputs.subnetAddressPrefix
output subnetResourceId string = spokeNetwork.outputs.subnetResourceId
output networkSecurityGroupName string = spokeNetwork.outputs.networkSecurityGroupName
output networkSecurityGroupResourceId string = spokeNetwork.outputs.networkSecurityGroupResourceId
