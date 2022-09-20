/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@description('The name of the resource the private endpoint is being created for')
param logAnalyticsWorkspaceName string

@description('The resource id of the resoure the private endpoint is being created for')
param logAnalyticsWorkspaceResourceId string

@description('The name of the subnet in the virtual network where the private endpoint will be placed')
param privateEndpointSubnetName string

@description('The name of the virtual network where the private endpoint will be placed')
param privateEndpointVnetName string

@description('The tags that will be associated to the VM')
param tags object

@description('Data used to append to resources to ensure uniqueness')
param uniqueData string = substring(uniqueString(subscription().subscriptionId, deployment().name), 0, 8)

@description('The name of the the resource group where the virtual network exists')
param vnetResourceGroup string = resourceGroup().name

@description('The subscription id of the subscription the virtual network exists in')
param vnetSubscriptionId string = subscription().subscriptionId

@description('The location of this resource')
param location string = resourceGroup().location

@description('Azure Monitor Private DNS Zone resource id')
param monitorPrivateDnsZoneId string

@description('OMS Private DNS Zone resource id')
param omsPrivateDnsZoneId string

@description('ODS Private DNS Zone resource id')
param odsPrivateDnsZoneId string

@description('Agentsvc Private DNS Zone resource id')
param agentsvcPrivateDnsZoneId string

@description('Azure Blob Storage Private DNS Zone resource id')
param storagePrivateDnsZoneId string

var privateLinkConnectionName = take('plconn${logAnalyticsWorkspaceName}${uniqueData}', 80)
var privateLinkEndpointName = take('pl${logAnalyticsWorkspaceName}${uniqueData}', 80)
var privateLinkScopeName = take('plscope${logAnalyticsWorkspaceName}${uniqueData}', 80)
var privateLinkScopeResourceName = take('plscres${logAnalyticsWorkspaceName}${uniqueData}', 80)

resource globalPrivateLinkScope 'microsoft.insights/privateLinkScopes@2019-10-17-preview' = {
  name: privateLinkScopeName
  location: 'global'
  properties: {}
}

resource logAnalyticsWorkspacePrivateLinkScope 'microsoft.insights/privateLinkScopes/scopedResources@2019-10-17-preview' = {
  name: '${privateLinkScopeName}/${privateLinkScopeResourceName}'
  properties: {
    linkedResourceId: logAnalyticsWorkspaceResourceId
  }
  dependsOn: [
    globalPrivateLinkScope
  ]
}

resource subnetPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-07-01' = {
  name: privateLinkEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', privateEndpointVnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionName
        properties: {
          privateLinkServiceId: globalPrivateLinkScope.id
          groupIds: [
            'azuremonitor'
          ]
        }
      }
    ]
  }
  dependsOn: [
    logAnalyticsWorkspacePrivateLinkScope
  ]
}

resource dnsZonePrivateLinkEndpoint 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  name: '${privateLinkEndpointName}/default'
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
      {
        name: 'storage'
        properties: {
          privateDnsZoneId: storagePrivateDnsZoneId
        }
      }
    ]
  }
  dependsOn: [
    subnetPrivateEndpoint
  ]
}
