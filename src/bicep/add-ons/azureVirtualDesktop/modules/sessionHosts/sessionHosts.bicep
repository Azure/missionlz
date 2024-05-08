targetScope = 'subscription'

param acceleratedNetworking string
param activeDirectorySolution string
param artifactsUri string
param artifactsUserAssignedIdentityClientId string
param artifactsUserAssignedIdentityResourceId string
param automationAccountName string
param availability string
param availabilitySetNamePrefix string
param availabilitySetsCount int
param availabilitySetsIndex int
param availabilityZones array
param avdAgentBootLoaderMsiName string
param avdAgentMsiName string
param dataCollectionRuleAssociationName string
param dataCollectionRuleResourceId string
param deploymentUserAssignedIdentityClientId string
param diskEncryptionSetResourceId string
param diskNamePrefix string
param diskSku string
param divisionRemainderValue int
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param drainMode bool
param fslogix bool
param fslogixContainerType string
param hostPoolName string
param hostPoolType string
param hybridRunbookWorkerGroupName string
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersionResourceId string
param location string
param logAnalyticsWorkspaceName string
param managementVirtualMachineName string
param maxResourcesPerTemplateDeployment int
param monitoring bool
param netAppFileShares array
param networkInterfaceNamePrefix string
param networkName string
param organizationalUnitPath string
param pooledHostPool bool
param enableRecoveryServices bool
param enableScalingTool bool
param recoveryServicesVaultName string
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
param securityLogAnalyticsWorkspaceResourceId string
param serviceName string
param sessionHostBatchCount int
param sessionHostIndex int
param storageAccountPrefix string
param storageCount int
param storageIndex int
param storageService string
param storageSuffix string
param subnet string
param tags object
param timeDifference string
param timestamp string
param timeZone string
param virtualMachineMonitoringAgent string
param virtualMachineNamePrefix string
@secure()
param virtualMachinePassword string
param virtualMachineSize string
param virtualMachineUsername string
param virtualNetwork string
param virtualNetworkResourceGroup string

var tagsAutomationAccounts = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Automation/automationAccounts') ? tags['Microsoft.Automation/automationAccounts'] : {})
var tagsAvailabilitySets = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Compute/availabilitySets') ? tags['Microsoft.Compute/availabilitySets'] : {})
var tagsNetworkInterfaces = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Network/networkInterfaces') ? tags['Microsoft.Network/networkInterfaces'] : {})
var tagsRecoveryServicesVault = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.recoveryServices/vaults') ? tags['Microsoft.recoveryServices/vaults'] : {})
var tagsVirtualMachines = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {})

module availabilitySets 'availabilitySets.bicep' = if (pooledHostPool && availability == 'availabilitySets') {
  name: 'availabilitySets_${timestamp}'
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
  name: 'RoleAssignments_${i}_${timestamp}'
  scope: resourceGroup(resourceGroupHosts)
  params: {
    PrincipalId: securityPrincipalObjectIds[i]
    PrincipalType: 'Group'
    RoleDefinitionId: roleDefinitions.VirtualMachineUserLogin
  }
}]

