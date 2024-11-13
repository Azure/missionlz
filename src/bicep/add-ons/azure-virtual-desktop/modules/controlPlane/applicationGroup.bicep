param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param deploymentUserAssignedIdentityPrincipalId string
param desktopApplicationGroupName string
param desktopFriendlyName string
param hostPoolResourceId string
param locationControlPlane string
param locationVirtualMachines string
param mlzTags object
param resourceGroupManagement string
param roleDefinitions object
param securityPrincipalObjectIds array
param tags object
param virtualMachineName string

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' = {
  name: desktopApplicationGroupName
  location: locationControlPlane
  tags: union({
    'cm-resource-parent': hostPoolResourceId
  }, contains(tags, 'Microsoft.DesktopVirtualization/applicationGroups') ? tags['Microsoft.DesktopVirtualization/applicationGroups'] : {}, mlzTags)
  properties: {
    hostPoolArmPath: hostPoolResourceId
    applicationGroupType: 'Desktop'
  }
}

resource roleAssignment_ManagedIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(deploymentUserAssignedIdentityPrincipalId, '86240b0e-9422-4c43-887b-b61143f32ba8', applicationGroup.id)
  scope: applicationGroup
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '86240b0e-9422-4c43-887b-b61143f32ba8') // Desktop Virtualization Application Group Contributor (Purpose: updates the friendly name for the desktop)
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Adds a friendly name to the SessionDesktop application for the desktop application group
module applicationFriendlyName '../common/runCommand.bicep' = if (!empty(desktopFriendlyName)) {
  scope: resourceGroup(resourceGroupManagement)
  name: 'deploy-vdapp-friendly-name-${deploymentNameSuffix}'
  params: {
    location: locationVirtualMachines
    name: 'Update-AvdDesktop'
    parameters: [
      {
        name: 'ApplicationGroupName' 
        value: applicationGroup.name
      }
      {
        name: 'FriendlyName' 
        value: desktopFriendlyName
      }
      {
        name: 'ResourceGroupName' 
        value:resourceGroup().name
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'SubscriptionId'
        value:subscription().subscriptionId
      }
      {
        name: 'UserAssignedIdentityClientId' 
        value: deploymentUserAssignedIdentityClientId
      }
    ]
    script: loadTextContent('../../artifacts/Update-AvdDesktop.ps1')
    tags: union(
      {
        'cm-resource-parent': hostPoolResourceId
      },
      contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {},
      mlzTags
    )
    virtualMachineName: virtualMachineName
  }
  dependsOn: [
    roleAssignment_ManagedIdentity
  ]
}

resource roleAssignment_Users 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(securityPrincipalObjectIds)): {
  scope: applicationGroup
  name: guid(securityPrincipalObjectIds[i], roleDefinitions.DesktopVirtualizationUser, desktopApplicationGroupName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.DesktopVirtualizationUser)
    principalId: securityPrincipalObjectIds[i]
  }
}]

output resourceId string = applicationGroup.id
