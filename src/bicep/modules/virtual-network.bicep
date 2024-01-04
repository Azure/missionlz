/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param name string
param location string
param tags object = {}

param addressPrefix string
param vNetDnsServers array = []
param logAnalyticsWorkspaceResourceId string
param logStorageAccountResourceId string
param subnets array

param logs array
param metrics array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: name
  location: location
  tags: tags

  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: subnets
    dhcpOptions: vNetDnsServers != null ? {
      dnsServers: vNetDnsServers
    } : null
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: virtualNetwork
  name: '${virtualNetwork.name}-diagnostics'
  properties: {
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
    metrics: metrics
  }
}

output name string = virtualNetwork.name
output id string = virtualNetwork.id
output subnets array = virtualNetwork.properties.subnets
output addressPrefix string = virtualNetwork.properties.addressSpace.addressPrefixes[0]
