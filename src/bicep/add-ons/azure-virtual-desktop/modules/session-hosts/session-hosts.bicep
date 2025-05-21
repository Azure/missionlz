targetScope = 'subscription'

param activeDirectorySolution string
param availability string
param availabilitySetsCount int
param availabilitySetsIndex int
param availabilityZones array
param avdConfigurationZipFileName string
param dataCollectionRuleResourceId string
param delimiter string
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
// param enableRecoveryServices bool
param enableWindowsUpdate bool
param environmentAbbreviation string
param fslogixContainerType string
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
param names object
param netAppFileShares array
param networkSecurityGroupResourceId string
param organizationalUnitPath string
param profile string
// param recoveryServicesVaultName string
param resourceGroupManagement string
param scalingWeekdaysOffPeakStartTime string
param scalingWeekdaysPeakStartTime string
param scalingWeekendsOffPeakStartTime string
param scalingWeekendsPeakStartTime string
param securityPrincipalObjectIds array
param sessionHostBatchCount int
param sessionHostIndex int
param stampIndexFull string
param storageAccountNamePrefix string
param storageCount int
param storageIndex int
param storageService string
param storageSuffix string
param subnetResourceId string
param tags object
param timeZone string
@secure()
param virtualMachineAdminPassword string
param virtualMachineAdminUsername string
param virtualMachineSize string

var availabilitySetNamePrefix = names.availabilitySet
var tagsVirtualMachines = union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
var uniqueToken = uniqueString(identifier, environmentAbbreviation, subscription().subscriptionId)

resource computeGallery 'Microsoft.Compute/galleries@2023-07-03' existing = if (!empty(imageVersionResourceId)) {
  name: split(imageVersionResourceId, '/')[8]
  scope: resourceGroup(split(imageVersionResourceId, '/')[2], split(imageVersionResourceId, '/')[4])
}

resource computeGalleryImage 'Microsoft.Compute/galleries/images@2023-07-03' existing = if (!empty(imageVersionResourceId)) {
  name: split(imageVersionResourceId, '/')[10]
  parent: computeGallery
}


resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${names.resourceGroup}${delimiter}hosts'
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
}

