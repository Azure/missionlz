/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
targetScope = 'subscription'

param logAnalyticsWorkspaceId string
param networks array
param supportedClouds array = [
  'AzureCloud'
  'AzureUSGovernment'
]

// Export Activity Log to LAW
resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = [for (network, i) in networks: if ( contains(supportedClouds, environment().name) ) {
  name: 'diag-activity-log-${network.subscriptionId}'
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
}]
