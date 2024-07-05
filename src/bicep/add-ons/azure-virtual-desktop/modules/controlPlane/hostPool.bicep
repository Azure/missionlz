param activeDirectorySolution string
param artifactsUri string
param avdPrivateDnsZoneResourceId string
param customImageId string
param customRdpProperty string
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param deploymentUserAssignedIdentityPrincipalId string
param diskSku string
param domainName string
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
param keyVaultDiagnosticLogs array
param keyVaultDiagnosticSettingName string
param keyVaultName string
param keyVaultNetworkInterfaceName string
param keyVaultPrivateDnsZoneResourceId string
param keyVaultPrivateEndpointName string
param location string
param logAnalyticsWorkspaceResourceId string
param logAnalyticsWorkspaceResourceId_Ops string
param managementVirtualMachineName string
param maxSessionLimit int
param mlzTags object
param monitoring bool
param resourceGroupManagement string
param sessionHostNamePrefix string
param storageAccountResourceId string
param subnetResourceId string
param tags object
param time string = utcNow('u')
param validationEnvironment bool
param virtualMachineSize string

var customRdpProperty_Complete = contains(activeDirectorySolution, 'MicrosoftEntraId')
  ? '${customRdpProperty}targetisaadjoined:i:1;enablerdsaadauth:i:1;'
  : customRdpProperty
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
  tags: union(
    {
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
    },
    contains(tags, 'Microsoft.DesktopVirtualization/hostPools') ? tags['Microsoft.DesktopVirtualization/hostPools'] : {},
    mlzTags
  )
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
    vmTemplate: '{"domain":"${domainName}","galleryImageOffer":${galleryImageOffer},"galleryImagePublisher":${galleryImagePublisher},"galleryImageSKU":${galleryImageSku},"imageType":${imageType},"customImageId":${customImageId},"namePrefix":"${sessionHostNamePrefix}","osDiskType":"${diskSku}","vmSize":{"id":"${virtualMachineSize}","cores":null,"ram":null,"rdmaEnabled": false,"supportsMemoryPreservingMaintenance": true},"galleryItemId":${galleryItemId},"hibernate":false,"diskSizeGB":0,"securityType":"TrustedLaunch","secureBoot":true,"vTPM":true,"vmInfrastructureType":"Cloud","virtualProcessorCount":null,"memoryGB":null,"maximumMemoryGB":null,"minimumMemoryGB":null,"dynamicMemoryConfig":false}'
  }
}

resource privateEndpoint_hostPool 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: hostPoolPrivateEndpointName
  location: location
  tags: union(
    {
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
    },
    contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {},
    mlzTags
  )
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

resource privateDnsZoneGroup_hostPool 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint_hostPool
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

resource diagnosticSetting_hostPool 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (monitoring) {
  name: hostPoolDiagnosticSettingName
  scope: hostPool
  properties: {
    logs: hostPoolLogs
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  tags: union(
    {
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
    },
    contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {},
    mlzTags
  )
  properties: {
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: 'Disabled'
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}

resource privateEndpoint_keyVault 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: keyVaultPrivateEndpointName
  location: location
  tags: union(
    {
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
    },
    contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {},
    mlzTags
  )
  properties: {
    customNetworkInterfaceName: keyVaultNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: keyVaultPrivateEndpointName
        properties: {
          privateLinkServiceId: vault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup_keyVault 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint_keyVault
  name: vault.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

module diagnosticSetting_keyVault '../../../../modules/key-vault-diagnostics.bicep' = {
  name: 'deploy-kv-diags-${deploymentNameSuffix}'
  params: {
    keyVaultDiagnosticSettingName: keyVaultDiagnosticSettingName
    keyVaultName: vault.name
    keyVaultStorageAccountId: storageAccountResourceId
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId_Ops
    logs: keyVaultDiagnosticLogs
  }
}

resource roleAssignment_hostPool 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(deploymentUserAssignedIdentityPrincipalId, 'e307426c-f9b6-4e81-87de-d99efb3c32bc', hostPool.id)
  scope: hostPool
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e307426c-f9b6-4e81-87de-d99efb3c32bc') // Desktop Virtualization Host Pool Contributor
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignment_keyVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(deploymentUserAssignedIdentityPrincipalId, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7', vault.id)
  scope: vault
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7') // Key Vault Secrets Officer
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

module hostPoolRegistrationToken '../common/customScriptExtensions.bicep' = {
  name: 'deploy-host-pool-registration-token-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    fileUris: [
      '${artifactsUri}Set-HostPoolRegistrationToken.ps1'
    ]
    location: location
    parameters: '-HostPoolName "${hostPoolName}" -HostPoolResourceGroupName "${resourceGroup().name}" -KeyVaultUri "${vault.properties.vaultUri}" -ResourceManagerUri "${environment().resourceManager}" -SubscriptionId "${subscription().subscriptionId}" -UserAssignedIdentityClientId "${deploymentUserAssignedIdentityClientId}"'
    scriptFileName: 'Set-HostPoolRegistrationToken.ps1'
    tags: union(
      {
        'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
      },
      contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {},
      mlzTags
    )
    userAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    privateDnsZoneGroup_hostPool
    privateDnsZoneGroup_keyVault
  ]
}

output name string = hostPool.name
output resourceId string = hostPool.id
