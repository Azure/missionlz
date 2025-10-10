// appgateway-route-table.bicep - UDR forcing next hop to Firewall
@description('Deployment location')
param location string
@description('Firewall resource ID to extract private IP (placeholder)')
param firewallResourceId string
@description('Tags object')
param tags object = {}

// Placeholder outputs for integration
output routeTableId string = 'PLACEHOLDER_ROUTE_TABLE_ID'
