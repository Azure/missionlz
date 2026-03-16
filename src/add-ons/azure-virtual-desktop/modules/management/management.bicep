targetScope = 'subscription'

param avdObjectId string
param delimiter string
param deploymentNameSuffix string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableApplicationInsights bool
param enableAvdInsights bool
param environmentAbbreviation string
param fslogixStorageService string
param locationControlPlane string
param locationVirtualMachines string
param logAnalyticsWorkspaceRetention int
param logAnalyticsWorkspaceSku string
param mlzTags object
param organizationalUnitPath string
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string
param resourceAbbreviations object
param stampIndex int
param tags object
param tier object
param tokens object
@secure()
param virtualMachineAdminPassword string
param virtualMachineAdminUsername string
param virtualMachineSize string

var hostPoolResourceId = resourceId(subscription().subscriptionId, resourceGroupManagement, 'Microsoft.DesktopVirtualization/hostpools', replace(tier.namingConvention.hostPool, '${delimiter}${tokens.purpose}', ''))
var resourceGroupManagement = replace(tier.namingConvention.resourceGroup, tokens.purpose, 'management')
var resourceGroupFslogix = replace(tier.namingConvention.resourceGroup, tokens.purpose, 'fslogix')

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupManagement
  location: locationControlPlane
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with a Data Collection Rule 
module monitoring 'monitoring.bicep' = if (enableApplicationInsights || enableAvdInsights) {
  name: 'deploy-monitoring-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    enableAvdInsights: enableAvdInsights
    hostPoolResourceId: hostPoolResourceId
    location: locationVirtualMachines
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    mlzTags: mlzTags
    names: tier.namingConvention
    privateLinkScopeResourceId: privateLinkScopeResourceId
    stampIndex: stampIndex
    tags: tags
    tokens: tokens
  }
}

/* module recoveryServicesVault 'recoveryServicesVault.bicep' = if (recoveryServices) {
  name: 'deploy-rsv-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    azureBlobsPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
    azureQueueStoragePrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'queue'))[0]}'
    deployFslogix: deployFslogix
    hostPoolResourceId: hostPool.outputs.resourceId
    location: locationVirtualMachines
    mlzTags: mlzTags
    recoveryServicesPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => startsWith(name, 'privatelink.${recoveryServicesGeo}.backup.windowsazure'))[0]}'
    recoveryServicesVaultName: replace(tier.namingConvention.recoveryServicesVault, '${delimiter}${tokens.purpose}', '')
    recoveryServicesVaultNetworkInterfaceName: replace(tier.namingConvention.recoveryServicesVaultNetworkInterface, '${delimiter}${tokens.purpose}', '')
    recoveryServicesVaultPrivateEndpointName: replace(tier.namingConvention.recoveryServicesVaultPrivateEndpoint, '${delimiter}${tokens.purpose}', '')
    storageService: storageService
    subnetId: subnetResourceId
    tags: tags
    timeZone: timeZone
  }
} */

module deploymentUserAssignedIdentity 'user-assigned-identity.bicep' = {
  scope: resourceGroup
  name: 'deploy-id-deployment-${deploymentNameSuffix}'
  params: {
    location: locationVirtualMachines
    name: replace(tier.namingConvention.userAssignedIdentity, tokens.purpose, 'deployment')
    tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}, mlzTags)
  }
}

// Role Assignment for Autoscale
// Purpose: assigns the Desktop Virtualization Power On Off Contributor role to the 
// Azure Virtual Desktop service to scale the host pool
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(avdObjectId, '40c5ff49-9181-41f8-ae61-143b0e78555e', subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '40c5ff49-9181-41f8-ae61-143b0e78555e')
    principalId: avdObjectId
  }
}

// Role Assignment for the AVD host pool
// Purpose: assigns the Desktop Virtualization Contributor role to the managed identity on the 
// management virtual machine to set the drain mode on the AVD session hosts and manage the scaling plan
module roleAssignment_Management '../common/role-assignments/resource-group.bicep' = {
  name: 'assign-role-mgmt-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '082f0a83-3be5-4ba1-904c-961cca79b387'
  }
}

module diskAccess 'disk-access.bicep' = {
  scope: resourceGroup
  name: 'deploy-disk-access-${deploymentNameSuffix}'
  params: {
    azureBlobsPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
    delimiter: delimiter
    hostPoolResourceId: hostPoolResourceId
    location: locationVirtualMachines
    mlzTags: mlzTags
    names: tier.namingConvention
    subnetResourceId: tier.subnets[0].id
    tags: tags
    tokens: tokens
  }
}

// Sets an Azure policy to disable public network access to managed disks
module policy 'policy.bicep' = {
  name: 'deploy-policy-disks-${deploymentNameSuffix}'
  params: {
    diskAccessResourceId: diskAccess.outputs.resourceId
  }
}

