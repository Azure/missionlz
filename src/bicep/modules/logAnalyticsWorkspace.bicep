param name string
param location string
param tags object = {}
param retentionInDays int = 30
param skuName string = 'PerGB2018'
param workspaceCappingDailyQuotaGb int = -1
param deploySentinel bool = false

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    retentionInDays: retentionInDays
    sku:{
      name: skuName
    }
    workspaceCapping: {
      dailyQuotaGb: workspaceCappingDailyQuotaGb
    }
  }
}

//// sentinel
module sentinelSolution './sentinelSolution.bicep' = if (deploySentinel) {
  name: 'sentinelSolution'
  params: {
    workspaceName: logAnalyticsWorkspace.name
    workspaceLocation: location
    tags: tags
   }
}

output id string = logAnalyticsWorkspace.id
output name string = logAnalyticsWorkspace.name
