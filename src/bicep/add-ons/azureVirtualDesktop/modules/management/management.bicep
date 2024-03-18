targetScope = 'subscription'

param activeDirectorySolution string
param artifactsUri string
param artifactsStorageAccountResourceId string
param automationAccountDiagnosticSettingName string
param automationAccountName string
param automationAccountNetworkInterfaceName string
param automationAccountPrivateDnsZoneResourceId string
param automationAccountPrivateEndpointName string
param availability string
param avdObjectId string
param azureBlobsPrivateDnsZoneResourceId string
param azurePowerShellModuleMsiName string
param azureQueueStoragePrivateDnsZoneResourceId string
param dataCollectionRuleName string
//param diskAccessName string
param diskNamePrefix string
param diskEncryptionSetName string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableMonitoring bool
param environmentAbbreviation string
param fslogix bool
param fslogixStorageService string
param hostPoolName string
param hostPoolType string
param imageDefinitionResourceId string
param keyVaultName string
param keyVaultNetworkInterfaceName string
param keyVaultPrivateDnsZoneResourceId string
param keyVaultPrivateEndpointName string
param locationVirtualMachines string
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceRetention int
param logAnalyticsWorkspaceSku string
param networkInterfaceNamePrefix string
param networkName string
param organizationalUnitPath string
param recoveryServices bool
param recoveryServicesPrivateDnsZoneResourceId string
param recoveryServicesVaultName string
param recoveryServicesVaultNetworkInterfaceName string
param recoveryServicesVaultPrivateEndpointName string
param resourceGroupControlPlane string
param resourceGroupFeedWorkspace string
param resourceGroupHosts string
param resourceGroupManagement string
param resourceGroupStorage string
param roleDefinitions object
param scalingTool bool
param securityLogAnalyticsWorkspaceResourceId string
param serviceName string
param sessionHostCount int
param storageService string
param subnetResourceId string
param tags object
param timestamp string
param timeZone string
param userAssignedIdentityNamePrefix string
param virtualMachineMonitoringAgent string
param virtualMachineNamePrefix string
@secure()
param virtualMachinePassword string
param virtualMachineUsername string
param virtualMachineSize string
param workspaceFeedName string

var CpuCountMax = contains(hostPoolType, 'Pooled') ? 32 : 128
var CpuCountMin = contains(hostPoolType, 'Pooled') ? 4 : 2
var roleAssignments = union(roleAssignmentsCommon, roleAssignmentStorage)
var roleAssignmentsCommon = [
  {
    roleDefinitionId: 'f353d9bd-d4a6-484e-a77a-8050b599b867' // Automation Contributor (Purpose: adds runbook to automation account)
    resourceGroup: resourceGroupManagement
    subscription: subscription().subscriptionId
  }
  {
    roleDefinitionId: '86240b0e-9422-4c43-887b-b61143f32ba8' // Desktop Virtualization Application Group Contributor (Purpose: updates the friendly name for the desktop)
    resourceGroup: resourceGroupControlPlane
    subscription: subscription().subscriptionId
  }
  {
    roleDefinitionId: '2ad6aaab-ead9-4eaa-8ac5-da422f562408' // Desktop Virtualization Session Host Operator (Purpose: sets drain mode on the AVD session hosts)
    resourceGroup: resourceGroupControlPlane
    subscription: subscription().subscriptionId
  }
  {
    roleDefinitionId: 'a959dbd1-f747-45e3-8ba6-dd80f235f97c' // Desktop Virtualization Virtual Machine Contributor (Purpose: remove the management virtual machine)
    resourceGroup: resourceGroupManagement
    subscription: subscription().subscriptionId
  }
  {
    roleDefinitionId: '21efdde3-836f-432b-bf3d-3e8e734d4b2b' // Desktop Virtualization Workspace Contributor (Purpose: update the app group references on an existing feed workspace)
    resourceGroup: resourceGroupFeedWorkspace
    subscription: subscription().subscriptionId
  }
  {
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader
    resourceGroup: split(artifactsStorageAccountResourceId, '/')[4]
    subscription: split(artifactsStorageAccountResourceId, '/')[2]
  }
]
var roleAssignmentStorage = fslogix ? [
  {
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor (Purpose: domain join storage account & set NTFS permissions on the file share)
    resourceGroup: resourceGroupStorage
    subscription: subscription().subscriptionId
  }
] : []
var VirtualNetworkName = split(subnetResourceId, '/')[8]
var VirtualNetworkResourceGroupName = split(subnetResourceId, '/')[4]

