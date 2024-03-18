param artifactsUri string
param deploymentUserAssignedIdentityClientId string
param desktopApplicationGroupName string
param desktopFriendlyName string
param hostPoolResourceId string
param locationControlPlane string
param locationVirtualMachines string
param resourceGroupManagement string
param roleDefinitions object
param securityPrincipalObjectIds array
param tags object
param timestamp string
param virtualMachineName string

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-03-09-preview' = {
  name: desktopApplicationGroupName
  location: locationControlPlane
  tags: union({
    'cm-resource-parent': hostPoolResourceId
  }, contains(tags, 'Microsoft.DesktopVirtualization/applicationGroups') ? tags['Microsoft.DesktopVirtualization/applicationGroups'] : {})
  properties: {
    hostPoolArmPath: hostPoolResourceId
    applicationGroupType: 'Desktop'
  }
}

// Adds a friendly name to the SessionDesktop application for the desktop application group
module applicationFriendlyName '../common/customScriptExtensions.bicep' = if (!empty(desktopFriendlyName)) {
  scope: resourceGroup(resourceGroupManagement)
  name: 'ApplicationFriendlyName_${timestamp}'
  params : {
    fileUris: [
      '${artifactsUri}Update-AvdDesktop.ps1'
    ]
    location: locationVirtualMachines
    parameters: '-ApplicationGroupName ${applicationGroup.name} -Environment ${environment().name} -FriendlyName "${desktopFriendlyName}" -ResourceGroupName ${resourceGroup().name} -SubscriptionId ${subscription().subscriptionId} -Tenant ${tenant().tenantId} -UserAssignedIdentityClientId ${deploymentUserAssignedIdentityClientId}'
    scriptFileName: 'Update-AvdDesktop.ps1'
    tags: union({
      'cm-resource-parent': hostPoolResourceId
    }, contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {})
    userAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    virtualMachineName: virtualMachineName
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(securityPrincipalObjectIds)): {
  scope: applicationGroup
  name: guid(securityPrincipalObjectIds[i], roleDefinitions.DesktopVirtualizationUser, desktopApplicationGroupName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.DesktopVirtualizationUser)
    principalId: securityPrincipalObjectIds[i]
  }
}]


output applicationGroupReference array = [
  applicationGroup.id
]
output resourceId string = applicationGroup.id
