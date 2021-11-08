targetScope = 'subscription'

@minLength(3)
@maxLength(24)
param workloadName string

param resourceGroupName string = '${workloadName}-rg'
param location string = deployment().location
param tags object = {
  'resourceIdentifier': resourceIdentifier
}

param hubSubscriptionId string
param hubResourceGroupName string
param hubVirtualNetworkName string
param hubVirtualNetworkResourceId string
param logAnalyticsWorkspaceResourceId string
param firewallPrivateIPAddress string

param virtualNetworkName string = '${workloadName}-vnet'
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
param subnetAddressPrefix string = '10.0.125.0/27'
param subnetServiceEndpoints array = []

param logStorageAccountName string = toLower(take('logs${uniqueString(workloadName)}', 24))
param logStorageSkuName string = 'Standard_GRS'

param resourceIdentifier string = '${workloadName}${uniqueString(workloadName)}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module spokeNetwork '../../modules/spokeNetwork.bicep' = {
  name: 'spokeNetwork'
  scope: az.resourceGroup(resourceGroup.name)
  params: {
    tags: tags

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
  name: '${resourceIdentifier}-${workloadName}VirtualNetworkPeerings'
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

output virtualNetworkName string = spokeNetwork.outputs.virtualNetworkName
output virtualNetworkResourceId string = spokeNetwork.outputs.virtualNetworkResourceId
output subnetName string = spokeNetwork.outputs.subnetName
output subnetAddressPrefix string = spokeNetwork.outputs.subnetAddressPrefix
output subnetResourceId string = spokeNetwork.outputs.subnetResourceId
output networkSecurityGroupName string = spokeNetwork.outputs.networkSecurityGroupName
output networkSecurityGroupResourceId string = spokeNetwork.outputs.networkSecurityGroupResourceId
