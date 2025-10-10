// appgateway-diagnostics.bicep - attach diagnostic settings (future)
@description('Deployment location')
param location string
@description('Log Analytics Workspace Id')
param logAnalyticsWorkspaceId string
@description('App Gateway resource ID')
param appGatewayResourceId string
@description('Enable diagnostics')
param enable bool = true
@description('Tags object')
param tags object = {}

// Placeholder output
output diagnosticsSettingId string = 'PLACEHOLDER_DIAG_ID'
