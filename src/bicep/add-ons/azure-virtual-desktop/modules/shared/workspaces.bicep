targetScope = 'subscription'

param applicationGroupResourceId string
param avdPrivateDnsZoneResourceId string
param delimiter string
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param enableAvdInsights bool
param existingFeedWorkspaceResourceId string
param hostPoolName string
param identifier string
param identifierHub string
param locationControlPlane string
param locationHub string
param locationVirtualMachines string
param logAnalyticsWorkspaceResourceId string
param managementVirtualMachineName string
param mlzTags object
param names object
param resourceGroupManagement string
param sharedServicesSubnetResourceId string
param tags object
param workspaceFriendlyName string
param workspaceGlobalPrivateDnsZoneResourceId string
param workspacePublicNetworkAccess string

var resourceGroupShared = '${names.resourceGroup}${delimiter}shared'
var resourceGroupWorkspaceGlobal = replace('${names.resourceGroup}${delimiter}workspace${delimiter}global', identifier, identifierHub)

// Resource group for the global workspace
module rg_workspace_global '../../../../modules/resource-group.bicep' = {
  name: 'deploy-rg-vdws-global-${deploymentNameSuffix}'
  scope: subscription(split(sharedServicesSubnetResourceId, '/')[2])
  params: {
    location: locationControlPlane
    mlzTags: mlzTags
    name: resourceGroupWorkspaceGlobal
    tags: {}
  }
}

// Global workspace
module workspace_global 'workspace-global.bicep' = {
  name: 'deploy-vdws-global-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupWorkspaceGlobal)
  params: {
    globalWorkspacePrivateDnsZoneResourceId: workspaceGlobalPrivateDnsZoneResourceId
    location: locationControlPlane
    subnetResourceId: sharedServicesSubnetResourceId
    tags: mlzTags
    workspaceGlobalName: replace('${names.workspace}${delimiter}global', identifier, identifierHub)
    workspaceGlobalNetworkInterfaceName: replace('${names.workspaceNetworkInterface}${delimiter}global', identifier, identifierHub)
    workspaceGlobalPrivateEndpointName: replace('${names.workspacePrivateEndpoint}${delimiter}global', identifier, identifierHub)
  }
  dependsOn: [
    rg_workspace_global
  ]
}

module workspace_feed 'workspace-feed.bicep' = {
  name: 'deploy-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupShared)
  params: {
    applicationGroupResourceId: applicationGroupResourceId
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    enableAvdInsights: enableAvdInsights
    existingFeedWorkspaceResourceId: existingFeedWorkspaceResourceId
    hostPoolName: hostPoolName
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    mlzTags: mlzTags
    resourceGroupManagement: resourceGroupManagement
    subnetResourceId: sharedServicesSubnetResourceId
    tags: tags
    virtualMachineName: managementVirtualMachineName
    workspaceFeedDiagnoticSettingName: '${names.workspaceDiagnosticSetting}${delimiter}feed'
    workspaceFeedName: '${names.workspace}${delimiter}feed'
    workspaceFeedNetworkInterfaceName: '${names.workspaceNetworkInterface}${delimiter}feed'
    workspaceFeedPrivateEndpointName: '${names.workspacePrivateEndpoint}${delimiter}feed'
    workspaceFriendlyName: empty(workspaceFriendlyName) ? names.workspace : '${workspaceFriendlyName} (${locationHub})'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}
