// appgateway-core.bicep - Application Gateway resource skeleton
@description('Deployment location')
param location string
@description('Deployment name for resource naming context')
param deploymentName string
@description('Subnet ID for the AppGateway')
param subnetId string
@description('Route table ID (if association logic needed)')
param routeTableId string
@description('WAF policy resource ID')
param wafPolicyId string
@description('Common defaults object')
param commonDefaults object
@description('Apps array defining listeners/backends')
param apps array
@description('Enable diagnostic settings')
param enableDiagnosticLogs bool
@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string
@description('Tags object')
param tags object = {}

// Placeholder outputs
output appGatewayResourceId string = 'PLACEHOLDER_APPGW_ID'
output publicIpAddress string = 'PLACEHOLDER_PUBLIC_IP'
output perAppListenerMap object = {}
output perAppBackendPoolMap object = {}
