@description('Deployment location')
param location string = resourceGroup().location

@description('Private Endpoint Name')
param privateEndpointName string

@description('Private Endpoint Tags')
param privateEndpointTags object = {}

@description('Virtual Network Subnet Id to attach the Private Endpoint to')
param vnetSubnetResourceId string

@description('Resource Id of the Resource to attach the private endpoint to')
param resourceId string

@description('Private endpoint resource types')
param privateEndpointResourceType string

@description('Resource Id of the Private DNS Zone to integrate the Private Endpoint with')
param privateDnsZoneResourceId string = ''

resource privateEndpointName_resource 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: privateEndpointName
  location: location
  tags: privateEndpointTags
  properties: {
    subnet: {
      id: vnetSubnetResourceId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: resourceId
          groupIds: [
            privateEndpointResourceType
          ]
        }
      }
    ]
  }
}

resource privateEndpointName_privateDnsIntegration 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = if (privateDnsZoneResourceId != '') {
  parent: privateEndpointName_resource
  name: 'privateDnsIntegration'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneResourceId
        }
      }
    ]
  }
}

output privateEndpointCustomDnsConfigs array = privateEndpointName_resource.properties.customDnsConfigs
