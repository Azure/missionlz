param name string
param location string
param tags object = {}

param securityRules array

param logStorageAccountResourceId string
param logAnalyticsWorkspaceResourceId string

param logs array
param metrics array

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: name
  location: location
  tags: tags

  properties: {
    securityRules: securityRules
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: networkSecurityGroup
  name: '${networkSecurityGroup.name}-diagnostics'
  properties: {
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
    metrics: metrics
  }
}

output id string = networkSecurityGroup.id
output name string = networkSecurityGroup.name
