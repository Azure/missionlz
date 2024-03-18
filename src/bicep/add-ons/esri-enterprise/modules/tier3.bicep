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
param resourcePrefix string = 'esri'

@minLength(3)
@maxLength(6)
@description('A suffix, 3 to 6 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".')
param resourceSuffix string = 'mlz'

param deployDefender bool
param deploymentNameSuffix string = utcNow()
// param deployPolicy bool
param emailSecurityContact string
param firewallPrivateIPAddress string
param hubResourceGroupName string
param hubSubscriptionId string
param hubVirtualNetworkName string
param hubVirtualNetworkResourceId string
param location string
// param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceResourceId string
// param networkSecurityGroupRules array = []
// param policy string
param resourceGroupName string
// param subnetAddressPrefix string
param tags object = {}
param virtualNetworkAddressPrefix string
param vNetDnsServers array = [firewallPrivateIPAddress]
param workloadName string = 'esri'
param workloadSubscriptionId string
param applicationGatewayName string
param applicationGatewaySubnetAddressPrefix string
param defaultSubnetAddressPrefix string
param privatelink_keyvaultDns_name string
param hubVirtualNetworkId string
param externalDnsHostname string
param applicationGatewayPrivateIpAddress string
param joinWindowsDomain bool

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
var routeTableNamingConvention = replace(replace(namingConvention, nameToken, 'esri'), resourceToken, 'rt')
var workloadVirtualNetworkName = replace(virtualNetworkNamingConvention, nameToken, workloadName)
// var logAnalyticsWorkspaceResourceId_split = split(logAnalyticsWorkspaceResourceId, '/')
var defaultTags = {
  DeploymentType: 'MissionLandingZoneARM'
}
var calculatedTags = union(tags, defaultTags)


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' existing =  {
  name: resourceGroupName
  scope: subscription(workloadSubscriptionId)
}

module spokeNetwork 'virtualNetwork.bicep' = {
  name: 'deploy-spokeNetwork--${deploymentNameSuffix}'
  scope: az.resourceGroup(workloadSubscriptionId, rg.name)
  params: {
    applicationGatewayName: applicationGatewayName
    applicationGatewaySubnetAddressPrefix: applicationGatewaySubnetAddressPrefix
    defaultSubnetAddressPrefix: defaultSubnetAddressPrefix
    location:location
    resourceGroup: rg.name
    routeTableName: routeTableNamingConvention
    routeTableRouteNextHopIpAddress: firewallPrivateIPAddress
    tags: calculatedTags
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkName: workloadVirtualNetworkName
    vNetDnsServers: vNetDnsServers
  }
}

module link './virtualNetworkLink.bicep' = {
  name: 'deploy-virtualNetworkLink--${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    privatelink_keyvaultDns_name: privatelink_keyvaultDns_name
    workloadVirtualNetworkName: spokeNetwork.outputs.vNetName
    virtualNetworkId: spokeNetwork.outputs.vNetid
  }
  dependsOn: [
  ]
}

module workloadVirtualNetworkPeerings './spoke-network-peering.bicep' = {
  name: take('${workloadName}-to-hub-vnet-peering', 64)
  scope: subscription(workloadSubscriptionId)
  params: {
    spokeName: workloadName
    spokeResourceGroupName: rg.name
    spokeVirtualNetworkName: spokeNetwork.outputs.vNetName
    hubVirtualNetworkName: hubVirtualNetworkName
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
  }
  dependsOn: [
    spokeNetwork
    link
  ]
}

module hubToWorkloadVirtualNetworkPeering './hub-network-peering.bicep' = {
  scope: az.resourceGroup(workloadSubscriptionId, rg.name)
  name: take('hub-to-${workloadName}-vnet-peering', 64)
  params: {
    hubVirtualNetworkName: hubVirtualNetworkName
    hubResourceGroupName: hubResourceGroupName
    spokeVirtualNetworkName: spokeNetwork.outputs.vNetName
    spokeVirtualNetworkResourceId: spokeNetwork.outputs.vNetid
  }
  dependsOn:[
    spokeNetwork
    link
    workloadVirtualNetworkPeerings
  ]
}

// module workloadSubscriptionActivityLogging '../../tier3/modules/diagnostics.bicep' = if (workloadSubscriptionId != hubSubscriptionId) {
//   name: 'activity-logs-${spokeNetwork.name}-${resourceSuffix}'
//   scope: subscription(workloadSubscriptionId)
//   params: {
//     diagnosticSettingName: 'log-${spokeNetwork.name}-sub-activity-to-${logAnalyticsWorkspaceName}'
//     logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
//   }
//   dependsOn: [
//     spokeNetwork
//   ]
// }

// module workloadPolicyAssignment '../../../modules/policy-assignment.bicep' = if (deployPolicy) {
//   name: 'assign-policy-${workloadName}-${deploymentNameSuffix}'
//   scope:  az.resourceGroup(workloadSubscriptionId, rg.name)
//   params: {
//     builtInAssignment: policy
//     logAnalyticsWorkspaceName: logAnalyticsWorkspaceResourceId_split[8]
//     logAnalyticsWorkspaceResourceGroupName: logAnalyticsWorkspaceResourceId_split[4]
//     location: location
//     operationsSubscriptionId: logAnalyticsWorkspaceResourceId_split[2]
//    }
//   }

module spokeDefender '../../../modules/defenderForCloud.bicep' = if (deployDefender) {
  name: 'set-${workloadName}-sub-defender'
  scope: subscription(workloadSubscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    emailSecurityContact: emailSecurityContact
  }
}

module privateDnsZone 'privateDnsZone.bicep' = if (joinWindowsDomain == false) {
  name: 'deploy-privatednszone-${deploymentNameSuffix}'
  scope: resourceGroup(workloadSubscriptionId, resourceGroupName)
  params: {
    externalDnsHostname: externalDnsHostname
    applicationGatewayPrivateIPAddress: applicationGatewayPrivateIpAddress
    virtualNetworkId: spokeNetwork.outputs.vNetid
    hubVirtualNetworkId: hubVirtualNetworkId
    resourcePrefix: resourcePrefix
  }
  dependsOn: [
    spokeNetwork
    hubToWorkloadVirtualNetworkPeering
    workloadVirtualNetworkPeerings
  ]
}

output rg string = rg.name
output location string = location
output virtualNetworkName string = spokeNetwork.outputs.vNetName
output virtualNetworkAddressPrefix string = spokeNetwork.outputs.vNetAddressPrefix
output virtualNetworkResourceId string = spokeNetwork.outputs.vNetid
output subnetName string = spokeNetwork.outputs.subnetName
output subnetAddressPrefix string = spokeNetwork.outputs.subnetAddressPrefix
output subnetResourceId string = spokeNetwork.outputs.subnetResourceId
