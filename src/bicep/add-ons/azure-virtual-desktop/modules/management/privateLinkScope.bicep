param applicationInsightsName string
param applicationInsightsResourceId string
param privateLinkScopeResourceId string

#disable-next-line BCP081
resource privateLinkScope 'Microsoft.Insights/privateLinkScopes@2021-09-01' existing = {
  name: split(privateLinkScopeResourceId, '/')[8]
}

#disable-next-line BCP081
resource scopedResource 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-09-01' = {
  parent: privateLinkScope
  name: applicationInsightsName
  properties: {
    linkedResourceId: applicationInsightsResourceId
  }
}
