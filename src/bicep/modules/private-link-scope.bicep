param logAnalyticsWorkspaceResourceId string
param name string

resource privateLinkScope 'microsoft.insights/privateLinkScopes@2021-09-01' = {
  name: name
  location: 'global'
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'Private'
      queryAccessMode: 'Private'
    }
  }
}

resource scopedResource 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-09-01' = {
  parent: privateLinkScope
  name: split(logAnalyticsWorkspaceResourceId, '/')[8]
  properties: {
    linkedResourceId: logAnalyticsWorkspaceResourceId
  }
}

output resourceId string = privateLinkScope.id
