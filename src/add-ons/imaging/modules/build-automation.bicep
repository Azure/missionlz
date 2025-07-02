/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param arcGisProInstaller string
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
param keyVaultPrivateDnsZoneResourceId string
param location string
param locationProperties object
param logAnalyticsWorkspaceResourceId string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param marketplaceImageSKU string
param msrdcwebrtcsvcInstaller string
param officeInstaller string
param oUPath string
param replicaCount int
param computeGalleryImageResourceId string
param sourceImageType string
param storageAccountResourceId string
param tags object
param teamsInstaller string
param tier object
param updateService string
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param vcRedistInstaller string
param vDOTInstaller string
@secure()
param virtualMachineAdminPassword string
param virtualMachineAdminUsername string
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

module virtualNetwork 'virtual-network.bicep' = {
  scope: resourceGroup(split(tier.subnetResourceId, '/')[2], split(tier.subnetResourceId, '/')[4])
  name: 'virtual-network-${deploymentNameSuffix}'
  params: {
    principalId: userAssignedIdentityPrincipalId
    virtualNetworkName: split(tier.subnetResourceId, '/')[8]
  }
}

module keyVault 'key-vault.bicep' = {
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  name: 'key-vault-${deploymentNameSuffix}'
  params: {
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    keyVaultName: tier.namingConvention.keyVault
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    location: location
    mlzTags: tier.mlzTags
    roleDefinitionResourceId: roleDefinition.id
    subnetResourceId: tier.subnetResourceId
    tags: tags
    userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
  }
}

module templateSpec 'template-spec.bicep' = {
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  name: 'template-spec-${deploymentNameSuffix}'
  params: {
    imageDefinitionName: imageDefinitionName
    location: location
    mlzTags: tier.mlzTags
    tags: tags
  }
}

module managementVM 'management-virtual-machine.bicep' = {
  name: 'management-vm-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    hybridUseBenefit: hybridUseBenefit
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    location: location
    mlzTags: tier.mlzTags
    subnetResourceId: tier.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
    virtualMachineName: '${tier.namingConvention.virtualMachine}wm'
    virtualMachineSize: virtualMachineSize
  }
}

module automationAccount 'automation-account.bicep' = {
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  name: 'automation-account-${deploymentNameSuffix}'
  params: {
    arcGisProInstaller: arcGisProInstaller
    actionGroupName: tier.namingConvention.actionGroup
    automationAccountName: tier.namingConvention.automationAccount
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
    imageVirtualMachineName: '${tier.namingConvention.virtualMachine}wb'
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
    keyVaultName: tier.namingConvention.keyVault
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    managementVirtualMachineName: managementVM.outputs.name
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    mlzTags: tier.mlzTags
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    oUPath: oUPath
    replicaCount: replicaCount
    resourceGroupName: tier.resourceGroupName
    sourceImageType: sourceImageType
    storageAccountResourceId: storageAccountResourceId
    subnetResourceId: tier.subnetResourceId
    tags: tags
    teamsInstaller: teamsInstaller
    templateSpecResourceId: templateSpec.outputs.resourceId
    timeZone: locationProperties.timeZone
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
