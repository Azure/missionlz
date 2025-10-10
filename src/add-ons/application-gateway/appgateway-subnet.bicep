// appgateway-subnet.bicep - ensure AppGateway subnet & optional NSG
@description('Deployment location')
param location string
@description('Hub VNet resource ID')
param hubVnetResourceId string
@description('Tags object')
param tags object = {}

// Placeholder outputs for integration
output subnetId string = 'PLACEHOLDER_SUBNET_ID'
