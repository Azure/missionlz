param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param desktopApplicationGroupName string
param desktopFriendlyName string
param hostPoolResourceId string
param locationControlPlane string
param locationVirtualMachines string
param mlzTags object
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

// Run Command to update the Application
// Purpose: executes a script to update the friendly name on the application
module applicationFriendlyName '../common/run-command.bicep' = if (!empty(desktopFriendlyName)) {
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
}

// Role Assignment for AVD access
// Purpose: assigns the Desktop Virtualization User role on the application group for the specified security principals
resource roleAssignment_ApplicationGroup 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(securityPrincipalObjectIds)): {
  name: guid(securityPrincipalObjectIds[i], '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63', applicationGroup.id)
  scope: applicationGroup
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
    principalId: securityPrincipalObjectIds[i]
  }
}]

output resourceId string = applicationGroup.id
