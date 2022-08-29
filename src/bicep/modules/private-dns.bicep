/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@description('The name of the virtual network the private dns zones will be connected to')
param vnetName string

@description('The name of the the resource group where the virtual network exists')
param vnetResourceGroup string = resourceGroup().name

@description('The subscription id of the subscription the virtual network exists in')
param vnetSubscriptionId string = subscription().subscriptionId

@description('The tags that will be associated to the resources')
param tags object

var privateDnsZones_privatelink_monitor_azure_name = ( environment().name =~ 'AzureCloud' ? 'privatelink.monitor.azure.com' : 'privatelink.monitor.azure.us' ) 
var privateDnsZones_privatelink_ods_opinsights_azure_name = ( environment().name =~ 'AzureCloud' ? 'privatelink.ods.opinsights.azure.com' : 'privatelink.ods.opinsights.azure.us' )
var privateDnsZones_privatelink_oms_opinsights_azure_name = ( environment().name =~ 'AzureCloud' ? 'privatelink.oms.opinsights.azure.com' : 'privatelink.oms.opinsights.azure.us' )
var privateDnsZones_privatelink_blob_core_cloudapi_net_name = ( environment().name =~ 'AzureCloud' ? 'privatelink.blob.${environment().suffixes.storage}' : 'privatelink.blob.core.usgovcloudapi.net' )
var privateDnsZones_privatelink_agentsvc_azure_automation_name = ( environment().name =~ 'AzureCloud' ? 'privatelink.agentsvc.azure-automation.net' : 'privatelink.agentsvc.azure-automation.us' )

resource privatelink_monitor_azure_com 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_monitor_azure_name
  location: 'global'
  tags: tags
}

resource privatelink_oms_opinsights_azure_com 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_oms_opinsights_azure_name
  location: 'global'
  tags: tags
}

resource privatelink_ods_opinsights_azure_com 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_ods_opinsights_azure_name
  location: 'global'
  tags: tags
}

resource privatelink_agentsvc_azure_automation_net 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_agentsvc_azure_automation_name
  location: 'global'
  tags: tags
}

resource privatelink_blob_core_cloudapi_net 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_blob_core_cloudapi_net_name
  location: 'global'
  tags: tags
}

resource privatelink_monitor_azure_com_privatelink_monitor_azure_com_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZones_privatelink_monitor_azure_name}/${privateDnsZones_privatelink_monitor_azure_name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName )
    }
  }
  dependsOn: [
    privatelink_monitor_azure_com
  ]
}

resource privatelink_oms_opinsights_azure_com_privatelink_oms_opinsights_azure_com_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZones_privatelink_oms_opinsights_azure_name}/${privateDnsZones_privatelink_oms_opinsights_azure_name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName )
    }
  }
  dependsOn: [
    privatelink_oms_opinsights_azure_com
    privatelink_monitor_azure_com_privatelink_monitor_azure_com_link
  ]
}

resource privatelink_ods_opinsights_azure_com_privatelink_ods_opinsights_azure_com_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZones_privatelink_ods_opinsights_azure_name}/${privateDnsZones_privatelink_ods_opinsights_azure_name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName )
    }
  }
  dependsOn: [
    privatelink_ods_opinsights_azure_com
    privatelink_oms_opinsights_azure_com_privatelink_oms_opinsights_azure_com_link
  ]
}

resource privatelink_agentsvc_azure_automation_net_privatelink_agentsvc_azure_automation_net_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZones_privatelink_agentsvc_azure_automation_name}/${privateDnsZones_privatelink_agentsvc_azure_automation_name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName )
    }
  }
  dependsOn: [
    privatelink_agentsvc_azure_automation_net
    privatelink_ods_opinsights_azure_com_privatelink_ods_opinsights_azure_com_link
  ]
}

resource privateDnsZones_privatelink_blob_core_cloudapi_net_privateDnsZones_privatelink_blob_core_cloudapi_net_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZones_privatelink_blob_core_cloudapi_net_name}/${privateDnsZones_privatelink_blob_core_cloudapi_net_name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName )
    }
  }
  dependsOn: [
    privatelink_blob_core_cloudapi_net
    privatelink_agentsvc_azure_automation_net_privatelink_agentsvc_azure_automation_net_link
  ]
}

output monitorPrivateDnsZoneId string = privatelink_monitor_azure_com.id
output omsPrivateDnsZoneId string = privatelink_oms_opinsights_azure_com.id
output odsPrivateDnsZoneId string = privatelink_ods_opinsights_azure_com.id
output agentsvcPrivateDnsZoneId string = privatelink_agentsvc_azure_automation_net.id
output storagePrivateDnsZoneId string = privatelink_blob_core_cloudapi_net.id