// Sets an Azure policy to disable public network access to managed disks
module policyAssignment 'policy-assignment.bicep' = {
  name: 'assign-policy-diskAccess-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    diskAccessResourceId: diskAccess.outputs.resourceId
    location: resourceGroup.location
    policyDefinitionId: policy.outputs.policyDefinitionId
    policyDisplayName: policy.outputs.policyDisplayName
    policyName: policy.outputs.policyDisplayName
  }
}

module customerManagedKeys '../../../../modules/customer-managed-keys.bicep' = {
  name: 'deploy-cmk-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: replace(tier.namingConvention.diskEncryptionSet, tokens.purpose, 'cmk')
    keyVaultPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'vaultcore'))[0]}'
    location: locationVirtualMachines
    resourceAbbreviations: resourceAbbreviations
    subnetResourceId: tier.subnets[0].id
    tags: tags
    tier: tier
    tokens: tokens
    type: 'virtualMachine'
  }
}

// Management Virtual Machine
// Purpose: deploys the management VM which is used to execute PowerShell scripts.
module virtualMachine 'virtual-machine.bicep' = {
  name: 'deploy-mgmt-vm-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentity.outputs.principalId
    deploymentUserAssignedIdentityResourceId: deploymentUserAssignedIdentity.outputs.resourceId
    diskEncryptionSetResourceId: customerManagedKeys.outputs.diskEncryptionSetResourceId
    diskName: replace(tier.namingConvention.virtualMachineDisk, tokens.purpose, 'mgt')
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    hostPoolResourceId: hostPoolResourceId
    location: locationVirtualMachines
    mlzTags: mlzTags
    networkInterfaceName: replace(tier.namingConvention.virtualMachineNetworkInterface, tokens.purpose, 'mgt')
    organizationalUnitPath: organizationalUnitPath
    subnetResourceId: tier.subnets[0].id
    tags: tags
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineName: replace(tier.namingConvention.virtualMachine, tokens.purpose, 'mgt')
    virtualMachineSize: virtualMachineSize
  }
}

// Deploys the Auto Increase Premium File Share Quota solution on an Azure Function App
module functionApp 'function-app.bicep' = if (fslogixStorageService == 'AzureFiles Premium') {
  name: 'deploy-function-app-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    delegatedSubnetResourceId: filter(tier.subnets, subnet => contains(subnet.name, 'function-app-outbound'))[0].id
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    enableApplicationInsights: enableApplicationInsights
    environmentAbbreviation: environmentAbbreviation
    hostPoolResourceId: hostPoolResourceId
    logAnalyticsWorkspaceResourceId: enableApplicationInsights || enableAvdInsights ? monitoring!.outputs.logAnalyticsWorkspaceResourceId : ''
    mlzTags: mlzTags
    names: tier.namingConvention
    privateDnsZoneResourceIdPrefix: privateDnsZoneResourceIdPrefix
    privateDnsZones: privateDnsZones
    privateLinkScopeResourceId: privateLinkScopeResourceId
    resourceGroupFslogix: resourceGroupFslogix
    stampIndex: stampIndex
    subnetResourceId: tier.subnets[0].id
    tags: tags
    tokens: tokens
  }
}

output dataCollectionRuleResourceId string = enableAvdInsights ? monitoring!.outputs.dataCollectionRuleResourceId : ''
output deploymentUserAssignedIdentityClientId string = deploymentUserAssignedIdentity.outputs.clientId
output deploymentUserAssignedIdentityPrincipalId string = deploymentUserAssignedIdentity.outputs.principalId
output deploymentUserAssignedIdentityResourceId string = deploymentUserAssignedIdentity.outputs.resourceId
output diskAccessPolicyDefinitionId string = policy.outputs.policyDefinitionId
output diskAccessPolicyDisplayName string = policy.outputs.policyDisplayName
output diskAccessResourceId string = diskAccess.outputs.resourceId
output diskEncryptionSetResourceId string = customerManagedKeys.outputs.diskEncryptionSetResourceId
output encryptionUserAssignedIdentityResourceId string = customerManagedKeys.outputs.userAssignedIdentityResourceId
output functionAppPrincipalId string = fslogixStorageService == 'AzureFiles Premium' ? functionApp!.outputs.functionAppPrincipalId : ''
output keyVaultName string = customerManagedKeys.outputs.keyVaultName
output keyVaultUri string = customerManagedKeys.outputs.keyVaultUri
output logAnalyticsWorkspaceName string = enableApplicationInsights || enableAvdInsights ? monitoring!.outputs.logAnalyticsWorkspaceName : ''
output logAnalyticsWorkspaceResourceId string = enableApplicationInsights || enableAvdInsights ? monitoring!.outputs.logAnalyticsWorkspaceResourceId : ''
output resourceGroupName string = resourceGroup.name
output virtualMachineName string = virtualMachine.outputs.name
output virtualMachineResourceId string = virtualMachine.outputs.resourceId
