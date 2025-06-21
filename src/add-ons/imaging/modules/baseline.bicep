/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param computeGalleryName string
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
param enableBuildAutomation bool
param exemptPolicyAssignmentIds array
param location string
param mlzTags object
param resourceGroupName string
param storageAccountResourceId string
param subscriptionId string
param tags object
param userAssignedIdentityName string

module userAssignedIdentity 'userAssignedIdentity.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'user-assigned-identity-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: mlzTags
    name: userAssignedIdentityName
    tags: tags
  }
}

module roleAssignments 'roleAssignments.bicep' = {
  name: 'role-assignment-compute-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    principalId: userAssignedIdentity.outputs.principalId
  }
}

module storageAccount 'storageAccount.bicep' = {
  name: 'role-assignment-storage-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, split(storageAccountResourceId, '/')[4])
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountResourceId: storageAccountResourceId
  }
}

module diskEncryptionSet 'diskEncryptionSet.bicep' = {
  scope: resourceGroup(split(diskEncryptionSetResourceId, '/')[2], split(diskEncryptionSetResourceId, '/')[4])
  name: 'disk-encryption-set-${deploymentNameSuffix}'
  params: {
    diskEncryptionSetName: split(diskEncryptionSetResourceId, '/')[8]
    principalId: userAssignedIdentity.outputs.principalId
  }
}

module computeGallery 'computeGallery.bicep' = {
  name: 'gallery-image-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    computeGalleryName: computeGalleryName
    enableBuildAutomation: enableBuildAutomation
    location: location
    mlzTags: mlzTags
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
output userAssignedIdentityClientId string = userAssignedIdentity.outputs.clientId
output userAssignedIdentityPrincipalId string = userAssignedIdentity.outputs.principalId
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
