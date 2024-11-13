param activeDirectorySolution string
param avdPrivateDnsZoneResourceId string
param deploymentUserAssignedIdentityPrincipalId string
param customImageId string
param customRdpProperty string
param diskSku string
param domainName string
param enableAvdInsights bool
param galleryImageOffer string
param galleryImagePublisher string
param galleryImageSku string
param galleryItemId string
param hostPoolDiagnosticSettingName string
param hostPoolName string
param hostPoolNetworkInterfaceName string
param hostPoolPrivateEndpointName string
param hostPoolPublicNetworkAccess string
param hostPoolType string
param imageType string
param location string
param logAnalyticsWorkspaceResourceId string
param maxSessionLimit int
param mlzTags object
param sessionHostNamePrefix string
param subnetResourceId string
param tags object
param time string = utcNow('u')
param validationEnvironment bool
param virtualMachineSize string

var customRdpProperty_Complete = contains(activeDirectorySolution, 'MicrosoftEntraId') ? '${customRdpProperty}enablerdsaadauth:i:1;' : customRdpProperty

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
  name: hostPoolName
  location: location
  tags: union({
    'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
  }, contains(tags, 'Microsoft.DesktopVirtualization/hostPools') ? tags['Microsoft.DesktopVirtualization/hostPools'] : {}, mlzTags)
  properties: {
    customRdpProperty: customRdpProperty_Complete
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
    vmTemplate: '{"domain":"${domainName}","galleryImageOffer":${galleryImageOffer},"galleryImagePublisher":${galleryImagePublisher},"galleryImageSKU":${galleryImageSku},"imageType":${imageType},"customImageId":${customImageId},"namePrefix":"${sessionHostNamePrefix}","osDiskType":"${diskSku}","vmSize":{"id":"${virtualMachineSize}","cores":null,"ram":null,"rdmaEnabled": false,"supportsMemoryPreservingMaintenance": true},"galleryItemId":${galleryItemId},"hibernate":false,"diskSizeGB":0,"securityType":"TrustedLaunch","secureBoot":true,"vTPM":true,"vmInfrastructureType":"Cloud","virtualProcessorCount":null,"memoryGB":null,"maximumMemoryGB":null,"minimumMemoryGB":null,"dynamicMemoryConfig":false}'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: hostPoolPrivateEndpointName
  location: location
  tags: union({
    'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
  }, contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}, mlzTags)
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

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(deploymentUserAssignedIdentityPrincipalId, '2ad6aaab-ead9-4eaa-8ac5-da422f562408', hostPool.id)
  scope: hostPool
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2ad6aaab-ead9-4eaa-8ac5-da422f562408') // Desktop Virtualization Session Host Operator (Purpose: sets drain mode on the AVD session hosts)
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableAvdInsights) {
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
