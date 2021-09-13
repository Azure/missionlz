// scope
targetScope = 'subscription'

param logAnalyticsWorkspaceId string
param deploymentName string

//// Central activity logging to LAWS
resource somethingNew 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'LoggingToLA-${deploymentName}'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Administrative'
        enabled: true
      }
      {
        category: 'Security'
        enabled: true
      }
      {
        category: 'ServiceHealth'
        enabled: true
      }
      {
        category: 'Alert'
        enabled: true
      }
      {
        category: 'Recommendation'
        enabled: true
      }
      {
        category: 'Policy'
        enabled: true
      }
      {
        category: 'Autoscale'
        enabled: true
      }
      {
        category: 'ResourceHealth'
        enabled: true
      }
    ]
  }

}
