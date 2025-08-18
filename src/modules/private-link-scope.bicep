/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param logAnalyticsWorkspaceResourceId string
param name string

#disable-next-line BCP081
resource privateLinkScope 'microsoft.insights/privateLinkScopes@2021-09-01' = {
  name: name
  location: 'global'
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'PrivateOnly'
      queryAccessMode: 'PrivateOnly'
    }
  }
}

#disable-next-line BCP081
resource scopedResource 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-09-01' = {
  parent: privateLinkScope
  name: split(logAnalyticsWorkspaceResourceId, '/')[8]
  properties: {
    linkedResourceId: logAnalyticsWorkspaceResourceId
  }
}

output resourceId string = privateLinkScope.id
