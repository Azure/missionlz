targetScope = 'subscription'

param activeDirectorySolution string
param artifactsUri string
param avdPrivateDnsZoneResourceId string
param customRdpProperty string
param deploymentUserAssignedIdentityClientId string
param desktopApplicationGroupName string
param desktopFriendlyName string
param existingFeedWorkspace bool
param hostPoolName string
param hostPoolPublicNetworkAccess string
param hostPoolType string
param locationControlPlane string
param locationVirtualMachines string
param logAnalyticsWorkspaceResourceId string
param managementVirtualMachineName string
param maxSessionLimit int
param monitoring bool
param resourceGroupControlPlane string
param resourceGroupFeedWorkspace string
param resourceGroupManagement string
param roleDefinitions object
param securityPrincipalObjectIds array
param subnetResourceId string
param tags object
param timestamp string
param validationEnvironment bool
param vmTemplate string
param workspaceFriendlyName string
param workspaceNamePrefix string
param workspacePublicNetworkAccess string

module hostPool 'hostPool.bicep' = {
  name: 'HostPool_${timestamp}'
  scope: resourceGroup(resourceGroupControlPlane)
  params: {
    activeDirectorySolution: activeDirectorySolution
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    customRdpProperty: customRdpProperty
    hostPoolName: hostPoolName
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    location: locationControlPlane
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    maxSessionLimit: maxSessionLimit
    monitoring: monitoring
    subnetResourceId: subnetResourceId
    tags: tags
    validationEnvironment: validationEnvironment
    vmTemplate: vmTemplate
  }
}

module applicationGroup 'applicationGroup.bicep' = {
  name: 'ApplicationGroup_${timestamp}'
  scope: resourceGroup(resourceGroupControlPlane)
  params: {
    artifactsUri: artifactsUri
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    desktopApplicationGroupName: desktopApplicationGroupName
    hostPoolResourceId: hostPool.outputs.ResourceId
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    resourceGroupManagement: resourceGroupManagement
    roleDefinitions: roleDefinitions
    securityPrincipalObjectIds: securityPrincipalObjectIds
    desktopFriendlyName: desktopFriendlyName
    tags: tags
    timestamp: timestamp
    virtualMachineName: managementVirtualMachineName
  }
}

module workspace 'workspace.bicep' = {
  name: 'WorkspaceFeed_${timestamp}'
  scope: resourceGroup(resourceGroupFeedWorkspace)
  params: {
    applicationGroupReferences: applicationGroup.outputs.applicationGroupReference
    artifactsUri: artifactsUri
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    existing: existingFeedWorkspace
    friendlyName: workspaceFriendlyName
    hostPoolName: hostPoolName
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    monitoring: monitoring
    resourceGroupManagement: resourceGroupManagement
    subnetResourceId: subnetResourceId
    tags: tags
    timestamp: timestamp
    virtualMachineName: managementVirtualMachineName
    workspaceNamePrefix: workspaceNamePrefix
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}
