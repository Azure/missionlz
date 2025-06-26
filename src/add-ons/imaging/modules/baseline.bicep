/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param computeGalleryName string
param deploymentNameSuffix string
param enableBuildAutomation bool
param environmentAbbreviation string
param exemptPolicyAssignmentIds array
param keyVaultPrivateDnsZoneResourceId string
param location string
param resourceGroupName string
param storageAccountResourceId string
param subnetResourceId string
param subscriptionId string
param tags object
param tier object
param userAssignedIdentityName string

module userAssignedIdentity 'user-assigned-identity.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'user-assigned-identity-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: tier.mlzTags
    name: userAssignedIdentityName
    tags: tags
  }
}

module roleAssignments_ResourceGroups 'role-assignments/resource-groups.bicep' = {
  name: 'role-assignment-compute-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    principalId: userAssignedIdentity.outputs.principalId
  }
}

module storageAccount 'storage-account.bicep' = {
  name: 'role-assignment-storage-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, split(storageAccountResourceId, '/')[4])
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountResourceId: storageAccountResourceId
  }
}

module customerManagedKeys '../../../modules/customer-managed-keys.bicep' = {
  params: {
    location: location
    tags: tags
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    mlzTags: {}
    resourceGroupName: resourceGroupName
    subnetResourceId: subnetResourceId
    tier: tier
  }
}

module key '../../../modules/key-vault-key.bicep' = {
  name: 'deploy-cmk-key-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    keyName: tier.namingConvention.diskEncryptionSet
    keyVaultName: customerManagedKeys.outputs.keyVaultName
  }
}

module diskEncryptionSet '../../../modules/disk-encryption-set.bicep' = {
  name: 'deploy-cmk-des-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    tags: tags
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: tier.namingConvention.diskEncryptionSet
    keyUrl: key.outputs.keyUriWithVersion
    keyVaultResourceId: customerManagedKeys.outputs.keyVaultResourceId
    mlzTags: tier.mlzTags
  }
}

module roleAssignment_DiskEncryptionSet 'role-assignments/disk-encryption-set.bicep' = {
  name: 'disk-encryption-set-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    diskEncryptionSetName: split(diskEncryptionSet.outputs.resourceId, '/')[8]
    principalId: userAssignedIdentity.outputs.principalId
  }
}

module computeGallery 'compute-gallery.bicep' = {
  name: 'gallery-image-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    computeGalleryName: computeGalleryName
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
    scope: resourceGroup(subscriptionId, resourceGroupName)
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
