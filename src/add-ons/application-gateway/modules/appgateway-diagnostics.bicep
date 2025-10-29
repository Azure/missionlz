// moved from root: appgateway-diagnostics.bicep
targetScope = 'resourceGroup'
param logAnalyticsWorkspaceId string
param appGatewayName string
param enable bool = true
resource appGw 'Microsoft.Network/applicationGateways@2021-08-01' existing = { name: appGatewayName }
resource diag 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (enable) {
  name: 'diag-${appGatewayName}'
  scope: appGw
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [ { categoryGroup: 'allLogs', enabled: true } ]
    metrics: [ { category: 'AllMetrics', enabled: true } ]
  }
}
output diagnosticsSettingId string = enable ? diag.id : ''