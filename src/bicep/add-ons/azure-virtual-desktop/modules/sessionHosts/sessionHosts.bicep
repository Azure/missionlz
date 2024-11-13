targetScope = 'subscription'

param activeDirectorySolution string
param availability string
param availabilitySetsCount int
param availabilitySetsIndex int
param availabilityZones array
param avdConfigurationZipFileName string
param dataCollectionRuleResourceId string
param deployFslogix bool
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param deploymentUserAssignedIdentityPrincipalId string
param diskEncryptionSetResourceId string
param diskSku string
param divisionRemainderValue int
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param drainMode bool
param enableAcceleratedNetworking bool
param enableAvdInsights bool
param environmentAbbreviation string
param fslogixContainerType string
param hostPoolName string
param hostPoolResourceId string
param hostPoolType string
param identifier string
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersionResourceId string
param location string
param logAnalyticsWorkspaceResourceId string
param managementVirtualMachineName string
param maxResourcesPerTemplateDeployment int
param mlzTags object
param namingConvention object
param netAppFileShares array
param organizationalUnitPath string
param enableRecoveryServices bool
param recoveryServicesVaultName string
param resourceGroupControlPlane string
param resourceGroupHosts string
param resourceGroupManagement string
param roleDefinitions object
param scalingWeekdaysOffPeakStartTime string
param scalingWeekdaysPeakStartTime string
param scalingWeekendsOffPeakStartTime string
param scalingWeekendsPeakStartTime string
param securityPrincipalObjectIds array
param serviceToken string
param sessionHostBatchCount int
param sessionHostIndex int
param storageAccountNamePrefix string
param storageCount int
param storageIndex int
param storageService string
param storageSuffix string
param subnetResourceId string
param tags object
param timeZone string
@secure()
param virtualMachinePassword string
param virtualMachineSize string
param virtualMachineUsername string

