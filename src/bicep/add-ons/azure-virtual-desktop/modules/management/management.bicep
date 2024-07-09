targetScope = 'subscription'

param activeDirectorySolution string
param artifactsUri string
param artifactsStorageAccountResourceId string
param avdObjectId string
param azurePowerShellModuleMsiName string
param deploymentNameSuffix string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableMonitoring bool
param deployFslogix bool
param diskEncryptionSetResourceId string
param fslogixStorageService string
param hostPoolType string
param locationVirtualMachines string
param logAnalyticsWorkspaceRetention int
param logAnalyticsWorkspaceSku string
param mlzTags object
param namingConvention object
param organizationalUnitPath string
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param recoveryServices bool
param recoveryServicesGeo string
param resourceGroupControlPlane string
param resourceGroupFeedWorkspace string
param resourceGroupHosts string
param resourceGroupManagement string
param resourceGroupStorage string
param roleDefinitions object
param scalingTool bool
param serviceToken string
param storageService string
param subnetResourceId string
param tags object
param timeZone string
@secure()
param virtualMachinePassword string
param virtualMachineUsername string

var hostPoolName = namingConvention.hostPool
var roleAssignments = union([
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
], deployFslogix ? [
  {
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor (Purpose: domain join storage account & set NTFS permissions on the file share)
    resourceGroup: resourceGroupStorage
    subscription: subscription().subscriptionId
  }
] : [])
var userAssignedIdentityNamePrefix = namingConvention.userAssignedIdentity
var virtualNetworkName = split(subnetResourceId, '/')[8]
var virtualNetworkResourceGroupName = split(subnetResourceId, '/')[4]

// Disabling the deployment below until Enhanced Policies in Recovery Services support managed disks with private link
/* module diskAccess 'diskAccess.bicep' = {
  scope: resourceGroup(resourceGroupManagement)
  name: 'DiskAccess_${timestamp}'
  params: {
    diskAccessName: namingConvention.diskAccess
    hostPoolName: hostPoolName
    location: locationVirtualMachines
    mlzTags: mlzTags
    resourceGroupControlPlane: resourceGroupControlPlane
    subnetResourceId: subnetResourceId
    tags: tags
  }
} */

// Sets an Azure policy to disable public network access to managed disks
// Once Enhanced Policies in Recovery Services support managed disks with private link, remove the "if" condition
module policy 'policy.bicep' = if (contains(hostPoolType, 'Pooled') && recoveryServices) {
  name: 'deploy-policy-disks-${deploymentNameSuffix}'
  params: {
    // Disabling the param below until Enhanced Policies in Recovery Services support managed disks with private link
    //diskAccessResourceId: diskAccess.outputs.resourceId
    location: locationVirtualMachines
    resourceGroupName: resourceGroupHosts
  }
}

module deploymentUserAssignedIdentity 'userAssignedIdentity.bicep' = {
  scope: resourceGroup(resourceGroupManagement)
  name: 'deploy-id-deployment-${deploymentNameSuffix}'
  params: {
    location: locationVirtualMachines
    name: replace(userAssignedIdentityNamePrefix, serviceToken, 'deployment')
    tags: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
    }, contains(tags, 'Microsoft.ManagedIdentity/userAssignedIdentities') ? tags['Microsoft.ManagedIdentity/userAssignedIdentities'] : {}, mlzTags)
  }
}

module roleAssignments_deployment '../common/roleAssignment.bicep' = [for i in range(0, length(roleAssignments)): {
  scope: resourceGroup(roleAssignments[i].subscription, roleAssignments[i].resourceGroup)
  name: 'deploy-role-assignment-${i}-${deploymentNameSuffix}'
  params: {
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleAssignments[i].roleDefinitionId
  }
}]

