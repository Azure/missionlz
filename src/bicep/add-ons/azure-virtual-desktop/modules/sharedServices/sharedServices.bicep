targetScope = 'subscription'

param applicationGroupResourceId string
param avdPrivateDnsZoneResourceId string
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param deploymentUserAssignedIdentityPrincipalId string
param enableAvdInsights bool
param existingFeedWorkspaceResourceId string
param existingWorkspace bool
param hostPoolName string
param locationControlPlane string
param locationVirtualMachines string
param logAnalyticsWorkspaceResourceId string
param managementVirtualMachineName string
param mlzTags object
param resourceGroupManagement string
param sharedServicesSubnetResourceId string
param tags object
param workspaceFeedDiagnoticSettingName string
param workspaceFeedName string
param workspaceFeedNetworkInterfaceName string
param workspaceFeedPrivateEndpointName string
param workspaceFeedResourceGroupName string
param workspaceFriendlyName string
param workspaceGlobalName string
param workspaceGlobalNetworkInterfaceName string
param workspaceGlobalPrivateDnsZoneResourceId string
param workspaceGlobalPrivateEndpointName string
param workspaceGlobalResourceGroupName string
param workspacePublicNetworkAccess string

// Resource rgoup for the global workspace
module rg_workspace_global '../../../../modules/resource-group.bicep' = {
  name: 'deploy-rg-vdws-global-${deploymentNameSuffix}'
  scope: subscription(split(sharedServicesSubnetResourceId, '/')[2])
  params: {
    location: locationControlPlane
    mlzTags: mlzTags
    name: workspaceGlobalResourceGroupName
    tags: {}
  }
}

module workspace_global 'workspaceGlobal.bicep' = {
  name: 'deploy-vdws-global-${deploymentNameSuffix}'
  scope: resourceGroup(workspaceGlobalResourceGroupName)
  params: {
    globalWorkspacePrivateDnsZoneResourceId: workspaceGlobalPrivateDnsZoneResourceId
    location: locationControlPlane
    subnetResourceId: sharedServicesSubnetResourceId
    tags: mlzTags
    workspaceGlobalName: workspaceGlobalName
    workspaceGlobalNetworkInterfaceName: workspaceGlobalNetworkInterfaceName
    workspaceGlobalPrivateEndpointName: workspaceGlobalPrivateEndpointName
  }
  dependsOn: [
    rg_workspace_global
  ]
}

// Resource group for the feed workspace
module rg_workspace_feed '../../../../modules/resource-group.bicep' = if (!existingWorkspace) {
  name: 'deploy-rg-vdws-feed-${deploymentNameSuffix}'
  scope: subscription(split(sharedServicesSubnetResourceId, '/')[2])
  params: {
    location: locationControlPlane
    mlzTags: mlzTags
    name: workspaceFeedResourceGroupName
    tags: {}
  }
}

module roleAssignment '../common/roleAssignments/resourceGroup.bicep' = {
  name: 'assign-role-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(workspaceFeedResourceGroupName)
  params: {
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '21efdde3-836f-432b-bf3d-3e8e734d4b2b' // Desktop Virtualization Workspace Contributor (Purpose: update the app group references on an existing feed workspace)
  }
  dependsOn: [
    rg_workspace_feed
  ]
}

module workspace_feed 'workspaceFeed.bicep' = {
  name: 'deploy-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(workspaceGlobalResourceGroupName)
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
    workspaceFeedDiagnoticSettingName: workspaceFeedDiagnoticSettingName
    workspaceFeedName: workspaceFeedName
    workspaceFeedNetworkInterfaceName: workspaceFeedNetworkInterfaceName
    workspaceFeedPrivateEndpointName: workspaceFeedPrivateEndpointName
    workspaceFriendlyName: workspaceFriendlyName
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
  dependsOn: [
    roleAssignment
  ]
}
