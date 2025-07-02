/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param delimiter string
param deploymentNameSuffix string
param enableBuildAutomation bool
param environmentAbbreviation string
param exemptPolicyAssignmentIds array
param keyVaultPrivateDnsZoneResourceId string
param location string
param resourceAbbreviations object
param storageAccountResourceId string
param tags object
param tier object

module userAssignedIdentity 'user-assigned-identity.bicep' = {
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  name: 'user-assigned-identity-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: tier.mlzTags
    name: tier.namingConvention.userAssignedIdentity
    tags: tags
  }
}

module roleAssignments_ResourceGroups 'role-assignments/resource-groups.bicep' = {
  name: 'role-assignment-compute-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    principalId: userAssignedIdentity.outputs.principalId
  }
}

module storageAccount 'storage-account.bicep' = {
  name: 'role-assignment-storage-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, split(storageAccountResourceId, '/')[4])
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountResourceId: storageAccountResourceId
  }
}

module customerManagedKeys '../../../modules/customer-managed-keys.bicep' = {
  params: {
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: tier.namingConvention.diskEncryptionSet
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    resourceAbbreviations: resourceAbbreviations
    tags: tags
    tier: tier
  }
}

module diskEncryptionSet '../../../modules/disk-encryption-set.bicep' = {
  name: 'deploy-cmk-des-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    location: location
    tags: tags
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: tier.namingConvention.diskEncryptionSet
    keyUrl: customerManagedKeys.outputs.keyUriWithVersion
    keyVaultResourceId: customerManagedKeys.outputs.keyVaultResourceId
    mlzTags: tier.mlzTags
  }
}

module roleAssignment_DiskEncryptionSet 'role-assignments/disk-encryption-set.bicep' = {
  name: 'disk-encryption-set-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    diskEncryptionSetName: split(diskEncryptionSet.outputs.resourceId, '/')[8]
    principalId: userAssignedIdentity.outputs.principalId
  }
}

module computeGallery 'compute-gallery.bicep' = {
  name: 'gallery-image-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    computeGalleryName: tier.namingConvention.computeGallery
    enableBuildAutomation: enableBuildAutomation
    location: location
    mlzTags: tier.mlzTags
    tags: tags
    userAssignedIdentityPrincipalId: userAssignedIdentity.outputs.principalId
  }
}

module policyExemptions 'exemption.bicep' = [
  for i in range(0, length(exemptPolicyAssignmentIds)): if (!empty((exemptPolicyAssignmentIds)[0])) {
    name: 'PolicyExemption_${i}'
    scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
    params: {
      policyAssignmentId: exemptPolicyAssignmentIds[i]
    }
  }
]

output computeGalleryResourceId string = computeGallery.outputs.computeGalleryResourceId
output diskEncryptionSetResourceId string = diskEncryptionSet.outputs.resourceId
output userAssignedIdentityClientId string = userAssignedIdentity.outputs.clientId
output userAssignedIdentityPrincipalId string = userAssignedIdentity.outputs.principalId
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
