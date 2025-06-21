targetScope = 'subscription'

param activeDirectorySolution string
param avdPrivateDnsZoneResourceId string
param customImageId string
param customRdpProperty string
param delimiter string
// param deployFslogix bool
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
param managementSubnetResourceId string
param managementVirtualMachineName string
param maxSessionLimit int
param mlzTags object
param resourceGroupManagement string
param resourceGroupShared string
param securityPrincipalObjectIds array
param sharedNames object
param sharedSubnetReourceId string
param stampNames object
param tags object
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
    hostPoolDiagnosticSettingName: stampNames.hostPoolDiagnosticSetting
    hostPoolName: stampNames.hostPool
    hostPoolNetworkInterfaceName: stampNames.hostPoolNetworkInterface
    hostPoolPrivateEndpointName: stampNames.hostPoolPrivateEndpoint
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    imageType: imageType
    location: locationControlPlane
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    maxSessionLimit: maxSessionLimit
    mlzTags: mlzTags
    sessionHostNamePrefix: stampNames.virtualMachine
    subnetResourceId: managementSubnetResourceId
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
    desktopApplicationGroupName: stampNames.applicationGroup
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
    subnetResourceId: sharedSubnetReourceId
    tags: tags
    virtualMachineName: managementVirtualMachineName
    workspaceFeedDiagnoticSettingName: '${sharedNames.workspaceDiagnosticSetting}${delimiter}feed'
    workspaceFeedName: '${sharedNames.workspace}${delimiter}feed'
    workspaceFeedNetworkInterfaceName: '${sharedNames.workspaceNetworkInterface}${delimiter}feed'
    workspaceFeedPrivateEndpointName: '${sharedNames.workspacePrivateEndpoint}${delimiter}feed'
    workspaceFriendlyName: empty(workspaceFriendlyName) ? sharedNames.workspace : '${workspaceFriendlyName} (${locationControlPlane})'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}

output applicationGroupResourceId string = applicationGroup.outputs.resourceId
output hostPoolName string = hostPool.outputs.name
output hostPoolResourceId string = hostPool.outputs.resourceId
