param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
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

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-03-09-preview' = {
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
        value:deploymentUserAssignedIdentityClientId
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
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(securityPrincipalObjectIds)): {
  scope: applicationGroup
  name: guid(securityPrincipalObjectIds[i], roleDefinitions.DesktopVirtualizationUser, desktopApplicationGroupName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.DesktopVirtualizationUser)
    principalId: securityPrincipalObjectIds[i]
  }
}]

output resourceId string = applicationGroup.id
