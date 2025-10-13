// appgateway-diagnostics.bicep - attach diagnostic settings to Application Gateway
targetScope = 'resourceGroup'

@description('Log Analytics Workspace resource ID')
param logAnalyticsWorkspaceId string
@description('Application Gateway name (existing in this resource group)')
param appGatewayName string
@description('Enable diagnostics')
param enable bool = true

// Minimal set of log categories for App Gateway (can be extended later)
// Use category group 'allLogs' for parity with other add-ons (collects all available log categories)

// Reference existing Application Gateway
// Existing App Gateway reference
resource appGw 'Microsoft.Network/applicationGateways@2021-08-01' existing = {
	name: appGatewayName
}

resource diag 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if (enable) {
	name: 'diag-${appGatewayName}'
	scope: appGw
	properties: {
		workspaceId: logAnalyticsWorkspaceId
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
	}
}

output diagnosticsSettingId string = enable ? diag.id : ''
