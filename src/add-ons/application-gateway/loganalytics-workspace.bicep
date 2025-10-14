// loganalytics-workspace.bicep - ensures a Log Analytics workspace exists
// Deploys at resource group scope

targetScope = 'resourceGroup'

@description('Workspace name')
param name string
@description('Location for the workspace')
param location string
@description('Tags to apply')
param tags object = {}
@description('Retention in days (30-730)')
param retentionDays int = 30

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionDays
  }
  tags: tags
}

output workspaceId string = workspace.id
