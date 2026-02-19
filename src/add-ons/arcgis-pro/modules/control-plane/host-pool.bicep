param avdPrivateDnsZoneResourceId string
param customRdpProperty string
param hostPoolDiagnosticSettingName string
param hostPoolName string
param hostPoolNetworkInterfaceName string
param hostPoolPrivateEndpointName string
param hostPoolPublicNetworkAccess string
param hostPoolType string
param location string
param logAnalyticsWorkspaceResourceId string
param maxSessionLimit int
param mlzTags object
param subnetResourceId string
param tags object
param time string = utcNow('u')
param validationEnvironment bool
param vmTemplate string

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
  name: hostPoolName
  location: location
  tags: union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, tags[?'Microsoft.DesktopVirtualization/hostPools'] ?? {}, mlzTags)
  properties: {
    customRdpProperty: customRdpProperty
    hostPoolType: hostPoolType
    loadBalancerType: hostPoolType == 'Pooled' ? 'DepthFirst' : 'Persistent'
    maxSessionLimit: maxSessionLimit
    personalDesktopAssignmentType: hostPoolType == 'Personal' ? 'Automatic' : null
    preferredAppGroupType: 'Desktop'
    publicNetworkAccess: hostPoolPublicNetworkAccess
    registrationInfo: {
      expirationTime: dateTimeAdd(time, 'PT2H')
      registrationTokenOperation: 'Update'
    }
    startVMOnConnect: true
    validationEnvironment: validationEnvironment
    vmTemplate: vmTemplate
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: hostPoolPrivateEndpointName
  location: location
  tags: union({'cm-resource-parent': hostPool.id}, tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
  properties: {
    customNetworkInterfaceName: hostPoolNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: hostPoolPrivateEndpointName
        properties: {
          privateLinkServiceId: hostPool.id
          groupIds: [
            'connection'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: replace(split(avdPrivateDnsZoneResourceId, '/')[8], '.', '-')
        properties: {
          privateDnsZoneId: avdPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: hostPoolDiagnosticSettingName
  scope: hostPool
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ] 
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

output name string = hostPool.name
output resourceId string = hostPool.id
