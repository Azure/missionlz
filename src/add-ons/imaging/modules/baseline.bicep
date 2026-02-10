/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param enableBuildAutomation bool
param environmentAbbreviation string
param exemptPolicyAssignmentIds array
param keyVaultPrivateDnsZoneResourceId string
param location string
param mlzTags object
param resourceAbbreviations object
param storageAccountResourceId string
param tags object
param tier object
param tokens object

var resourceGroupName = replace(tier.namingConvention.resourceGroup, tokens.purpose, tier.name)

module rg '../../../modules/resource-group.bicep' = {
  name: 'deploy-imaging-rg-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    name: resourceGroupName
    location: location
    tags: union(tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
  }
}

// Identity used on mgmt VM to execute run commands
module userAssignedIdentity 'user-assigned-identity.bicep' = {
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  name: 'user-assigned-identity-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.userAssignedIdentity, tokens.purpose, tier.name)
    tags: tags
  }
  dependsOn: [
    rg
  ]
}

// Role assignments needed to perform image build
module roleAssignments_ResourceGroups 'role-assignments/resource-groups.bicep' = {
  name: 'role-assignment-compute-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    principalId: userAssignedIdentity.outputs.principalId
  }
  dependsOn: [
    rg
  ]
}

// Role assignment needed to access build artifacts in storage account
module roleAssignment_StorageAccount 'role-assignments/storage-account.bicep' = {
  name: 'role-assignment-storage-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, split(storageAccountResourceId, '/')[4])
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountResourceId: storageAccountResourceId
  }
}

// Enables customer managed keys for disk encryption on the mgmt VM
module customerManagedKeys '../../../modules/customer-managed-keys.bicep' = {
  name: 'deploy-cmk-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: replace(tier.namingConvention.diskEncryptionSet, tokens.purpose, 'cmk')
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    resourceAbbreviations: resourceAbbreviations
    subnetResourceId: tier.subnetResourceId
    tags: tags
    tier: tier
    tokens: tokens
    type: 'virtualMachine'
  }
  dependsOn: [
    rg
  ]
}

// Need to validate if this is still needed
// module roleAssignment_DiskEncryptionSet 'role-assignments/disk-encryption-set.bicep' = {
//   name: 'disk-encryption-set-${deploymentNameSuffix}'
//   scope: resourceGroup(tier.subscriptionId, resourceGroupName)
//   params: {
//     diskEncryptionSetName: split(diskEncryptionSet.outputs.resourceId, '/')[8]
//     principalId: userAssignedIdentity.outputs.principalId
//   }
// }

module computeGallery 'compute-gallery.bicep' = {
  name: 'gallery-image-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    computeGalleryName: replace(tier.namingConvention.computeGallery, tokens.purpose, tier.name)
    enableBuildAutomation: enableBuildAutomation
    location: location
    mlzTags: mlzTags
    tags: tags
    userAssignedIdentityPrincipalId: userAssignedIdentity.outputs.principalId
  }
  dependsOn: [
    rg
  ]
}

module policyExemptions 'exemption.bicep' = [
  for i in range(0, length(exemptPolicyAssignmentIds)): if (!empty((exemptPolicyAssignmentIds)[0])) {
    name: 'PolicyExemption_${i}'
    scope: resourceGroup(tier.subscriptionId, resourceGroupName)
    params: {
      policyAssignmentId: exemptPolicyAssignmentIds[i]
    }
  }
]

output computeGalleryResourceId string = computeGallery.outputs.computeGalleryResourceId
output diskEncryptionSetResourceId string = customerManagedKeys.outputs.diskEncryptionSetResourceId
output resourceGroupName string = resourceGroupName
output userAssignedIdentityClientId string = userAssignedIdentity.outputs.clientId
output userAssignedIdentityPrincipalId string = userAssignedIdentity.outputs.principalId
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
