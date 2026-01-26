targetScope = 'subscription'

param avdObjectId string
param deploymentNameSuffix string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param environmentAbbreviation string
param locationControlPlane string
param locationVirtualMachines string
param mlzTags object
param organizationalUnitPath string
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param resourceAbbreviations object
param tags object
param tier object
param tokens object
@secure()
param virtualMachineAdminPassword string
param virtualMachineAdminUsername string
param virtualMachineSize string

var hostPoolResourceId = resourceId(subscription().subscriptionId, resourceGroupManagement, 'Microsoft.DesktopVirtualization/hostpools', replace(tier.namingConvention.hostPool, tokens.purpose, ''))
var resourceGroupManagement = replace(tier.namingConvention.resourceGroup, tokens.purpose, 'management')

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupManagement
  location: locationControlPlane
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
}

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
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: replace(tier.namingConvention.diskEncryptionSet, tokens.purpose, 'cmk')
    keyVaultPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'vaultcore'))[0]}'
    location: locationVirtualMachines
    mlzTags: mlzTags
    resourceAbbreviations: resourceAbbreviations
    resourceGroupName: resourceGroup.name
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

output deploymentUserAssignedIdentityClientId string = deploymentUserAssignedIdentity.outputs.clientId
output deploymentUserAssignedIdentityPrincipalId string = deploymentUserAssignedIdentity.outputs.principalId
output deploymentUserAssignedIdentityResourceId string = deploymentUserAssignedIdentity.outputs.resourceId
output diskAccessPolicyDefinitionId string = policy.outputs.policyDefinitionId
output diskAccessPolicyDisplayName string = policy.outputs.policyDisplayName
output diskAccessResourceId string = diskAccess.outputs.resourceId
output diskEncryptionSetResourceId string = customerManagedKeys.outputs.diskEncryptionSetResourceId
output encryptionUserAssignedIdentityResourceId string = customerManagedKeys.outputs.userAssignedIdentityResourceId
output keyVaultName string = customerManagedKeys.outputs.keyVaultName
output keyVaultUri string = customerManagedKeys.outputs.keyVaultUri
output resourceGroupName string = resourceGroup.name
output virtualMachineName string = virtualMachine.outputs.name
output virtualMachineResourceId string = virtualMachine.outputs.resourceId
