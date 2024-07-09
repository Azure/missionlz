targetScope = 'subscription'

param activeDirectorySolution string
param availability string
param availabilitySetsCount int
param availabilitySetsIndex int
param availabilityZones array
param dataCollectionRuleResourceId string
param delegatedSubnetResourceId string
param deployFslogix bool
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param diskEncryptionSetResourceId string
param diskSku string
param divisionRemainderValue int
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param drainMode bool
param enableAcceleratedNetworking bool
param environmentAbbreviation string
param fslogixContainerType string
param hostPoolName string
param hostPoolType string
param identifier string
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersionResourceId string
param location string
param managementVirtualMachineName string
param maxResourcesPerTemplateDeployment int
param mlzTags object
param monitoring bool
param namingConvention object
param netAppFileShares array
param organizationalUnitPath string
param pooledHostPool bool
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param enableRecoveryServices bool
param enableScalingTool bool
param recoveryServicesVaultName string
param resourceAbbreviations object
param resourceGroupControlPlane string
param resourceGroupHosts string
param resourceGroupManagement string
param roleDefinitions object
param scalingBeginPeakTime string
param scalingEndPeakTime string
param scalingLimitSecondsToForceLogOffUser string
param scalingMinimumNumberOfRdsh string
param scalingSessionThresholdPerCPU string
param securityPrincipalObjectIds array
param serviceToken string
param sessionHostBatchCount int
param sessionHostIndex int
param storageCount int
param storageIndex int
param storageService string
param storageSuffix string
param subnetResourceId string
param tags object
param timeDifference string
@secure()
param virtualMachinePassword string
param virtualMachineSize string
param virtualMachineUsername string

var availabilitySetNamePrefix = namingConvention.availabilitySet
var tagsAutomationAccounts = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Automation/automationAccounts') ? tags['Microsoft.Automation/automationAccounts'] : {}, mlzTags)
var tagsAvailabilitySets = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Compute/availabilitySets') ? tags['Microsoft.Compute/availabilitySets'] : {}, mlzTags)
var tagsNetworkInterfaces = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Network/networkInterfaces') ? tags['Microsoft.Network/networkInterfaces'] : {}, mlzTags)
var tagsRecoveryServicesVault = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.recoveryServices/vaults') ? tags['Microsoft.recoveryServices/vaults'] : {}, mlzTags)
var tagsVirtualMachines = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}, mlzTags)
var uniqueToken = uniqueString(identifier, environmentAbbreviation, subscription().subscriptionId)
var virtualMachineNamePrefix = replace(namingConvention.virtualMachine, serviceToken, '')

module availabilitySets 'availabilitySets.bicep' = if (pooledHostPool && availability == 'AvailabilitySets') {
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
module roleAssignments '../common/roleAssignment.bicep' = [for i in range(0, length(securityPrincipalObjectIds)): if (!contains(activeDirectorySolution, 'DomainServices')) {
  name: 'deploy-role-assignments-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupHosts)
  params: {
    principalId: securityPrincipalObjectIds[i]
    principalType: 'Group'
    roleDefinitionId: roleDefinitions.VirtualMachineUserLogin
  }
}]

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: take(replace(namingConvention.keyVault, serviceToken, resourceAbbreviations.hostPools), 24)
  scope: resourceGroup(resourceGroupControlPlane)
}

resource gallery 'Microsoft.Compute/galleries@2023-07-03' existing = if (empty(imageVersionResourceId)) {
  scope: resourceGroup(split(imageVersionResourceId, '/')[2], split(imageVersionResourceId, '/')[4])
  name: split(imageVersionResourceId, '/')[8]
}

resource image 'Microsoft.Compute/galleries/images@2023-07-03' existing = if (empty(imageVersionResourceId)) {
  parent: gallery
  name: split(imageVersionResourceId, '/')[10]
}

@batchSize(1)
module virtualMachines 'virtualMachines.bicep' = [for i in range(1, sessionHostBatchCount): {
  name: 'deploy-vms-${i - 1}-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupHosts)
  params: {
    enableAcceleratedNetworking: enableAcceleratedNetworking
    activeDirectorySolution: activeDirectorySolution
    availability: availability
    availabilitySetNamePrefix: availabilitySetNamePrefix
    availabilityZones: availabilityZones
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
    enableDrainMode: drainMode
    fslogixContainerType: fslogixContainerType
    hostPoolName: hostPoolName
    hostPoolRegistrationToken: keyVault.getSecret('avdHostPoolRegistrationToken')
    imageVersionResourceId: imageVersionResourceId
    imageOffer: empty(imageVersionResourceId) ? imageOffer : image.properties.purchasePlan.product
    imagePublisher: empty(imageVersionResourceId) ? imagePublisher: image.properties.purchasePlan.publisher
    imageSku: empty(imageVersionResourceId) ? imageSku : image.properties.purchasePlan.name
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    monitoring: monitoring
    netAppFileShares: netAppFileShares
    networkInterfaceNamePrefix: namingConvention.virtualMachineNetworkInterface
    organizationalUnitPath: organizationalUnitPath
    resourceGroupControlPlane: resourceGroupControlPlane
    resourceGroupManagement: resourceGroupManagement
    serviceToken: serviceToken
    sessionHostCount: i == sessionHostBatchCount && divisionRemainderValue > 0 ? divisionRemainderValue : maxResourcesPerTemplateDeployment
    sessionHostIndex: i == 1 ? sessionHostIndex : ((i - 1) * maxResourcesPerTemplateDeployment) + sessionHostIndex
    storageAccountPrefix: namingConvention.storageAccount
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
  ]
}]

module recoveryServices 'recoveryServices.bicep' = if (enableRecoveryServices && contains(hostPoolType, 'Personal')) {
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

module scalingTool '../management/scalingTool.bicep' = if (enableScalingTool && pooledHostPool) {
  name: 'deploy-scaling-tool-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    beginPeakTime: scalingBeginPeakTime
    delegatedSubnetResourceId: delegatedSubnetResourceId
    endPeakTime: scalingEndPeakTime
    environmentAbbreviation: environmentAbbreviation
    resourceAbbreviations: resourceAbbreviations
    hostPoolName: hostPoolName
    hostPoolResourceGroupName: resourceGroupControlPlane
    limitSecondsToForceLogOffUser: scalingLimitSecondsToForceLogOffUser
    location: location
    minimumNumberOfRdsh: scalingMinimumNumberOfRdsh
    namingConvention: namingConvention
    privateDnsZoneResourceIdPrefix: privateDnsZoneResourceIdPrefix
    privateDnsZones: privateDnsZones
    sessionHostsResourceGroupName: resourceGroupHosts
    sessionThresholdPerCPU: scalingSessionThresholdPerCPU
    subnetResourceId: subnetResourceId
    tags: tagsAutomationAccounts
    timeDifference: timeDifference
    serviceToken: serviceToken
  }
  dependsOn: [
    recoveryServices
  ]
}
