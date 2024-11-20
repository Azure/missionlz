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
param securityPrincipalObjectIds array
param tags object
param virtualMachineName string

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: desktopApplicationGroupName
  location: locationControlPlane
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.DesktopVirtualization/applicationGroups'] ?? {}, mlzTags)
  properties: {
    hostPoolArmPath: hostPoolResourceId
    applicationGroupType: 'Desktop'
  }
}

// Role Assignment to update the Application
// Purpose: assigns the Desktop Virtualization Application Group Contributor role to the
// managed identity so the run command can update the friendly name for the application
resource roleAssignment_ManagedIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(deploymentUserAssignedIdentityPrincipalId, '86240b0e-9422-4c43-887b-b61143f32ba8', applicationGroup.id)
  scope: applicationGroup
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '86240b0e-9422-4c43-887b-b61143f32ba8')
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Run Command to update the Application
// Purpose: executes a script to update the friendly name on the application
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
    tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
    virtualMachineName: virtualMachineName
  }
  dependsOn: [
    roleAssignment_ManagedIdentity
  ]
}

// Role Assignment for AVD access
// Purpose: assigns the Desktop Virtualization User role to the application group for the specified security principals
resource roleAssignment_ApplicationGroup 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(securityPrincipalObjectIds)): {
  name: guid(securityPrincipalObjectIds[i], '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63', applicationGroup.id)
  scope: applicationGroup
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
    principalId: securityPrincipalObjectIds[i]
  }
}]

output resourceId string = applicationGroup.id
