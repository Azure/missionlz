/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param agentsvcPrivateDnsZoneId string
param location string = resourceGroup().location
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceResourceId string
param monitorPrivateDnsZoneId string
param odsPrivateDnsZoneId string
param omsPrivateDnsZoneId string
param resourcePrefix string
param subnetResourceId string
param tags object

var privateEndpointName = replace(logAnalyticsWorkspaceName, resourcePrefix, '${resourcePrefix}-pe')
var privateEndpointNetworkInterfaceName = replace(logAnalyticsWorkspaceName, resourcePrefix, '${resourcePrefix}-nic')
var privateLinkScopeName = replace(logAnalyticsWorkspaceName, resourcePrefix, '${resourcePrefix}-pls')

resource privateLinkScope 'microsoft.insights/privateLinkScopes@2019-10-17-preview' = {
  name: privateLinkScopeName
  location: 'global'
  properties: {}
}

resource scopedResource 'microsoft.insights/privateLinkScopes/scopedResources@2019-10-17-preview' = {
  parent: privateLinkScope
  name: logAnalyticsWorkspaceName
  properties: {
    linkedResourceId: logAnalyticsWorkspaceResourceId
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: privateEndpointNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: privateEndpointNetworkInterfaceName
        properties: {
          privateLinkServiceId: privateLinkScope.id
          groupIds: [
            'azuremonitor'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}


resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  name: privateEndpointName
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'monitor'
        properties: {
          privateDnsZoneId: monitorPrivateDnsZoneId
        }
      }
      {
        name: 'oms'
        properties: {
          privateDnsZoneId: omsPrivateDnsZoneId
        }
      }
      {
        name: 'ods'
        properties: {
          privateDnsZoneId: odsPrivateDnsZoneId
        }
      }
      {
        name: 'agentsvc'
        properties: {
          privateDnsZoneId: agentsvcPrivateDnsZoneId
        }
      }
    ]
  }
}

