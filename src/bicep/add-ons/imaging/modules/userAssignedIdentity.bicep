/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param location string
param mlzTags object
param name string
param tags object

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: name
  location: location
  tags: union(
    contains(tags, 'Microsoft.ManagedIdentity/userAssignedIdentities')
      ? tags['Microsoft.ManagedIdentity/userAssignedIdentities']
      : {},
    mlzTags
  )
}

output clientId string = userAssignedIdentity.properties.clientId
output principalId string = userAssignedIdentity.properties.principalId
output resourceId string = userAssignedIdentity.id