var availabilitySetNamePrefix = namingConvention.availabilitySet
var tagsAvailabilitySets = union({'cm-resource-parent': '${subscription().id}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Compute/availabilitySets') ? tags['Microsoft.Compute/availabilitySets'] : {}, mlzTags)
var tagsNetworkInterfaces = union({'cm-resource-parent': '${subscription().id}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Network/networkInterfaces') ? tags['Microsoft.Network/networkInterfaces'] : {}, mlzTags)
var tagsRecoveryServicesVault = union({'cm-resource-parent': '${subscription().id}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.recoveryServices/vaults') ? tags['Microsoft.recoveryServices/vaults'] : {}, mlzTags)
var tagsVirtualMachines = union({'cm-resource-parent': '${subscription().id}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}, mlzTags)
var uniqueToken = uniqueString(identifier, environmentAbbreviation, subscription().subscriptionId)
var virtualMachineNamePrefix = replace(namingConvention.virtualMachine, serviceToken, '')

module availabilitySets 'availabilitySets.bicep' = if (hostPoolType == 'Pooled' && availability == 'AvailabilitySets') {
  name: 'deploy-avail-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupHosts)
  params: {
    availabilitySetNamePrefix: availabilitySetNamePrefix
    availabilitySetsCount: availabilitySetsCount
    availabilitySetsIndex: availabilitySetsIndex
    location: location
    tagsAvailabilitySets: tagsAvailabilitySets
  }
}

// Role Assignment for Virtual Machine Login User
// This module deploys the role assignments to login to Azure AD joined session hosts
module roleAssignments '../common/roleAssignments/resourceGroup.bicep' = [for i in range(0, length(securityPrincipalObjectIds)): if (!contains(activeDirectorySolution, 'DomainServices')) {
  name: 'deploy-role-assignments-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupHosts)
  params: {
    principalId: securityPrincipalObjectIds[i]
    principalType: 'Group'
    roleDefinitionId: roleDefinitions.VirtualMachineUserLogin
  }
}]

resource gallery 'Microsoft.Compute/galleries@2023-07-03' existing = if (empty(imageVersionResourceId)) {
  scope: resourceGroup(split(imageVersionResourceId, '/')[2], split(imageVersionResourceId, '/')[4])
  name: split(imageVersionResourceId, '/')[8]
}

resource image 'Microsoft.Compute/galleries/images@2023-07-03' existing = if (empty(imageVersionResourceId)) {
  parent: gallery
  name: split(imageVersionResourceId, '/')[10]
}

// Disable Autoscale if adding new session hosts to an existing host pool
module disableAutoscale '../common/runCommand.bicep' = {
  name: 'deploy-disable-autoscale-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    location: location
    name: 'Disable-Autoscale'
    parameters: [
      {
        name: 'HostPoolResourceId'
        value: hostPoolResourceId
      }
      { 
        name: 'ResourceGroupName' 
        value: resourceGroupManagement
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'ScalingPlanName' 
        value: namingConvention.scalingPlan
      }
      {
        name: 'SubscriptionId' 
        value: subscription().subscriptionId
      }
      {
        name: 'UserAssignedidentityClientId' 
        value: deploymentUserAssignedIdentityClientId
      }
    ]
    script: loadTextContent('../../artifacts/Disable-Autoscale.ps1')
    tags: tagsVirtualMachines
    virtualMachineName: managementVirtualMachineName
  }
}

@batchSize(1)
module virtualMachines 'virtualMachines.bicep' = [for i in range(1, sessionHostBatchCount): {
  name: 'deploy-vms-${i - 1}-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupHosts)
  params: {
    activeDirectorySolution: activeDirectorySolution
    availability: availability
    availabilitySetNamePrefix: availabilitySetNamePrefix
    availabilityZones: availabilityZones
    avdConfigurationZipFileName: avdConfigurationZipFileName
    batchCount: i
    dataCollectionRuleAssociationName: namingConvention.dataCollectionRuleAssociation
    dataCollectionRuleResourceId: dataCollectionRuleResourceId
    deployFslogix: deployFslogix
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedidentityClientId: deploymentUserAssignedIdentityClientId
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskNamePrefix: namingConvention.virtualMachineDisk
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableAvdInsights: enableAvdInsights
    enableDrainMode: drainMode
    fslogixContainerType: fslogixContainerType
    hostPoolName: hostPoolName
    imageVersionResourceId: imageVersionResourceId
    imageOffer: empty(imageVersionResourceId) ? imageOffer : image.properties.purchasePlan.product
    imagePublisher: empty(imageVersionResourceId) ? imagePublisher: image.properties.purchasePlan.publisher
    imageSku: empty(imageVersionResourceId) ? imageSku : image.properties.purchasePlan.name
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    netAppFileShares: netAppFileShares
    networkInterfaceNamePrefix: namingConvention.virtualMachineNetworkInterface
    organizationalUnitPath: organizationalUnitPath
    resourceGroupControlPlane: resourceGroupControlPlane
    resourceGroupManagement: resourceGroupManagement
    serviceToken: serviceToken
    sessionHostCount: i == sessionHostBatchCount && divisionRemainderValue > 0 ? divisionRemainderValue : maxResourcesPerTemplateDeployment
    sessionHostIndex: i == 1 ? sessionHostIndex : ((i - 1) * maxResourcesPerTemplateDeployment) + sessionHostIndex
    storageAccountPrefix: storageAccountNamePrefix
    storageCount: storageCount
    storageIndex: storageIndex
    storageService: storageService
    storageSuffix: storageSuffix
    subnetResourceId: subnetResourceId
    tagsNetworkInterfaces: tagsNetworkInterfaces
    tagsVirtualMachines: tagsVirtualMachines
    uniqueToken: uniqueToken
    virtualMachineNamePrefix: virtualMachineNamePrefix
    virtualMachinePassword: virtualMachinePassword
    virtualMachineSize: virtualMachineSize
    virtualMachineUsername: virtualMachineUsername
  }
  dependsOn: [
    availabilitySets
    disableAutoscale
  ]
}]

module recoveryServices 'recoveryServices.bicep' = if (enableRecoveryServices && hostPoolType == 'Personal') {
  name: 'deploy-recovery-services-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    deployFslogix: deployFslogix
    deploymentNameSuffix: deploymentNameSuffix
    divisionRemainderValue: divisionRemainderValue
    location: location
    maxResourcesPerTemplateDeployment: maxResourcesPerTemplateDeployment
    recoveryServicesVaultName: recoveryServicesVaultName
    resourceGroupHosts: resourceGroupHosts
    resourceGroupManagement: resourceGroupManagement
    sessionHostBatchCount: sessionHostBatchCount
    sessionHostIndex: sessionHostIndex
    tagsRecoveryServicesVault: tagsRecoveryServicesVault
    virtualMachineNamePrefix: virtualMachineNamePrefix
  }
  dependsOn: [
    virtualMachines
  ]
}

module scalingPlan '../management/scalingPlan.bicep' = {
  name: 'deploy-scaling-plan-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentityPrincipalId
    enableAvdInsights: enableAvdInsights
    hostPoolResourceId: hostPoolResourceId
    hostPoolType: hostPoolType
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    scalingPlanDiagnosticSettingName: namingConvention.scalingPlanDiagnosticSetting
    scalingPlanName: namingConvention.scalingPlan
    tags: tags
    timeZone: timeZone
    weekdaysOffPeakStartTime: scalingWeekdaysOffPeakStartTime
    weekdaysPeakStartTime: scalingWeekdaysPeakStartTime
    weekendsOffPeakStartTime: scalingWeekendsOffPeakStartTime
    weekendsPeakStartTime: scalingWeekendsPeakStartTime
  }
  dependsOn: [
    recoveryServices
    virtualMachines
  ]
}
