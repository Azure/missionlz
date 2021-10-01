@description('The name of the resource the private endpoint is being created for')
param laWorkspaceName string

@description('The resource id of the resoure the private endpoint is being created for')
param laWorkspaceResourceId string

@description('The region the private endpoint will be created in')
param privateEndpointLocation string = resourceGroup().location

@description('The name of the subnet in the virtual network where the private endpoint will be placed')
param privateEndpointSubnetName string

@description('The name of the virtual network where the private endpoint will be placed')
param privateEndpointVnetName string

@description('The tags that will be associated to the VM')
param tags object

@description('Data used to append to resources to ensure uniqueness')
param uniqueData string = substring(newGuid(), 0, 8)

@description('The name of the the resource group where the virtual network exists')
param vnetResourceGroup string = resourceGroup().name

@description('The subscription id of the subscription the virtual network exists in')
param vnetSubscriptionId string = subscription().subscriptionId

var privateLinkConnName = substring('plconn${laWorkspaceName}${uniqueData}', 0, 16)
var privateLinkEndpointName_var = substring('pl${laWorkspaceName}${uniqueData}', 0, 16)
var privateLinkScopeName_var = substring('plscope${laWorkspaceName}${uniqueData}', 0, 16)
var privateLinkScopeResourceName = substring('plscres${laWorkspaceName}${uniqueData}', 0, 16)

resource privateLinkScopeName 'microsoft.insights/privateLinkScopes@2019-10-17-preview' = {
  name: privateLinkScopeName_var
  location: 'global'
  properties: {}
}

resource privateLinkScopeName_privateLinkScopeResourceName 'microsoft.insights/privateLinkScopes/scopedResources@2019-10-17-preview' = {
  name: '${privateLinkScopeName_var}/${privateLinkScopeResourceName}'
  properties: {
    linkedResourceId: laWorkspaceResourceId
  }
  dependsOn: [
    privateLinkScopeName
  ]
}

resource privateLinkEndpointName 'Microsoft.Network/privateEndpoints@2020-07-01' = {
  name: privateLinkEndpointName_var
  location: privateEndpointLocation
  tags: tags
  properties: {
    subnet: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', privateEndpointVnetName, privateEndpointSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnName
        properties: {
          privateLinkServiceId: privateLinkScopeName.id
          groupIds: [
            'azuremonitor'
          ]
        }
      }
    ]
  }
  dependsOn: [
    privateLinkScopeName_privateLinkScopeResourceName
  ]
}

resource privateLinkEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  name: '${privateLinkEndpointName_var}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'monitor'
        properties: {
          privateDnsZoneId: privatelink_monitor_azure_com.id
        }
      }
      {
        name: 'oms'
        properties: {
          privateDnsZoneId: privatelink_oms_opinsights_azure_com.id
        }
      }
      {
        name: 'ods'
        properties: {
          privateDnsZoneId: privatelink_ods_opinsights_azure_com.id
        }
      }
      {
        name: 'agentsvc'
        properties: {
          privateDnsZoneId: privatelink_agentsvc_azure_automation_net .id
        }
      }
    ]
  }
  dependsOn: [
    privateLinkEndpointName
  ]
}
var privateDnsZones_privatelink_monitor_azure_name = ( environment().name =~ 'AzureCloud' ? 'privatelink.monitor.azure.com' : 'privatelink.monitor.azure.us' ) 
var privateDnsZones_privatelink_ods_opinsights_azure_name = ( environment().name =~ 'AzureCloud' ? 'privatelink.ods.opinsights.azure.com' : 'privatelink.ods.opinsights.azure.us' )
var privateDnsZones_privatelink_oms_opinsights_azure_name = ( environment().name =~ 'AzureCloud' ? 'privatelink.oms.opinsights.azure.com' : 'privatelink.oms.opinsights.azure.us' )
var privateDnsZones_privatelink_blob_core_cloudapi_net_name = ( environment().name =~ 'AzureCloud' ? 'privatelink.blob.${environment().suffixes.storage}' : 'privatelink.blob.core.usgovcloudapi.net' )
var privateDnsZones_privatelink_agentsvc_azure_automation_name = ( environment().name =~ 'AzureCloud' ? 'privatelink.agentsvc.azure-automation.net' : 'privatelink.agentsvc.azure-automation.us' )

resource privatelink_monitor_azure_com 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_monitor_azure_name
  location: 'global'
}

resource privatelink_oms_opinsights_azure_com 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_oms_opinsights_azure_name
  location: 'global'
}

resource privatelink_ods_opinsights_azure_com 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_ods_opinsights_azure_name
  location: 'global'
}

resource privatelink_agentsvc_azure_automation_net 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_agentsvc_azure_automation_name
  location: 'global'
}

resource privatelink_blob_core_cloudapi_net 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_blob_core_cloudapi_net_name
  location: 'global'
}

resource privatelink_monitor_azure_com_privatelink_monitor_azure_com_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZones_privatelink_monitor_azure_name}/${privateDnsZones_privatelink_monitor_azure_name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', privateEndpointVnetName )
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
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', privateEndpointVnetName )
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
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', privateEndpointVnetName )
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
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', privateEndpointVnetName )
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
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', privateEndpointVnetName )
    }
  }
  dependsOn: [
    privatelink_blob_core_cloudapi_net
    privatelink_agentsvc_azure_automation_net_privatelink_agentsvc_azure_automation_net_link
  ]
}
