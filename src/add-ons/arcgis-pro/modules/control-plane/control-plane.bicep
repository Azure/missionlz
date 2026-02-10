targetScope = 'subscription'

param activeDirectorySolution string
param avdPrivateDnsZoneResourceId string
param customImageId string
param customRdpProperty string
param delimiter string
param deploymentNameSuffix string
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
param logAnalyticsWorkspaceResourceId string
param maxSessionLimit int
param mlzTags object
param namingConvention object
param resourceGroupName string
param securityPrincipalObjectId string
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
  scope: resourceGroup(resourceGroupName)
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
  scope: resourceGroup(resourceGroupName)
  params: {
    desktopApplicationGroupName: replace(namingConvention.applicationGroup, '${delimiter}${tokens.purpose}', '')
    hostPoolResourceId: hostPool.outputs.resourceId
    locationControlPlane: locationControlPlane
    mlzTags: mlzTags
    securityPrincipalObjectId: securityPrincipalObjectId
    tags: tags
  }
}

// Deploys the resources to create and configure the feed workspace
module workspace_feed 'workspace-feed.bicep' = {
  name: 'deploy-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    applicationGroupResourceId: applicationGroup.outputs.resourceId
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    enableAvdInsights: enableAvdInsights
    existingFeedWorkspaceResourceId: existingFeedWorkspaceResourceId
    locationControlPlane: locationControlPlane
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    mlzTags: mlzTags
    subnetResourceId: subnetResourceId
    workspaceFeedDiagnoticSettingName: replace(namingConvention.workspaceDiagnosticSetting, tokens.purpose, 'feed')
    workspaceFeedName: replace(namingConvention.workspace, tokens.purpose, 'feed')
    workspaceFeedNetworkInterfaceName: replace(namingConvention.workspaceNetworkInterface, tokens.purpose, 'feed')
    workspaceFeedPrivateEndpointName: replace(namingConvention.workspacePrivateEndpoint, tokens.purpose, 'feed')
    workspaceFriendlyName: empty(workspaceFriendlyName) ? replace(namingConvention.workspace, '${delimiter}${tokens.purpose}', '') : '${workspaceFriendlyName} (${locationControlPlane})'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}

output applicationGroupResourceId string = applicationGroup.outputs.resourceId
output hostPoolName string = hostPool.outputs.name
output hostPoolResourceId string = hostPool.outputs.resourceId
