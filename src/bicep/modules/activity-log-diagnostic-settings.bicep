/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
targetScope = 'subscription'

param logAnalyticsWorkspaceId string

// Export Activity Log to LAW
resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' =  {
  name: 'diag-activity-log-${subscription().subscriptionId}'
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
