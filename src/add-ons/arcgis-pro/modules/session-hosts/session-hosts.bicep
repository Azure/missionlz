targetScope = 'subscription'

param activeDirectorySolution string
param avdConfigurationZipFileUri string
param dataCollectionRuleResourceId string
param delimiter string
param deploymentNameSuffix string
param diskAccessPolicyDefinitionId string
param diskAccessPolicyDisplayName string
param diskAccessResourceId string
param diskEncryptionSetResourceId string
param diskSku string
param fileShare string
param hostPoolResourceId string
param imageOffer string
param imagePublisher string
param imageSku string
param location string
param mlzTags object 
param resourceGroupName string
param securityPrincipalObjectId string
param tags object
param tier object
param tokens object
@secure()
param virtualMachineAdminPassword string
param virtualMachineAdminUsername string
param virtualMachineSize string

var tagsVirtualMachines = union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)

// Sets an Azure policy to disable public network access to managed disks
module policyAssignment '../../../azure-virtual-desktop/modules/management/policy-assignment.bicep' = {
  name: 'assign-policy-diskAccess-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    diskAccessResourceId: diskAccessResourceId
    location: location
    policyDefinitionId: diskAccessPolicyDefinitionId
    policyDisplayName: diskAccessPolicyDisplayName
    policyName: diskAccessPolicyDisplayName
  }
}

// Role Assignment for Entra Joined Virtual Machines
// Purpose: assigns the Virtual Machine Login User role on the hosts resource group
// to enable the login to Entra joined virtual machines
module roleAssignments '../../../azure-virtual-desktop/modules/common/role-assignments/resource-group.bicep' = if (contains(activeDirectorySolution, 'EntraId')) {
  name: 'assign-role-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    principalId: securityPrincipalObjectId
    principalType: 'Group'
    roleDefinitionId: 'fb879df8-f326-4884-b1cf-06f3ad86be52'
  }
}

module virtualMachine 'virtual-machine.bicep' = {
  name: 'deploy-vm-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    activeDirectorySolution: activeDirectorySolution
    avdConfigurationZipFileUri: avdConfigurationZipFileUri
    dataCollectionRuleAssociationName: replace(tier.namingConvention.dataCollectionRuleAssociation, '${delimiter}${tokens.purpose}', '')
    dataCollectionRuleResourceId: dataCollectionRuleResourceId
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskNamePrefix: replace(tier.namingConvention.virtualMachineDisk, '${delimiter}${tokens.purpose}', '')
    diskSku: diskSku
    fileShare: fileShare
    hostPoolResourceId: hostPoolResourceId
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imagePurchasePlan: {
      name: imageSku
      publisher: imagePublisher
      product: imageOffer
    }
    imageSku: imageSku
    location: location
    networkInterfaceNamePrefix: replace(tier.namingConvention.virtualMachineNetworkInterface, '${delimiter}${tokens.purpose}', '')
    networkSecurityGroupResourceId: tier.networkSecurityGroupResourceId
    subnetResourceId: tier.subnets[0].id
    tagsNetworkInterfaces: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/networkInterfaces'] ?? {}, mlzTags)
    tagsVirtualMachines: tagsVirtualMachines
    virtualMachineNamePrefix: replace(tier.namingConvention.virtualMachine, tokens.purpose, '')
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineSize: virtualMachineSize
  }
}
