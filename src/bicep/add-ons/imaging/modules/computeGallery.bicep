/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param computeGalleryName string
param enableBuildAutomation bool
param location string
param mlzTags object
param tags object
param userAssignedIdentityPrincipalId string

var roleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor

resource computeGallery 'Microsoft.Compute/galleries@2022-01-03' = {
  name: computeGalleryName
  location: location
  tags: union(contains(tags, 'Microsoft.Compute/galleries') ? tags['Microsoft.Compute/galleries'] : {}, mlzTags)
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' =
  if (enableBuildAutomation) {
    scope: computeGallery
    name: guid(userAssignedIdentityPrincipalId, roleDefinitionId, computeGallery.id)
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
      principalId: userAssignedIdentityPrincipalId
      principalType: 'ServicePrincipal'
    }
  }

output computeGalleryResourceId string = computeGallery.id
