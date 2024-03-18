param applicationGroupReferences array
param artifactsUri string
param avdPrivateDnsZoneResourceId string
param deploymentUserAssignedIdentityClientId string
param existing bool
param hostPoolName string
param locationControlPlane string
param locationVirtualMachines string
param logAnalyticsWorkspaceResourceId string
param monitoring bool
param resourceGroupManagement string
param subnetResourceId string
param tags object
param timestamp string
param virtualMachineName string
param workspaceFeedDiagnoticSettingName string
param workspaceFeedName string
param workspaceFeedNetworkInterfaceName string
param workspaceFeedPrivateEndpointName string
param workspaceFriendlyName string
param workspacePublicNetworkAccess string

module addApplicationGroups '../common/customScriptExtensions.bicep' = if (existing) {
  scope: resourceGroup(resourceGroupManagement)
  name: 'AddApplicationGroupReferences_${timestamp}'
  params: {
    fileUris: [
      '${artifactsUri}Update-AvdWorkspace.ps1'
    ]
    location: locationVirtualMachines
    parameters: '-ApplicationGroupReferences "${applicationGroupReferences}" -Environment ${environment().name} -ResourceGroupName ${resourceGroup().name} -SubscriptionId ${subscription().subscriptionId} -TenantId ${tenant().tenantId} -UserAssignedIdentityClientId ${deploymentUserAssignedIdentityClientId} -WorkspaceName ${workspaceFeedName}'
    scriptFileName: 'Update-AvdWorkspace.ps1'
    tags: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
    }, contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {})    
    userAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    virtualMachineName: virtualMachineName
  }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = if (!existing) {
  name: workspaceFeedName
  location: locationControlPlane
  tags: {}
  properties: {
    applicationGroupReferences: applicationGroupReferences
    friendlyName: workspaceFriendlyName
    publicNetworkAccess: workspacePublicNetworkAccess
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if (!existing) {
  name: workspaceFeedPrivateEndpointName
  location: locationControlPlane
  tags: {}
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

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (!existing) {
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

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!existing && monitoring) {
  name: workspaceFeedDiagnoticSettingName
  scope: workspace
  properties: {
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Feed'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}
