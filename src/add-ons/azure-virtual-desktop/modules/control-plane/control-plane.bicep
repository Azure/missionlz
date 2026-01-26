targetScope = 'subscription'

param activeDirectorySolution string
param avdPrivateDnsZoneResourceId string
param customImageId string
param customRdpProperty string
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param desktopFriendlyName string
param diskSku string
param domainName string
param enableAvdInsights bool
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
param resourceGroupManagement string
param resourceGroupShared string
param securityPrincipalObjectIds array
param tags object
param tiers array
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
var sharedTier = tiers[0]
var stampTier = tiers[1]

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
    hostPoolDiagnosticSettingName: replace(stampTier.namingConvention.hostPoolDiagnosticSetting, tokens.purpose, '')
    hostPoolName: replace(stampTier.namingConvention.hostPool, tokens.purpose, '')
    hostPoolNetworkInterfaceName: replace(stampTier.namingConvention.hostPoolNetworkInterface, tokens.purpose, '')
    hostPoolPrivateEndpointName: replace(stampTier.namingConvention.hostPoolPrivateEndpoint, tokens.purpose, '')
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    imageType: imageType
    location: locationControlPlane
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    maxSessionLimit: maxSessionLimit
    mlzTags: mlzTags
    sessionHostNamePrefix: replace(stampTier.namingConvention.virtualMachine, tokens.purpose, '')
    subnetResourceId: stampTier.subnets[0].id
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
    desktopApplicationGroupName: replace(stampTier.namingConvention.applicationGroup, tokens.purpose, '')
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
module workspace_feed '../shared/workspace-feed.bicep' = {
  name: 'deploy-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupShared)
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
    subnetResourceId: sharedTier.subnets[0].id
    tags: tags
    virtualMachineName: managementVirtualMachineName
    workspaceFeedDiagnoticSettingName: replace(sharedTier.namingConvention.workspaceDiagnosticSetting, tokens.purpose, 'feed')
    workspaceFeedName: replace(sharedTier.namingConvention.workspace, tokens.purpose, 'feed')
    workspaceFeedNetworkInterfaceName: replace(sharedTier.namingConvention.workspaceNetworkInterface, tokens.purpose, 'feed')
    workspaceFeedPrivateEndpointName: replace(sharedTier.namingConvention.workspacePrivateEndpoint, tokens.purpose, 'feed')
    workspaceFriendlyName: empty(workspaceFriendlyName) ? replace(sharedTier.namingConvention.workspace, tokens.purpose, '') : '${workspaceFriendlyName} (${locationControlPlane})'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}

output applicationGroupResourceId string = applicationGroup.outputs.resourceId
output hostPoolName string = hostPool.outputs.name
output hostPoolResourceId string = hostPool.outputs.resourceId