// Sets an Azure policy to disable public network access to managed disks
module policyAssignment '../management/policy-assignment.bicep' = {
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

module availabilitySets 'availability-sets.bicep' = if (hostPoolType == 'Pooled' && availability == 'AvailabilitySets') {
  name: 'deploy-avSets-${deploymentNameSuffix}'
  scope: rg
  params: {
    availabilitySetNamePrefix: availabilitySetNamePrefix
    availabilitySetsCount: availabilitySetsCount
    availabilitySetsIndex: availabilitySetsIndex
    delimiter: delimiter
    location: location
    tagsAvailabilitySets: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/availabilitySets'] ?? {}, mlzTags)
  }
}

// Role Assignment for Entra Joined Virtual Machines
// Purpose: assigns the Virtual Machine Login User role on the hosts resource group
// to enable the login to Entra joined virtual machines
module roleAssignments '../common/role-assignments/resource-group.bicep' = [for i in range(0, length(securityPrincipalObjectIds)): if (contains(activeDirectorySolution, 'EntraId')) {
  name: 'assign-role-${i}-${deploymentNameSuffix}'
  scope: rg
  params: {
    principalId: securityPrincipalObjectIds[i]
    principalType: 'Group'
    roleDefinitionId: 'fb879df8-f326-4884-b1cf-06f3ad86be52'
  }
}]

resource gallery 'Microsoft.Compute/galleries@2023-07-03' existing = if (!empty(imageVersionResourceId)) {
  scope: resourceGroup(split(imageVersionResourceId, '/')[2], split(imageVersionResourceId, '/')[4])
  name: split(imageVersionResourceId, '/')[8]
}

resource image 'Microsoft.Compute/galleries/images@2023-07-03' existing = if (!empty(imageVersionResourceId)) {
  parent: gallery
  name: split(imageVersionResourceId, '/')[10]
}

// Disable Autoscale if adding new session hosts to an existing host pool
module disableAutoscale '../common/run-command.bicep' = {
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
        value: names.scalingPlan
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
module virtualMachines 'virtual-machines.bicep' = [for i in range(1, sessionHostBatchCount): {
  name: 'deploy-vms-${i - 1}-${deploymentNameSuffix}'
  scope: rg
  params: {
    activeDirectorySolution: activeDirectorySolution
    availability: availability
    availabilitySetNamePrefix: availabilitySetNamePrefix
    availabilityZones: availabilityZones
    avdConfigurationZipFileName: avdConfigurationZipFileName
    batchCount: i
    dataCollectionRuleAssociationNamePrefix: names.dataCollectionRuleAssociation
    dataCollectionRuleResourceId: dataCollectionRuleResourceId
    delimiter: delimiter
    deployFslogix: deployFslogix
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedidentityClientId: deploymentUserAssignedIdentityClientId
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskNamePrefix: names.virtualMachineDisk
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableAvdInsights: enableAvdInsights
    enableDrainMode: drainMode
    enableWindowsUpdate: enableWindowsUpdate
    fslogixContainerType: fslogixContainerType
    hostPoolResourceId: hostPoolResourceId
    imageVersionResourceId: imageVersionResourceId
    imageOffer: empty(imageVersionResourceId) ? imageOffer : image.properties.identifier.offer
    imagePublisher: empty(imageVersionResourceId) ? imagePublisher : image.properties.identifier.publisher
    imagePurchasePlan: profile == 'ArcGISPro' && !empty(imageVersionResourceId) ? computeGalleryImage.properties.purchasePlan : profile == 'ArcGISPro' && empty(imageVersionResourceId) ? {
      name: imageSku
      publisher: imagePublisher
      product: imageOffer
    } : {}
    imageSku: empty(imageVersionResourceId) ? imageSku : image.properties.identifier.sku
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    netAppFileShares: netAppFileShares
    networkInterfaceNamePrefix: names.virtualMachineNetworkInterface
    networkSecurityGroupResourceId: networkSecurityGroupResourceId
    organizationalUnitPath: organizationalUnitPath
    profile: profile
    resourceGroupManagement: resourceGroupManagement
    sessionHostCount: i == sessionHostBatchCount && divisionRemainderValue > 0 ? divisionRemainderValue : maxResourcesPerTemplateDeployment
    sessionHostIndex: i == 1 ? sessionHostIndex : ((i - 1) * maxResourcesPerTemplateDeployment) + sessionHostIndex
    stampIndexFull: stampIndexFull
    storageAccountPrefix: storageAccountNamePrefix
    storageCount: storageCount
    storageIndex: storageIndex
    storageService: storageService
    storageSuffix: storageSuffix
    subnetResourceId: subnetResourceId
    tagsNetworkInterfaces: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/networkInterfaces'] ?? {}, mlzTags)
    tagsVirtualMachines: tagsVirtualMachines
    uniqueToken: uniqueToken
    virtualMachineNamePrefix: names.virtualMachine
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    availabilitySets
    disableAutoscale  ]
}]

/* module recoveryServices 'recoveryServices.bicep' = if (enableRecoveryServices && hostPoolType == 'Personal') {
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
} */

module scalingPlan '../control-plane/scaling-plan.bicep' = {
  name: 'deploy-scalingPlan-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentityPrincipalId
    enableAvdInsights: enableAvdInsights
    hostPoolResourceId: hostPoolResourceId
    hostPoolType: hostPoolType
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    scalingPlanDiagnosticSettingName: names.scalingPlanDiagnosticSetting
    scalingPlanName: names.scalingPlan
    tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.DesktopVirtualization/scalingPlans'] ?? {}, mlzTags)
    timeZone: timeZone
    weekdaysOffPeakStartTime: scalingWeekdaysOffPeakStartTime
    weekdaysPeakStartTime: scalingWeekdaysPeakStartTime
    weekendsOffPeakStartTime: scalingWeekendsOffPeakStartTime
    weekendsPeakStartTime: scalingWeekendsPeakStartTime
  }
  dependsOn: [
    // recoveryServices
    virtualMachines
  ]
}