// Disabling the deployment below until Enhanced Policies in Recovery Services support managed disks with private link
/* module diskAccess 'diskAccess.bicep' = {
  scope: resourceGroup(resourceGroupManagement)
  name: 'DiskAccess_${timestamp}'
  params: {
    diskAccessName: diskAccessName
    location: locationVirtualMachines
    subnetResourceId: subnetResourceId
    tags: tags
  }
} */

// Sets an Azure policy to disable public network access to managed disks
// Once Enhanced Policies in Recovery Services support managed disks with private link, remove the "if" condition
module policy 'policy.bicep' = if (contains(hostPoolType, 'Pooled') && recoveryServices) {
  name: 'Policy_${timestamp}'
  params: {
    // Disabling the param below until Enhanced Policies in Recovery Services support managed disks with private link
    //diskAccessResourceId: diskAccess.outputs.resourceId
    location: locationVirtualMachines
    resourceGroupName: resourceGroupHosts
  }
}

module deploymentUserAssignedIdentity 'userAssignedIdentity.bicep' = {
  scope: resourceGroup(resourceGroupManagement)
  name: 'UserAssignedIdentity_${timestamp}'
  params: {
    location: locationVirtualMachines
    name: replace(userAssignedIdentityNamePrefix, serviceName, 'deployment')
    tags: contains(tags, 'Microsoft.ManagedIdentity/userAssignedIdentities') ? tags['Microsoft.ManagedIdentity/userAssignedIdentities'] : {}
  }
}

module roleAssignments_deployment '../common/roleAssignment.bicep' = [for i in range(0, length(roleAssignments)): {
  scope: resourceGroup(roleAssignments[i].subscription, roleAssignments[i].resourceGroup)
  name: 'RoleAssignment_${i}_${timestamp}'
  params: {
    PrincipalId: deploymentUserAssignedIdentity.outputs.principalId
    PrincipalType: 'ServicePrincipal'
    RoleDefinitionId: roleAssignments[i].roleDefinitionId
  }
}]

// Role Assignment for Validation
// This role assignment is required to collect validation information
resource roleAssignment_validation 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${userAssignedIdentityNamePrefix}-deployment', roleDefinitions.Reader, subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.Reader)
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

module artifacts 'artifacts.bicep' = {
  scope: resourceGroup(split(artifactsStorageAccountResourceId, '/')[2], split(artifactsStorageAccountResourceId, '/')[4])
  name: 'Artifacts_${timestamp}'
  params: {
    location: locationVirtualMachines
    resourceGroupManagement: resourceGroupManagement
    serviceName: serviceName
    storageAccountName: split(artifactsStorageAccountResourceId, '/')[8]
    subscriptionId: subscription().subscriptionId
    tags: tags
    timestamp: timestamp
    userAssignedIdentityNamePrefix: userAssignedIdentityNamePrefix
  }
}

// Deploys the prerequisites to enable customer managed keys on storage accounts and managed disks
module customerManagedKeys 'customerManagedKeys.bicep' = {
  name: 'CustomerManagedKeys_${timestamp}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    environment: environmentAbbreviation
    keyVaultName: keyVaultName
    keyVaultNetworkInterfaceName: keyVaultNetworkInterfaceName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    keyVaultPrivateEndpointName: keyVaultPrivateEndpointName
    location: locationVirtualMachines
    serviceName: serviceName
    subnetResourceId: subnetResourceId
    tags: tags
    timestamp: timestamp
    userAssignedIdentityNamePrefix: userAssignedIdentityNamePrefix
  }
}

module diskEncryptionSet 'diskEncryptionSet.bicep' = {
  name: 'DiskEncryptionSet_${timestamp}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    diskEncryptionSetName: diskEncryptionSetName
    keyUrl: customerManagedKeys.outputs.keyUriWithVersion
    keyVaultResourceId: customerManagedKeys.outputs.keyVaultResourceId
    location: locationVirtualMachines
    tags: contains(tags, 'Microsoft.Compute/diskEncryptionSets') ? tags['Microsoft.Compute/diskEncryptionSets'] : {}
    timestamp: timestamp 
  }
}

