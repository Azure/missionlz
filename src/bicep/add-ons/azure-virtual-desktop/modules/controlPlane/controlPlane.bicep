targetScope = 'subscription'

param activeDirectorySolution string
param avdPrivateDnsZoneResourceId string
param customImageId string
param customRdpProperty string
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param deploymentUserAssignedIdentityPrincipalId string
param desktopFriendlyName string
param diskSku string
param domainName string
param enableAvdInsights bool
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
param resourceGroupControlPlane string
param resourceGroupManagement string
param roleDefinitions object
param securityPrincipalObjectIds array
param serviceToken string
param sessionHostNamePrefix string
param subnetResourceId string
param tags object
param validationEnvironment bool
param virtualMachineSize string

var galleryImageOffer = empty(imageVersionResourceId) ? '"${imageOffer}"' : 'null'
var galleryImagePublisher = empty(imageVersionResourceId) ? '"${imagePublisher}"' : 'null'
var galleryImageSku = empty(imageVersionResourceId) ? '"${imageSku}"' : 'null'
var galleryItemId = empty(imageVersionResourceId) ? '"${imagePublisher}.${imageOffer}${imageSku}"' : 'null'
var hostPoolName = namingConvention.hostPool
var imageType = empty(imageVersionResourceId) ? '"Gallery"' : '"CustomImage"'

module hostPool 'hostPool.bicep' = {
  name: 'deploy-vdpool-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupControlPlane)
  params: {
    activeDirectorySolution: activeDirectorySolution
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    customImageId: customImageId
    customRdpProperty: customRdpProperty
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentityPrincipalId
    diskSku: diskSku
    domainName: domainName
    enableAvdInsights: enableAvdInsights
    galleryImageOffer: galleryImageOffer
    galleryImagePublisher: galleryImagePublisher
    galleryImageSku: galleryImageSku
    galleryItemId: galleryItemId
    hostPoolDiagnosticSettingName: namingConvention.hostPoolDiagnosticSetting
    hostPoolName: hostPoolName
    hostPoolNetworkInterfaceName: namingConvention.hostPoolNetworkInterface
    hostPoolPrivateEndpointName: namingConvention.hostPoolPrivateEndpoint
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    imageType: imageType
    location: locationControlPlane
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    maxSessionLimit: maxSessionLimit
    mlzTags: mlzTags
    sessionHostNamePrefix: sessionHostNamePrefix
    subnetResourceId: subnetResourceId
    tags: tags
    validationEnvironment: validationEnvironment
    virtualMachineSize: virtualMachineSize
  }
}

module applicationGroup 'applicationGroup.bicep' = {
  name: 'deploy-vdag-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupControlPlane)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentityPrincipalId
    desktopApplicationGroupName: replace(namingConvention.applicationGroup, serviceToken, 'desktop')
    hostPoolResourceId: hostPool.outputs.resourceId
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    mlzTags: mlzTags
    resourceGroupManagement: resourceGroupManagement
    roleDefinitions: roleDefinitions
    securityPrincipalObjectIds: securityPrincipalObjectIds
    desktopFriendlyName: desktopFriendlyName
    tags: tags
    virtualMachineName: managementVirtualMachineName
  }
}

output applicationGroupResourceId string = applicationGroup.outputs.resourceId
output hostPoolName string = hostPool.outputs.name
output hostPoolResourceId string = hostPool.outputs.resourceId
