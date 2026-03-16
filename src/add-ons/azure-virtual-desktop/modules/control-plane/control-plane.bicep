targetScope = 'subscription'

param activeDirectorySolution string
param avdPrivateDnsZoneResourceId string
param customImageId string
param customRdpProperty string
param delimiter string
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param deploymentUserAssignedIdentityPrincipalId string
param desktopFriendlyName string
param diskSku string
param domainName string
param enableAvdInsights bool
param existingApplicationGroupReferences array
param existingFeedWorkspaceResourceId string
param hostPoolPublicNetworkAccess string
param hostPoolType string
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersionResourceId string
param locationControlPlane string
param locationVirtualMachines string
param logAnalyticsWorkspaceResourceId string
param managementVirtualMachineName string
param maxSessionLimit int
param mlzTags object
param namingConvention object
param resourceGroupManagement string
param securityPrincipalObjectIds array
param stampIndex int
param subnetResourceId string
param tags object
param tokens object
param validationEnvironment bool
param virtualMachineSize string
param workspaceFriendlyName string
param workspacePublicNetworkAccess string

var galleryImageOffer = empty(imageVersionResourceId) ? '"${imageOffer}"' : 'null'
var galleryImagePublisher = empty(imageVersionResourceId) ? '"${imagePublisher}"' : 'null'
var galleryImageSku = empty(imageVersionResourceId) ? '"${imageSku}"' : 'null'
var galleryItemId = empty(imageVersionResourceId) ? '"${imagePublisher}.${imageOffer}${imageSku}"' : 'null'
var imageType = empty(imageVersionResourceId) ? '"Gallery"' : '"CustomImage"'

module hostPool 'host-pool.bicep' = {
  name: 'deploy-vdpool-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    activeDirectorySolution: activeDirectorySolution
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    customImageId: customImageId
    customRdpProperty: customRdpProperty
    diskSku: diskSku
    domainName: domainName
    enableAvdInsights: enableAvdInsights
    galleryImageOffer: galleryImageOffer
    galleryImagePublisher: galleryImagePublisher
    galleryImageSku: galleryImageSku
    galleryItemId: galleryItemId
    hostPoolDiagnosticSettingName: replace(namingConvention.hostPoolDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    hostPoolName: replace(namingConvention.hostPool, '${delimiter}${tokens.purpose}', '')
    hostPoolNetworkInterfaceName: replace(namingConvention.hostPoolNetworkInterface, '${delimiter}${tokens.purpose}', '')
    hostPoolPrivateEndpointName: replace(namingConvention.hostPoolPrivateEndpoint, '${delimiter}${tokens.purpose}', '')
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    imageType: imageType
    location: locationControlPlane
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    maxSessionLimit: maxSessionLimit
    mlzTags: mlzTags
    sessionHostNamePrefix: replace(namingConvention.virtualMachine, '${delimiter}${tokens.purpose}', '')
    subnetResourceId: subnetResourceId
    tags: tags
    validationEnvironment: validationEnvironment
    virtualMachineSize: virtualMachineSize
  }
}

module applicationGroup 'application-group.bicep' = {
  name: 'deploy-vdag-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    desktopApplicationGroupName: replace(namingConvention.applicationGroup, '${delimiter}${tokens.purpose}', '')
    hostPoolResourceId: hostPool.outputs.resourceId
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    mlzTags: mlzTags
    securityPrincipalObjectIds: securityPrincipalObjectIds
    desktopFriendlyName: desktopFriendlyName
    tags: tags
    virtualMachineName: managementVirtualMachineName
  }
}

// Deploys the resources to create and configure the feed workspace
module workspace_feed 'workspace-feed.bicep' = {
  name: 'deploy-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    applicationGroupResourceId: applicationGroup.outputs.resourceId
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    enableAvdInsights: enableAvdInsights
    existingFeedWorkspaceResourceId: existingFeedWorkspaceResourceId
    hostPoolResourceId: hostPool.outputs.resourceId
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    mlzTags: mlzTags
    resourceGroupManagement: resourceGroupManagement
    subnetResourceId: subnetResourceId
    tags: tags
    virtualMachineName: managementVirtualMachineName
    workspaceFeedDiagnoticSettingName: replace(replace(namingConvention.workspaceDiagnosticSetting, tokens.purpose, 'feed'), '${delimiter}${stampIndex}', '')
    workspaceFeedName: replace(replace(namingConvention.workspace, tokens.purpose, 'feed'), '${delimiter}${stampIndex}', '')
    workspaceFeedNetworkInterfaceName: replace(replace(namingConvention.workspaceNetworkInterface, tokens.purpose, 'feed'), '${delimiter}${stampIndex}', '')
    workspaceFeedPrivateEndpointName: replace(replace(namingConvention.workspacePrivateEndpoint, tokens.purpose, 'feed'), '${delimiter}${stampIndex}', '')
    workspaceFriendlyName: empty(workspaceFriendlyName) ? replace(replace(namingConvention.workspace, '${delimiter}${tokens.purpose}', ''), '${delimiter}${stampIndex}', '') : '${workspaceFriendlyName} (${locationControlPlane})'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}

// Role assignments needed to update the application groups on the existing feed workspace
module roleAssignments_appGroupReferences '../common/role-assignments/resource-group.bicep' = [for (appGroup, i) in existingApplicationGroupReferences: if (!empty(existingFeedWorkspaceResourceId)) {
  name: 'assign-role-vdws-feed-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(split(appGroup, '/')[2], split(appGroup, '/')[4])
  params: {
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '86240b0e-9422-4c43-887b-b61143f32ba8' // Desktop Virtualization Application Group Contributor (Purpose: update the app group references on an existing feed workspace)
  }
}]

module roleAssignment '../common/role-assignments/resource-group.bicep' = if (!empty(existingFeedWorkspaceResourceId)) {
  name: 'assign-role-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '21efdde3-836f-432b-bf3d-3e8e734d4b2b' // Desktop Virtualization Workspace Contributor (Purpose: update the app group references on an existing feed workspace)
  }
}

output applicationGroupResourceId string = applicationGroup.outputs.resourceId
output hostPoolName string = hostPool.outputs.name
output hostPoolResourceId string = hostPool.outputs.resourceId
