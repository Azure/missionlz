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
param diskAccessPolicyDefinitionId string
param diskAccessPolicyDisplayName string
param diskAccessResourceId string
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
param enableRecoveryServices bool
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
param profile string
param recoveryServicesVaultName string
param resourceGroupManagement string
param resourceGroupName string
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
var tagsVirtualMachines = union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
var uniqueToken = uniqueString(identifier, environmentAbbreviation, subscription().subscriptionId)
var virtualMachineNamePrefix = replace(namingConvention.virtualMachine, serviceToken, '')

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
}

// Sets an Azure policy to disable public network access to managed disks
module policyAssignment '../management/policyAssignment.bicep' = {
  name: 'assign-policy-diskAccess-${deploymentNameSuffix}'
  scope: rg
  params: {
    diskAccessResourceId: diskAccessResourceId
    location: location
    policyDefinitionId: diskAccessPolicyDefinitionId
    policyDisplayName: diskAccessPolicyDisplayName
    policyName: diskAccessPolicyDisplayName
  }
}

module availabilitySets 'availabilitySets.bicep' = if (hostPoolType == 'Pooled' && availability == 'AvailabilitySets') {
  name: 'deploy-avSets-${deploymentNameSuffix}'
  scope: rg
  params: {
    availabilitySetNamePrefix: availabilitySetNamePrefix
    availabilitySetsCount: availabilitySetsCount
    availabilitySetsIndex: availabilitySetsIndex
    location: location
    tagsAvailabilitySets: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/availabilitySets'] ?? {}, mlzTags)
  }
}

// Role Assignment for Entra Joined Virtual Machines
// Purpose: assigns the Virtual Machine Login User role on the hosts resource group
// to enable the login to Entra joined virtual machines
module roleAssignments '../common/roleAssignments/resourceGroup.bicep' = [for i in range(0, length(securityPrincipalObjectIds)): if (contains(activeDirectorySolution, 'EntraId')) {
  name: 'assign-role-${i}-${deploymentNameSuffix}'
  scope: rg
  params: {
    principalId: securityPrincipalObjectIds[i]
    principalType: 'Group'
    roleDefinitionId: 'fb879df8-f326-4884-b1cf-06f3ad86be52'
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
  name: 'deploy-disableAutoscale-${deploymentNameSuffix}'
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

// Set MarketPlace Terms for ESRI's ArcGIS Pro image
module setMarketplaceTerms '../common/runCommand.bicep' = if (profile == 'ArcGISPro') {
  name: 'set-marketplaceTerms-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    location: location
    name: 'Set-AzureMarketplaceTerms'
    parameters: [
      {
        name: 'ImageOffer'
        value: imageOffer
      }
      {
        name: 'ImagePublisher'
        value: imagePublisher
      }
      {
        name: 'ImageSku'
        value: imageSku
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
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
    script: loadTextContent('../../artifacts/Set-AzureMarketplaceTerms.ps1')
    tags: tagsVirtualMachines
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    disableAutoscale
  ]
}

@batchSize(1)
module virtualMachines 'virtualMachines.bicep' = [for i in range(1, sessionHostBatchCount): {
  name: 'deploy-vms-${i - 1}-${deploymentNameSuffix}'
  scope: rg
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
    profile: profile
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
    tagsNetworkInterfaces: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/networkInterfaces'] ?? {}, mlzTags)
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
    setMarketplaceTerms
  ]
}]

module recoveryServices 'recoveryServices.bicep' = if (enableRecoveryServices && hostPoolType == 'Personal') {
  name: 'deploy-recoveryServices-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    deployFslogix: deployFslogix
    deploymentNameSuffix: deploymentNameSuffix
    divisionRemainderValue: divisionRemainderValue
    location: location
    maxResourcesPerTemplateDeployment: maxResourcesPerTemplateDeployment
    recoveryServicesVaultName: recoveryServicesVaultName
    resourceGroupHosts: rg.name
    resourceGroupManagement: resourceGroupManagement
    sessionHostBatchCount: sessionHostBatchCount
    sessionHostIndex: sessionHostIndex
    tagsRecoveryServicesVault: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.recoveryServices/vaults'] ?? {}, mlzTags)
    virtualMachineNamePrefix: virtualMachineNamePrefix
  }
  dependsOn: [
    virtualMachines
  ]
}

module scalingPlan '../management/scalingPlan.bicep' = {
  name: 'deploy-scalingPlan-${deploymentNameSuffix}'
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
    tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.DesktopVirtualization/scalingPlans'] ?? {}, mlzTags)
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
