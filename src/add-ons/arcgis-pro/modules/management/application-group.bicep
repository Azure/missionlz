param desktopApplicationGroupName string
param hostPoolResourceId string
param locationControlPlane string
param mlzTags object
param securityPrincipalObjectId string
param tags object

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: desktopApplicationGroupName
  location: locationControlPlane
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.DesktopVirtualization/applicationGroups'] ?? {}, mlzTags)
  properties: {
    hostPoolArmPath: hostPoolResourceId
    applicationGroupType: 'Desktop'
  }
}

// Role Assignment for AVD access
// Purpose: assigns the Desktop Virtualization User role on the application group for the specified security principals
resource roleAssignment_ApplicationGroup 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(securityPrincipalObjectId, '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63', applicationGroup.id)
  scope: applicationGroup
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
    principalId: securityPrincipalObjectId
  }
}

output resourceId string = applicationGroup.id
