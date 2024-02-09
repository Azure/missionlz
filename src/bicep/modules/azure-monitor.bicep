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
param privateLinkScopeName string
param privateLinkScopeNetworkInterfaceName string
param privateLinkScopePrivateEndpointName string
param subnetResourceId string
param tags object

resource privateLinkScope 'microsoft.insights/privateLinkScopes@2021-09-01' = {
  name: privateLinkScopeName
  location: 'global'
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'Private'
      queryAccessMode: 'Private'
    }
  }
}

resource scopedResource 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-09-01' = {
  parent: privateLinkScope
  name: logAnalyticsWorkspaceName
  properties: {
    linkedResourceId: logAnalyticsWorkspaceResourceId
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: privateLinkScopePrivateEndpointName
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: privateLinkScopeNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: privateLinkScopePrivateEndpointName
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
  dependsOn: [
    scopedResource
  ]
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: privateLinkScopePrivateEndpointName
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
