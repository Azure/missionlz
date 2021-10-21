param name string
param location string
param tags object = {}

param skuName string
param publicIpAllocationMethod string
param availabilityZones array

param logStorageAccountResourceId string
param logAnalyticsWorkspaceResourceId string

param logs array
param metrics array

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: name
  location: location
  tags: tags

  sku: {
    name: skuName
  }

  properties: {
    publicIPAllocationMethod: publicIpAllocationMethod
  }

  zones: availabilityZones
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: publicIPAddress
  name: '${publicIPAddress.name}-diagnostics'
  properties: {
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
    metrics: metrics
  }
}

output id string = publicIPAddress.id
