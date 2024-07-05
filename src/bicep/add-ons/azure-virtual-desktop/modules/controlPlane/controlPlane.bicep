targetScope = 'subscription'

param activeDirectorySolution string
param artifactsUri string
param avdPrivateDnsZoneResourceId string
param customImageId string
param customRdpProperty string
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param deploymentUserAssignedIdentityPrincipalId string
param desktopFriendlyName string
param diskSku string
param domainName string
param existingFeedWorkspace bool
param hostPoolPublicNetworkAccess string
param hostPoolType string
param hubResourceGroupName string
param hubSubscriptionId string
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersionResourceId string
param keyVaultDiagnosticLogs array
param locationControlPlane string
param locationVirtualMachines string
param logAnalyticsWorkspaceResourceId string
param logAnalyticsWorkspaceResourceId_Ops string
param managementVirtualMachineName string
param maxSessionLimit int
param mlzTags object
param monitoring bool
param namingConvention object
param resourceAbbreviations object
param resourceGroups array
param roleDefinitions object
param securityPrincipalObjectIds array
param serviceToken string
param sessionHostNamePrefix string
param stampIndex string
@secure()
param storageAccountResourceId string
param subnetResourceId string
param tags object
param validationEnvironment bool
param virtualMachineSize string
param workspaceFriendlyName string
param workspacePublicNetworkAccess string

var galleryImageOffer = empty(imageVersionResourceId) ? '"${imageOffer}"' : 'null'
var galleryImagePublisher = empty(imageVersionResourceId) ? '"${imagePublisher}"' : 'null'
var galleryImageSku = empty(imageVersionResourceId) ? '"${imageSku}"' : 'null'
var galleryItemId = empty(imageVersionResourceId) ? '"${imagePublisher}.${imageOffer}${imageSku}"' : 'null'
var hostPoolName = namingConvention.hostPool
var imageType = empty(imageVersionResourceId) ? '"Gallery"' : '"CustomImage"'

module hostPool 'hostPool.bicep' = {
  name: 'deploy-vdpool-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroups[0])
  params: {
    activeDirectorySolution: activeDirectorySolution
    // artifactsUri: artifactsUri
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    customImageId: customImageId
    customRdpProperty: customRdpProperty
    deploymentNameSuffix: deploymentNameSuffix
    // deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentityPrincipalId
    diskSku: diskSku
    domainName: domainName
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
    keyVaultDiagnosticLogs: keyVaultDiagnosticLogs
    keyVaultDiagnosticSettingName: replace(namingConvention.keyVaultDiagnosticSetting, serviceToken, resourceAbbreviations.hostPools)
    keyVaultName: take(replace(namingConvention.keyVault, serviceToken, resourceAbbreviations.hostPools), 24)
    keyVaultNetworkInterfaceName: replace(namingConvention.keyVaultNetworkInterface, serviceToken, resourceAbbreviations.hostPools)
    keyVaultPrivateDnsZoneResourceId: resourceId(
      hubSubscriptionId,
      hubResourceGroupName,
      'Microsoft.Network/privateDnsZones',
      replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
    )
    keyVaultPrivateEndpointName: replace(namingConvention.keyVaultPrivateEndpoint, serviceToken, resourceAbbreviations.hostPools)
    location: locationControlPlane
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logAnalyticsWorkspaceResourceId_Ops: logAnalyticsWorkspaceResourceId_Ops
    // managementVirtualMachineName: managementVirtualMachineName
    maxSessionLimit: maxSessionLimit
    mlzTags: mlzTags
    monitoring: monitoring
    // resourceGroupManagement: resourceGroups[3]
    sessionHostNamePrefix: sessionHostNamePrefix
    storageAccountResourceId: storageAccountResourceId
    subnetResourceId: subnetResourceId
    tags: tags
    validationEnvironment: validationEnvironment
    virtualMachineSize: virtualMachineSize
  }
}

module applicationGroup 'applicationGroup.bicep' = {
  name: 'deploy-vdag-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroups[0])
  params: {
    artifactsUri: artifactsUri
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    desktopApplicationGroupName: replace(namingConvention.applicationGroup, serviceToken, 'desktop')
    hostPoolResourceId: hostPool.outputs.resourceId
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    mlzTags: mlzTags
    resourceGroupManagement: resourceGroups[3]
    roleDefinitions: roleDefinitions
    securityPrincipalObjectIds: securityPrincipalObjectIds
    desktopFriendlyName: desktopFriendlyName
    tags: tags
    virtualMachineName: managementVirtualMachineName
  }
}

module workspace 'workspace.bicep' = {
  name: 'deploy-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroups[1])
  params: {
    applicationGroupReferences: applicationGroup.outputs.applicationGroupReference
    artifactsUri: artifactsUri
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    existing: existingFeedWorkspace
    hostPoolName: hostPoolName
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    mlzTags: mlzTags
    monitoring: monitoring
    resourceGroupManagement: resourceGroups[3]
    subnetResourceId: subnetResourceId
    tags: tags
    virtualMachineName: managementVirtualMachineName
    workspaceFeedDiagnoticSettingName: replace(replace(namingConvention.workspaceFeedDiagnosticSetting, serviceToken, 'feed'), '-${stampIndex}', '')
    workspaceFeedName: replace(replace(namingConvention.workspaceFeed, serviceToken, 'feed'), '-${stampIndex}', '')
    workspaceFeedNetworkInterfaceName: replace(replace(namingConvention.workspaceFeedNetworkInterface, serviceToken, 'feed'), '-${stampIndex}', '')
    workspaceFeedPrivateEndpointName: replace(replace(namingConvention.workspaceFeedPrivateEndpoint, serviceToken, 'feed'), '-${stampIndex}', '')
    workspaceFriendlyName: empty(workspaceFriendlyName) ? replace(replace(namingConvention.workspaceFeed, '-${serviceToken}', ''), '-${stampIndex}', '') : '${workspaceFriendlyName} (${locationControlPlane})'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}

output hostPoolName string = hostPool.outputs.name
