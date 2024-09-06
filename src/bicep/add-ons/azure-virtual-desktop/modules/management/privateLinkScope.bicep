param applicationInsightsResourceId string = ''
param logAnalyticsWorkspaceResourceId string = ''
param privateLinkScopeResourceId string

#disable-next-line BCP081
resource privateLinkScope 'Microsoft.Insights/privateLinkScopes@2021-09-01' existing = {
  name: split(privateLinkScopeResourceId, '/')[8]
}

#disable-next-line BCP081
resource scopedResource_appInsights 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-09-01' = if (!(empty(applicationInsightsResourceId))) {
  parent: privateLinkScope
  name: split(applicationInsightsResourceId, '/')[8]
  properties: {
    linkedResourceId: applicationInsightsResourceId
  }
}

#disable-next-line BCP081
resource scopedResource_logAnalyticsWorkspace 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-09-01' = if (!(empty(logAnalyticsWorkspaceResourceId))) {
  parent: privateLinkScope
  name: split(logAnalyticsWorkspaceResourceId, '/')[8]
  properties: {
    linkedResourceId: applicationInsightsResourceId
  }
}