// Management VM
// The management VM is required to validate the deployment and configure FSLogix storage.
module virtualMachine 'virtualMachine.bicep' = {
  name: 'ManagementVirtualMachine_${timestamp}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    artifactsUri: artifactsUri
    azurePowerShellModuleMsiName: azurePowerShellModuleMsiName
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentity.outputs.clientId
    deploymentUserAssignedIdentityResourceId: deploymentUserAssignedIdentity.outputs.resourceId
    diskEncryptionSetResourceId: diskEncryptionSet.outputs.resourceId
    diskNamePrefix: diskNamePrefix
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    location: locationVirtualMachines
    networkInterfaceNamePrefix: networkInterfaceNamePrefix
    networkName: networkName
    organizationalUnitPath: organizationalUnitPath
    securityLogAnalyticsWorkspaceResourceId: securityLogAnalyticsWorkspaceResourceId
    serviceName: serviceName
    subnet: split(subnetResourceId, '/')[10]
    tagsNetworkInterfaces: contains(tags, 'Microsoft.Network/networkInterfaces') ? tags['Microsoft.Network/networkInterfaces'] : {}
    tagsVirtualMachines: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
    virtualMachineMonitoringAgent: virtualMachineMonitoringAgent
    virtualMachineNamePrefix: virtualMachineNamePrefix
    virtualMachinePassword: virtualMachinePassword
    virtualMachineUsername: virtualMachineUsername
    virtualNetwork: VirtualNetworkName
    virtualNetworkResourceGroup: VirtualNetworkResourceGroupName
  }
}

// Deployment Validations
// This module validates the selected parameter values and collects required data
module validations '../common/customScriptExtensions.bicep' = {
  scope: resourceGroup(resourceGroupManagement)
  name: 'Validations_${timestamp}'
  params: {
    fileUris: [
      '${artifactsUri}Get-Validations.ps1'
    ]
    location: locationVirtualMachines
    parameters: '-ActiveDirectorySolution ${activeDirectorySolution} -CpuCountMax ${CpuCountMax} -CpuCountMin ${CpuCountMin} -DomainName ${empty(domainName) ? 'NotApplicable' : domainName} -Environment ${environment().name} -ImageDefinitionResourceId ${empty(imageDefinitionResourceId) ? 'NotApplicable' : imageDefinitionResourceId} -Location ${locationVirtualMachines} -SessionHostCount ${sessionHostCount} -StorageService ${storageService} -SubscriptionId ${subscription().subscriptionId} -TenantId ${tenant().tenantId} -UserAssignedIdentityClientId ${deploymentUserAssignedIdentity.outputs.clientId} -VirtualMachineSize ${virtualMachineSize} -VirtualNetworkName ${VirtualNetworkName} -VirtualNetworkResourceGroupName ${VirtualNetworkResourceGroupName} -WorkspaceFeedName ${workspaceFeedName} -WorkspaceResourceGroupName ${resourceGroupFeedWorkspace}'
    scriptFileName: 'Get-Validations.ps1'
    tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
    userAssignedIdentityClientId: deploymentUserAssignedIdentity.outputs.clientId
    virtualMachineName: virtualMachine.outputs.Name
  }
}

// Role Assignment required for Start VM On Connect
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(avdObjectId, roleDefinitions.DesktopVirtualizationPowerOnContributor, subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.DesktopVirtualizationPowerOnContributor)
    principalId: avdObjectId
  }
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with either Windows Events & Windows Performance Counters or a Data Collection Rule 
module monitoring 'monitoring.bicep' = if (enableMonitoring) {
  name: 'Monitoring_${timestamp}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    dataCollectionRuleName: dataCollectionRuleName
    hostPoolName: hostPoolName
    location: locationVirtualMachines
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    resourceGroupControlPlane: resourceGroupControlPlane
    tags: tags
    virtualMachineMonitoringAgent: virtualMachineMonitoringAgent
  }
}

