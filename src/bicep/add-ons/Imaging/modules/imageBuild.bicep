targetScope = 'resourceGroup'

param arcGisProInstaller string = ''
param computeGalleryImageResourceId string = ''
param computeGalleryName string
param containerName string 
param customizations array = []
param deploymentNameSuffix string = utcNow('yyMMddHHs')
param diskEncryptionSetResourceId string
param enableBuildAutomation bool = false
param excludeFromLatest bool = true
param hybridUseBenefit bool = false
param imageDefinitionName string
param imageMajorVersion int
param imageMinorVersion int
param imageVirtualMachineName string
param installAccess bool = false
param installArcGisPro bool = false
param installExcel bool = false
param installOneDrive bool = false
param installOneNote bool = false
param installOutlook bool = false
param installPowerPoint bool = false
param installProject bool = false
param installPublisher bool = false
param installSkypeForBusiness bool = false
param installTeams bool = false
param installVirtualDesktopOptimizationTool bool = false
param installVisio bool = false
param installWord bool = false
param keyVaultName string
@secure()
param localAdministratorPassword string = ''
@secure()
param localAdministratorUsername string = ''
param location string = resourceGroup().location
param managementVirtualMachineName string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param marketplaceImageSKU string
param msrdcwebrtcsvcInstaller string = ''
param officeInstaller string = ''
param replicaCount int = 1
param runbookExecution bool = false
param sourceImageType string = 'AzureMarketplace'
param storageAccountResourceId string
param subnetResourceId string
param tags object = {}
param teamsInstaller string = ''
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param vcRedistInstaller string = ''
param vDOTInstaller string = ''
param virtualMachineSize string

var autoImageVersion = '${imageMajorVersion}.${imageSuffix}.${imageMinorVersion}'
var imageSuffix = take(deploymentNameSuffix, 9)
var resourceGroupName = resourceGroup().name
var storageAccountName = split(storageAccountResourceId, '/')[8]
var storageEndpoint = environment().suffixes.storage
var subscriptionId = subscription().subscriptionId

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = if (runbookExecution) {
  name: keyVaultName
}

module managementVM 'managementVM.bicep' = if (!enableBuildAutomation) {
  name: 'management-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    containerName: containerName
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    hybridUseBenefit: hybridUseBenefit
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    storageAccountName: split(storageAccountResourceId, '/')[8]
    subnetResourceId: subnetResourceId
    tags: tags
    userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
    virtualMachineName: managementVirtualMachineName
  }
}

module virtualMachine 'virtualMachine.bicep' = {
  name: 'image-vm-${deploymentNameSuffix}'
  params: {
    // diskEncryptionSetResourceId: diskEncryptionSetResourceId
    localAdministratorPassword: runbookExecution ? keyVault.getSecret('LocalAdministratorPassword') : localAdministratorPassword
    localAdministratorUsername: runbookExecution ? keyVault.getSecret('LocalAdministratorUsername') : localAdministratorUsername
    location: location
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    computeGalleryImageResourceId: computeGalleryImageResourceId
    sourceImageType: sourceImageType
    subnetResourceId: subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
    virtualMachineName: imageVirtualMachineName
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
  ]
}

module addCustomizations 'customizations.bicep' = {
  name: 'customizations-${deploymentNameSuffix}'
  params: {
    arcGisProInstaller: arcGisProInstaller
    containerName: containerName
    customizations: customizations
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
    installVirtualDesktopOptimizationTool: installVirtualDesktopOptimizationTool
    installVisio: installVisio
    installWord: installWord
    location: location
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    storageAccountName: storageAccountName
    storageEndpoint: storageEndpoint
    tags: tags
    teamsInstaller: teamsInstaller
    userAssignedIdentityObjectId: userAssignedIdentityPrincipalId
    vcRedistInstaller: vcRedistInstaller
    vDotInstaller: vDOTInstaller
    virtualMachineName: virtualMachine.outputs.name
  }
  dependsOn: [
  ]
}

module restartVirtualMachine 'restartVirtualMachine.bicep' = {
  name: 'restart-vm-${deploymentNameSuffix}'
  params: {
    imageVirtualMachineName: virtualMachine.outputs.name
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
    userAssignedIdentityClientId: userAssignedIdentityClientId
    virtualMachineName: enableBuildAutomation ? managementVirtualMachineName : managementVM.outputs.name
  }
  dependsOn: [
    addCustomizations
  ]
}

module sysprepVirtualMachine 'sysprepVirtualMachine.bicep' = {
  name: 'sysprep-vm-${deploymentNameSuffix}'
  params: {
    location: location
    tags: tags
    virtualMachineName: virtualMachine.outputs.name
  }
  dependsOn: [
    restartVirtualMachine
  ]
}

module generalizeVirtualMachine 'generalizeVirtualMachine.bicep' = {
  name: 'generalize-vm-${deploymentNameSuffix}'
  params: {
    imageVirtualMachineName: virtualMachine.outputs.name
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
    userAssignedIdentityClientId: userAssignedIdentityClientId
    virtualMachineName: enableBuildAutomation ? managementVirtualMachineName : managementVM.outputs.name
  }
  dependsOn: [
    sysprepVirtualMachine
  ]
}

module imageVersion 'imageVersion.bicep' = {
  name: 'image-version-${deploymentNameSuffix}'
  params: {
    computeGalleryImageResourceId: computeGalleryImageResourceId
    computeGalleryName: computeGalleryName
    //diskEncryptionSetResourceId: diskEncryptionSetResourceId
    excludeFromLatest: excludeFromLatest
    imageDefinitionName: imageDefinitionName
    imageVersionNumber: autoImageVersion
    imageVirtualMachineResourceId: virtualMachine.outputs.resourceId
    location: location
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    replicaCount: replicaCount
    tags: tags
  }
  dependsOn: [
    generalizeVirtualMachine
  ]
}

module removeVirtualMachine 'removeVirtualMachine.bicep' = {
  name: 'remove-vm-${deploymentNameSuffix}'
  params: {
    enableBuildAutomation: enableBuildAutomation
    imageVirtualMachineName: virtualMachine.outputs.name
    location: location
    tags: tags
    userAssignedIdentityClientId: userAssignedIdentityClientId
    virtualMachineName: enableBuildAutomation ? managementVirtualMachineName : managementVM.outputs.name
  }
  dependsOn: [
    imageVersion
  ]
}
