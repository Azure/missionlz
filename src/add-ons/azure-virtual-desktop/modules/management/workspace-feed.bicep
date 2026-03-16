param applicationGroupResourceId string
param avdPrivateDnsZoneResourceId string
param enableAvdInsights bool
param hostPoolResourceId string
param location string
param logAnalyticsWorkspaceResourceId string
param mlzTags object
param subnetResourceId string
param tags object
param workspaceFeedDiagnoticSettingName string
param workspaceFeedName string
param workspaceFeedNetworkInterfaceName string
param workspaceFeedPrivateEndpointName string
param workspaceFriendlyName string
param workspacePublicNetworkAccess string

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = {
  name: workspaceFeedName
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.DesktopVirtualization/workspaces'] ?? {}, mlzTags)
  properties: {
    applicationGroupReferences: [
      applicationGroupResourceId
    ]
    friendlyName: workspaceFriendlyName
    publicNetworkAccess: workspacePublicNetworkAccess
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: workspaceFeedPrivateEndpointName
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
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

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
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
