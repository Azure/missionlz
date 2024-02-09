param activeDirectorySolution string
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
param monitoring bool
param subnetResourceId string
param tags object
param time string = utcNow('u')
param validationEnvironment bool
param vmTemplate string

var customRdpProperty_Complete = contains(activeDirectorySolution, 'MicrosoftEntraId') ? '${customRdpProperty}targetisaadjoined:i:1;enablerdsaadauth:i:1;' : customRdpProperty
var hostPoolLogs = [
  {
    category: 'Checkpoint'
    enabled: true
  }
  {
    category: 'Error'
    enabled: true
  }
  {
    category: 'Management'
    enabled: true
  }
  {
    category: 'Connection'
    enabled: true
  }
  {
    category: 'HostRegistration'
    enabled: true
  }
  {
    category: 'AgentHealthStatus'
    enabled: true
  }
]

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
  name: hostPoolName
  location: location
  tags: union({
    'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
  }, contains(tags, 'Microsoft.DesktopVirtualization/hostPools') ? tags['Microsoft.DesktopVirtualization/hostPools'] : {})
  properties: {
    customRdpProperty: customRdpProperty_Complete
    hostPoolType: split(hostPoolType, ' ')[0]
    loadBalancerType: contains(hostPoolType, 'Pooled') ? split(hostPoolType, ' ')[1] : 'Persistent'
    maxSessionLimit: maxSessionLimit
    personalDesktopAssignmentType: contains(hostPoolType, 'Personal') ? split(hostPoolType, ' ')[1] : null
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
  tags: union({
    'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
  }, contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {})
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

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (monitoring) {
  name: hostPoolDiagnosticSettingName
  scope: hostPool
  properties: {
    logs: hostPoolLogs
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

output ResourceId string = hostPool.id
