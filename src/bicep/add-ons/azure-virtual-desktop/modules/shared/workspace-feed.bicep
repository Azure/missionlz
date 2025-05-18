param applicationGroupResourceId string
param avdPrivateDnsZoneResourceId string
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param enableAvdInsights bool
param existingFeedWorkspaceResourceId string
param hostPoolResourceId string
param locationControlPlane string
param locationVirtualMachines string
param logAnalyticsWorkspaceResourceId string
param mlzTags object
param resourceGroupManagement string
param subnetResourceId string
param tags object
param virtualMachineName string
param workspaceFeedDiagnoticSettingName string
param workspaceFeedName string
param workspaceFeedNetworkInterfaceName string
param workspaceFeedPrivateEndpointName string
param workspaceFriendlyName string
param workspacePublicNetworkAccess string

module addApplicationGroups '../common/run-command.bicep' = if (!empty(existingFeedWorkspaceResourceId)) {
  scope: resourceGroup(resourceGroupManagement)
  name: 'add-vdag-references-${deploymentNameSuffix}'
  params: {
    location: locationVirtualMachines
    name: 'Update-AvdWorkspace'
    parameters: [
      {
        name: 'ApplicationGroupResourceId'
        value: applicationGroupResourceId
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: deploymentUserAssignedIdentityClientId
      }
      {
        name: 'WorkspaceResourceId'
        value: existingFeedWorkspaceResourceId
      }
    ]
    script: loadTextContent('../../artifacts/Update-AvdWorkspace.ps1')
    tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
    virtualMachineName: virtualMachineName
  }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = if (empty(existingFeedWorkspaceResourceId)) {
  name: workspaceFeedName
  location: locationControlPlane
  tags: mlzTags
  properties: {
    applicationGroupReferences: [
      applicationGroupResourceId
    ]
    friendlyName: workspaceFriendlyName
    publicNetworkAccess: workspacePublicNetworkAccess
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if (empty(existingFeedWorkspaceResourceId)) {
  name: workspaceFeedPrivateEndpointName
  location: locationControlPlane
  tags: mlzTags
  properties: {
    customNetworkInterfaceName: workspaceFeedNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: workspaceFeedPrivateEndpointName
        properties: {
          privateLinkServiceId: workspace.id
          groupIds: [
            'feed'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (empty(existingFeedWorkspaceResourceId)) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: replace(split(avdPrivateDnsZoneResourceId, '/')[8], '.', '-')
        properties: {
          privateDnsZoneId: avdPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableAvdInsights) {
  name: workspaceFeedDiagnoticSettingName
  scope: workspace
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}