@batchSize(1)
module virtualMachines 'virtualMachines.bicep' = [for i in range(1, sessionHostBatchCount): {
  name: 'VirtualMachines_${i - 1}_${timestamp}'
  scope: resourceGroup(resourceGroupHosts)
  params: {
    acceleratedNetworking: acceleratedNetworking
    activeDirectorySolution: activeDirectorySolution
    artifactsUri: artifactsUri
    artifactsUserAssignedIdentityClientId: artifactsUserAssignedIdentityClientId
    artifactsUserAssignedIdentityResourceId: artifactsUserAssignedIdentityResourceId
    availability: availability
    availabilitySetNamePrefix: availabilitySetNamePrefix
    availabilityZones: availabilityZones
    avdAgentBootLoaderMsiName: avdAgentBootLoaderMsiName
    avdAgentMsiName: avdAgentMsiName
    batchCount: i
    dataCollectionRuleAssociationName: dataCollectionRuleAssociationName
    dataCollectionRuleResourceId: dataCollectionRuleResourceId
    deploymentUserAssignedidentityClientId: deploymentUserAssignedIdentityClientId
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskNamePrefix: diskNamePrefix
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    enableDrainMode: drainMode
    fslogix: fslogix
    fslogixContainerType: fslogixContainerType
    hostPoolName: hostPoolName
    hostPoolType: hostPoolType
    imageVersionResourceId: imageVersionResourceId
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imageSku: imageSku
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    managementVirtualMachineName: managementVirtualMachineName
    monitoring: monitoring
    netAppFileShares: netAppFileShares
    networkInterfaceNamePrefix: networkInterfaceNamePrefix
    networkName: networkName
    organizationalUnitPath: organizationalUnitPath
    resourceGroupControlPlane: resourceGroupControlPlane
    resourceGroupManagement: resourceGroupManagement
    securityLogAnalyticsWorkspaceResourceId: securityLogAnalyticsWorkspaceResourceId
    serviceName: serviceName
    sessionHostCount: i == sessionHostBatchCount && divisionRemainderValue > 0 ? divisionRemainderValue : maxResourcesPerTemplateDeployment
    sessionHostIndex: i == 1 ? sessionHostIndex : ((i - 1) * maxResourcesPerTemplateDeployment) + sessionHostIndex
    storageAccountPrefix: storageAccountPrefix
    storageCount: storageCount
    storageIndex: storageIndex
    storageService: storageService
    storageSuffix: storageSuffix
    subnet: subnet
    tagsNetworkInterfaces: tagsNetworkInterfaces
    tagsVirtualMachines: tagsVirtualMachines
    timestamp: timestamp
    virtualMachineMonitoringAgent: virtualMachineMonitoringAgent
    virtualMachineNamePrefix: virtualMachineNamePrefix
    virtualMachinePassword: virtualMachinePassword
    virtualMachineSize: virtualMachineSize
    virtualMachineUsername: virtualMachineUsername
    virtualNetwork: virtualNetwork
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
  }
  dependsOn: [
    availabilitySets
  ]
}]

module recoveryServices 'recoveryServices.bicep' = if (enableRecoveryServices && contains(hostPoolType, 'Personal')) {
  name: 'RecoveryServices_VirtualMachines_${timestamp}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    divisionRemainderValue: divisionRemainderValue
    fslogix: fslogix
    location: location
    maxResourcesPerTemplateDeployment: maxResourcesPerTemplateDeployment
    recoveryServicesVaultName: recoveryServicesVaultName
    resourceGroupHosts: resourceGroupHosts
    resourceGroupManagement: resourceGroupManagement
    sessionHostBatchCount: sessionHostBatchCount
    sessionHostIndex: sessionHostIndex
    tagsRecoveryServicesVault: tagsRecoveryServicesVault
    timestamp: timestamp
    virtualMachineNamePrefix: virtualMachineNamePrefix
  }
  dependsOn: [
    virtualMachines
  ]
}

module scalingTool '../management/scalingTool.bicep' = if (enableScalingTool && pooledHostPool) {
  name: 'ScalingTool_${timestamp}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    artifactsUri: artifactsUri
    automationAccountName: automationAccountName
    beginPeakTime: scalingBeginPeakTime
    endPeakTime: scalingEndPeakTime
    hostPoolName: hostPoolName
    hostPoolResourceGroupName: resourceGroupControlPlane
    hybridRunbookWorkerGroupName: hybridRunbookWorkerGroupName
    limitSecondsToForceLogOffUser: scalingLimitSecondsToForceLogOffUser
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    minimumNumberOfRdsh: scalingMinimumNumberOfRdsh
    resourceGroupControlPlane: resourceGroupControlPlane
    resourceGroupHosts: resourceGroupHosts
    sessionThresholdPerCPU: scalingSessionThresholdPerCPU
    tags: tagsAutomationAccounts
    timeDifference: timeDifference
    timestamp: timestamp
    timeZone: timeZone
    userAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
  }
  dependsOn: [
    recoveryServices
  ]
}