// Automation Account required for the AVD Scaling Tool and the Auto Increase Premium File Share Quota solution
module automationAccount 'automationAccount.bicep' = if (scalingTool || fslogixStorageService == 'AzureFiles Premium') {
  name: 'AutomationAccount_${timestamp}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    automationAccountDiagnosticSettingName: automationAccountDiagnosticSettingName
    automationAccountName: automationAccountName
    automationAccountNetworkInterfaceName: automationAccountNetworkInterfaceName
    automationAccountPrivateDnsZoneResourceId: automationAccountPrivateDnsZoneResourceId
    automationAccountPrivateEndpointName: automationAccountPrivateEndpointName
    location: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: enableMonitoring ? monitoring.outputs.logAnalyticsWorkspaceResourceId : ''
    monitoring: enableMonitoring
    subnetResourceId: subnetResourceId
    tags: contains(tags, 'Microsoft.Automation/automationAccounts') ? tags['Microsoft.Automation/automationAccounts'] : {}
    virtualMachineName: virtualMachine.outputs.Name
  }
}

module recoveryServicesVault 'recoveryServicesVault.bicep' = if (recoveryServices && ((contains(activeDirectorySolution, 'DomainServices') && contains(hostPoolType, 'Pooled') && contains(fslogixStorageService, 'AzureFiles')) || contains(hostPoolType, 'Personal'))) {
  name: 'RecoveryServicesVault_${timestamp}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    azureBlobsPrivateDnsZoneResourceId: azureBlobsPrivateDnsZoneResourceId
    fslogix: fslogix
    location: locationVirtualMachines
    azureQueueStoragePrivateDnsZoneResourceId: azureQueueStoragePrivateDnsZoneResourceId
    recoveryServicesPrivateDnsZoneResourceId: recoveryServicesPrivateDnsZoneResourceId
    recoveryServicesVaultName: recoveryServicesVaultName
    recoveryServicesVaultNetworkInterfaceName: recoveryServicesVaultNetworkInterfaceName
    recoveryServicesVaultPrivateEndpointName: recoveryServicesVaultPrivateEndpointName
    storageService: storageService
    subnetId: subnetResourceId
    tags: tags
    timeZone: timeZone
  }
}

output artifactsUserAssignedIdentityClientId string = artifacts.outputs.userAssignedIdentityClientId
output artifactsUserAssignedIdentityPrincipalId string = artifacts.outputs.userAssignedIdentityPrincipalId
output artifactsUserAssignedIdentityResourceId string = artifacts.outputs.userAssignedIdentityResourceId
output dataCollectionRuleResourceId string = enableMonitoring ? monitoring.outputs.dataCollectionRuleResourceId : ''
output deploymentUserAssignedIdentityClientId string = deploymentUserAssignedIdentity.outputs.clientId
output deploymentUserAssignedIdentityPrincipalId string = deploymentUserAssignedIdentity.outputs.principalId
output deploymentUserAssignedIdentityResourceId string = deploymentUserAssignedIdentity.outputs.resourceId
output diskEncryptionSetResourceId string = diskEncryptionSet.outputs.resourceId
output encryptionUserAssignedIdentityClientId string = customerManagedKeys.outputs.encryptionUserAssignedIdentityClientId
output encryptionUserAssignedIdentityPrincipalId string = customerManagedKeys.outputs.encryptionUserAssignedIdentityPrincipalId
output encryptionUserAssignedIdentityResourceId string = customerManagedKeys.outputs.encryptionUserAssignedIdentityResourceId
output existingFeedWorkspace bool = validations.outputs.value.existingWorkspace == 'true' ? true : false
output hybridRunbookWorkerGroupName string = scalingTool || fslogixStorageService == 'AzureFiles Premium' ? automationAccount.outputs.hybridRunbookWorkerGroupName : ''
output keyVaultUri string = customerManagedKeys.outputs.keyVaultUri
output logAnalyticsWorkspaceResourceId string = enableMonitoring ? monitoring.outputs.logAnalyticsWorkspaceResourceId : ''
output storageEncryptionKeyName string = customerManagedKeys.outputs.storageKeyName
output validateAcceleratedNetworking string = validations.outputs.value.acceleratedNetworking
output validateANFDnsServers string = validations.outputs.value.anfDnsServers
output validateANFfActiveDirectory string = validations.outputs.value.anfActiveDirectory
output validateANFSubnetId string = validations.outputs.value.anfSubnetId
output validateAvailabilityZones array = availability == 'AvailabilityZones' ? validations.outputs.value.availabilityZones : [ '1' ]
output virtualMachineName string = virtualMachine.outputs.Name
