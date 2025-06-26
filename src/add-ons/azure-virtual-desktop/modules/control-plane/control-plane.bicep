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
param resourceGroupManagement string
param resourceGroupShared string
param securityPrincipalObjectIds array
param tags object
param tiers array
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
    hostPoolDiagnosticSettingName: stampTier.namingConvention.hostPoolDiagnosticSetting
    hostPoolName: stampTier.namingConvention.hostPool
    hostPoolNetworkInterfaceName: stampTier.namingConvention.hostPoolNetworkInterface
    hostPoolPrivateEndpointName: stampTier.namingConvention.hostPoolPrivateEndpoint
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    imageType: imageType
    location: locationControlPlane
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    maxSessionLimit: maxSessionLimit
    mlzTags: stampTier.mlzTags
    sessionHostNamePrefix: stampTier.namingConvention.virtualMachine
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
    desktopApplicationGroupName: stampTier.namingConvention.applicationGroup
    hostPoolResourceId: hostPool.outputs.resourceId
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    mlzTags: stampTier.mlzTags
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
    mlzTags: sharedTier.mlzTags
    resourceGroupManagement: resourceGroupManagement
    subnetResourceId: sharedTier.subnets[0].id
    tags: tags
    virtualMachineName: managementVirtualMachineName
    workspaceFeedDiagnoticSettingName: '${sharedTier.namingConvention.workspaceDiagnosticSetting}${sharedTier.delimiter}feed'
    workspaceFeedName: '${sharedTier.namingConvention.workspace}${sharedTier.delimiter}feed'
    workspaceFeedNetworkInterfaceName: '${sharedTier.namingConvention.workspaceNetworkInterface}${sharedTier.delimiter}feed'
    workspaceFeedPrivateEndpointName: '${sharedTier.namingConvention.workspacePrivateEndpoint}${sharedTier.delimiter}feed'
    workspaceFriendlyName: empty(workspaceFriendlyName) ? sharedTier.namingConvention.workspace : '${workspaceFriendlyName} (${locationControlPlane})'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}

output applicationGroupResourceId string = applicationGroup.outputs.resourceId
output hostPoolName string = hostPool.outputs.name
output hostPoolResourceId string = hostPool.outputs.resourceId
