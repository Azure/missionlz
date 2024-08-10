/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param actionGroupName string
param arcGisProInstaller string
param automationAccountName string
param automationAccountPrivateDnsZoneResourceId string
param computeGalleryResourceId string
param containerName string
param customizations array
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
param distributionGroup string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableBuildAutomation bool
param excludeFromLatest bool
param hybridUseBenefit bool
param imageDefinitionName string
param imageMajorVersion int
param imageMinorVersion int
param imagePatchVersion int
param imageVirtualMachineName string
param installAccess bool
param installArcGisPro bool
param installExcel bool
param installOneDrive bool
param installOneNote bool
param installOutlook bool
param installPowerPoint bool
param installProject bool
param installPublisher bool
param installSkypeForBusiness bool
param installTeams bool
param installUpdates bool
param installVirtualDesktopOptimizationTool bool
param installVisio bool
param installWord bool
param keyVaultName string
param keyVaultPrivateDnsZoneResourceId string
@secure()
param localAdministratorPassword string
param localAdministratorUsername string
param location string
param logAnalyticsWorkspaceResourceId string
param managementVirtualMachineName string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param marketplaceImageSKU string
param mlzTags object
param msrdcwebrtcsvcInstaller string
param officeInstaller string
param oUPath string
param replicaCount int
param resourceGroupName string
param computeGalleryImageResourceId string
param sourceImageType string
param storageAccountResourceId string
param subnetResourceId string
param subscriptionId string
param tags object
param teamsInstaller string
param timeZone string
param updateService string
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param vcRedistInstaller string
param vDOTInstaller string
param virtualMachineSize string
param wsusServer string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'KeyVaultDeployAction')
  properties: {
    roleName: 'KeyVaultDeployAction_${subscription().subscriptionId}'
    description: 'Allows a principal to get but not view Key Vault secrets for ARM template deployments.'
    assignableScopes: [
      subscription().id
    ]
    permissions: [
      {
        actions: [
          'Microsoft.KeyVault/vaults/deploy/action'
        ]
      }
    ]
  }
}

module virtualNetwork 'virtualNetwork.bicep' = {
  scope: resourceGroup(split(subnetResourceId, '/')[2], split(subnetResourceId, '/')[4])
  name: 'virtual-network-${deploymentNameSuffix}'
  params: {
    principalId: userAssignedIdentityPrincipalId
    virtualNetworkName: split(subnetResourceId, '/')[8]
  }
}

module keyVault 'keyVault.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'key-vault-${deploymentNameSuffix}'
  params: {
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    keyVaultName: keyVaultName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    mlzTags: mlzTags
    roleDefinitionResourceId: roleDefinition.id
    subnetResourceId: subnetResourceId
    tags: tags
    userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
  }
}

module templateSpec 'templateSpec.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'template-spec-${deploymentNameSuffix}'
  params: {
    imageDefinitionName: imageDefinitionName
    location: location
    mlzTags: mlzTags
    tags: tags
  }
}

module managementVM 'managementVM.bicep' = {
  name: 'management-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {

    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    hybridUseBenefit: hybridUseBenefit
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    mlzTags: mlzTags

    subnetResourceId: subnetResourceId
    tags: tags

    userAssignedIdentityResourceId: userAssignedIdentityResourceId
    virtualMachineName: managementVirtualMachineName
    virtualMachineSize: virtualMachineSize
  }
}

module automationAccount 'automationAccount.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'automation-account-${deploymentNameSuffix}'
  params: {
    arcGisProInstaller: arcGisProInstaller
    actionGroupName: actionGroupName
    automationAccountName: automationAccountName
    automationAccountPrivateDnsZoneResourceId: automationAccountPrivateDnsZoneResourceId
    computeGalleryImageResourceId: computeGalleryImageResourceId
    computeGalleryResourceId: computeGalleryResourceId
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    distributionGroup: distributionGroup
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    enableBuildAutomation: enableBuildAutomation
    excludeFromLatest: excludeFromLatest
    hybridUseBenefit: hybridUseBenefit
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    imagePatchVersion: imagePatchVersion
    imageVirtualMachineName: imageVirtualMachineName
    installAccess: installAccess
    installArcGisPro: installArcGisPro
    installExcel: installExcel
    installOneDrive: installOneDrive
    installOneNote: installOneNote
    installOutlook: installOutlook
    installPowerPoint: installPowerPoint
    installProject: installProject
    installPublisher: installPublisher
    installSkypeForBusiness: installSkypeForBusiness
    installTeams: installTeams
    installUpdates: installUpdates
    installVirtualDesktopOptimizationTool: installVirtualDesktopOptimizationTool
    installVisio: installVisio
    installWord: installWord
    keyVaultName: keyVaultName
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    managementVirtualMachineName: managementVM.outputs.name
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    mlzTags: mlzTags
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    oUPath: oUPath
    replicaCount: replicaCount
    resourceGroupName: resourceGroupName
    sourceImageType: sourceImageType
    storageAccountResourceId: storageAccountResourceId
    subnetResourceId: subnetResourceId
    tags: tags
    teamsInstaller: teamsInstaller
    templateSpecResourceId: templateSpec.outputs.resourceId
    timeZone: timeZone
    updateService: updateService
    userAssignedIdentityClientId: userAssignedIdentityClientId
    userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineSize: virtualMachineSize
    wsusServer: wsusServer
  }
}