// Role Assignment for Validation
// This role assignment is required to collect validation information
resource roleAssignment_validation 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(replace(userAssignedIdentityNamePrefix, serviceToken, 'deployment'), roleDefinitions.Reader, subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.Reader)
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// Management VM
// The management VM is required to execute PowerShell scripts.
module virtualMachine 'virtualMachine.bicep' = {
  name: 'deploy-mgmt-vm-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    artifactsUri: artifactsUri
    azurePowerShellModuleMsiName: azurePowerShellModuleMsiName
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentity.outputs.clientId
    deploymentUserAssignedIdentityResourceId: deploymentUserAssignedIdentity.outputs.resourceId
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskName: replace(namingConvention.virtualMachineDisk, serviceToken, 'mgt')
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    hostPoolName: hostPoolName
    location: locationVirtualMachines
    mlzTags: mlzTags
    networkInterfaceName: replace(namingConvention.virtualMachineNetworkInterface, serviceToken, 'mgt')
    organizationalUnitPath: organizationalUnitPath
    resourceGroupControlPlane: resourceGroupControlPlane
    subnet: split(subnetResourceId, '/')[10]
    tags: tags
    virtualMachineName: replace(namingConvention.virtualMachine, serviceToken, 'mgt')
    virtualMachinePassword: virtualMachinePassword
    virtualMachineUsername: virtualMachineUsername
    virtualNetwork: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
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
  name: 'deploy-monitoring-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    dataCollectionRuleName: namingConvention.dataCollectionRule
    hostPoolName: hostPoolName
    location: locationVirtualMachines
    logAnalyticsWorkspaceName: namingConvention.logAnalyticsWorkspace
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    mlzTags: mlzTags
    resourceGroupControlPlane: resourceGroupControlPlane
    tags: tags
  }
}

// Automation Account required for the AVD Scaling Tool and the Auto Increase Premium File Share Quota solution
module automationAccount 'automationAccount.bicep' = if (scalingTool || fslogixStorageService == 'AzureFiles Premium') {
  name: 'deploy-aa-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    automationAccountDiagnosticSettingName: namingConvention.automationAccountDiagnosticSetting
    automationAccountName: namingConvention.automationAccount
    automationAccountNetworkInterfaceName: namingConvention.automationAccountNetworkInterface
    automationAccountPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => startsWith(name, 'privatelink.azure-automation'))[0]}'
    automationAccountPrivateEndpointName: namingConvention.automationAccountPrivateEndpoint
    hostPoolName: hostPoolName
    location: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: enableMonitoring ? monitoring.outputs.logAnalyticsWorkspaceResourceId : ''
    mlzTags: mlzTags
    monitoring: enableMonitoring
    resourceGroupControlPlane: resourceGroupControlPlane
    subnetResourceId: subnetResourceId
    tags: tags
    virtualMachineName: virtualMachine.outputs.Name
  }
}

module recoveryServicesVault 'recoveryServicesVault.bicep' = if (recoveryServices && ((contains(activeDirectorySolution, 'DomainServices') && contains(hostPoolType, 'Pooled') && contains(fslogixStorageService, 'AzureFiles')) || contains(hostPoolType, 'Personal'))) {
  name: 'deploy-rsv-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    azureBlobsPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
    azureQueueStoragePrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'queue'))[0]}'
    deployFslogix: deployFslogix
    hostPoolName: hostPoolName
    location: locationVirtualMachines
    mlzTags: mlzTags
    recoveryServicesPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => startsWith(name, 'privatelink.${recoveryServicesGeo}.backup.windowsazure'))[0]}'
    recoveryServicesVaultName: namingConvention.recoveryServicesVault
    recoveryServicesVaultNetworkInterfaceName: namingConvention.recoveryServicesVaultNetworkInterface
    recoveryServicesVaultPrivateEndpointName: namingConvention.recoveryServicesVaultPrivateEndpoint
    resourceGroupControlPlane: resourceGroupControlPlane
    storageService: storageService
    subnetId: subnetResourceId
    tags: tags
    timeZone: timeZone
  }
}

output automationAccountName string = scalingTool || fslogixStorageService == 'AzureFiles Premium' ? automationAccount.outputs.name : ''
output dataCollectionRuleResourceId string = enableMonitoring ? monitoring.outputs.dataCollectionRuleResourceId : ''
output deploymentUserAssignedIdentityClientId string = deploymentUserAssignedIdentity.outputs.clientId
output deploymentUserAssignedIdentityPrincipalId string = deploymentUserAssignedIdentity.outputs.principalId
output deploymentUserAssignedIdentityResourceId string = deploymentUserAssignedIdentity.outputs.resourceId
output hybridRunbookWorkerGroupName string = scalingTool || fslogixStorageService == 'AzureFiles Premium' ? automationAccount.outputs.hybridRunbookWorkerGroupName : ''
output logAnalyticsWorkspaceName string = enableMonitoring ? monitoring.outputs.logAnalyticsWorkspaceName : ''
output logAnalyticsWorkspaceResourceId string = enableMonitoring ? monitoring.outputs.logAnalyticsWorkspaceResourceId : ''
output recoveryServicesVaultName string = recoveryServices && ((contains(activeDirectorySolution, 'DomainServices') && contains(hostPoolType, 'Pooled') && contains(fslogixStorageService, 'AzureFiles')) || contains(hostPoolType, 'Personal')) ? recoveryServicesVault.outputs.name : ''
output virtualMachineName string = virtualMachine.outputs.Name
