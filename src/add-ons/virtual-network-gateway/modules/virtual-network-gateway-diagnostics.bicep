param virtualNetworkGatewayName string
param logAnalyticsWorkspaceResourceId string

// Existing VPN Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-02-01' existing = {
  name: virtualNetworkGatewayName
}

// Send all logs and metrics to the specified Log Analytics Workspace
resource diagnosticSetting 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = {
  scope: vpnGateway
  name: 'diag-${vpnGateway.name}'
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}
