param delegatedSubnetResourceId string
param deployFslogix bool
param deploymentNameSuffix string
param enableApplicationInsights bool
param environmentAbbreviation string
param hostPoolName string
param keyExpirationInDays int = 30
param location string = resourceGroup().location
param logAnalyticsWorkspaceResourceId string
param namingConvention object
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string
param resourceAbbreviations object
param resourceGroupControlPlane string
param resourceGroupHosts string
param resourceGroupStorage string
param scalingBeginPeakTime string
param scalingEndPeakTime string
param scalingLimitSecondsToForceLogOffUser string
param scalingMinimumNumberOfRdsh string
param scalingSessionThresholdPerCPU string
param serviceToken string
param subnetResourceId string
param tags object
param timeDifference string

var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var functionAppKeyword = environment().name == 'AzureCloud' || environment().name == 'AzureUSGovernment'
  ? 'azurewebsites'
  : 'appservice'
var functionAppScmPrivateDnsZoneResourceId = '${privateDnsZoneResourceIdPrefix}scm.${filter(privateDnsZones, name => contains(name, functionAppKeyword))[0]}'
var roleAssignments = union([
  {
    roleDefinitionId: '40c5ff49-9181-41f8-ae61-143b0e78555e' // Desktop Virtualization Power On Off Contributor
    scope: resourceGroupControlPlane
  }
  {
    roleDefinitionId: '40c5ff49-9181-41f8-ae61-143b0e78555e' // Desktop Virtualization Power On Off Contributor
    scope: resourceGroupHosts
  }
], deployFslogix ? [
  {
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor
    scope: resourceGroupStorage
  }
] : [])
var service = 'mgmt'
var storagePrivateDnsZoneResourceIds = [
  '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
  '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'file'))[0]}'
  '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'queue'))[0]}'
  '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'table'))[0]}'
]
var storageSubResources = [
  'blob'
  'file'
  'queue'
  'table'
]

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: replace(namingConvention.userAssignedIdentity, serviceToken, service)
  location: location
  tags: tags[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}
}

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${resourceAbbreviations.keyVaults}${uniqueString(replace(namingConvention.keyVault, service, 'cmk'), resourceGroup().id)}'
  location: location
  tags: tags[?'Microsoft.KeyVault/vaults'] ?? {}
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
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
      name: 'premium'
    }
    softDeleteRetentionInDays: environmentAbbreviation == 'dev' || environmentAbbreviation == 'test' ? 7 : 90
    tenantId: subscription().tenantId
  }
}

resource roleAssignment_Encryption 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userAssignedIdentity.id, 'e147488a-f6f5-4113-8e2d-b22465e65bf6', vault.id)
  scope: vault
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')  // Key Vault Crypto Service Encryption User
  }
}

resource privateEndpoint_vault 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: replace(namingConvention.keyVaultPrivateEndpoint, serviceToken, service)
  location: location
  tags: tags[?'Microsoft.Network/privateEndpoints'] ?? {}
  properties: {
    customNetworkInterfaceName: replace(namingConvention.keyVaultNetworkInterface, serviceToken, service)
    privateLinkServiceConnections: [
      {
        name: replace(namingConvention.keyVaultPrivateEndpoint, serviceToken, service)
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

resource privateDnsZoneGroup_vault 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint_vault
  name: vault.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          #disable-next-line use-resource-id-functions
          privateDnsZoneId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'vaultcore'))[0]}'
        }
      }
    ]
  }
}

resource key_storageAccount 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: vault
  name: 'StorageEncryptionKey'
  properties: {
    attributes: {
      enabled: true
    }
    keySize: 4096
    kty: 'RSA'
    rotationPolicy: {
      attributes: {
        expiryTime: 'P${string(keyExpirationInDays)}D'
      }
      lifetimeActions: [
        {
          action: {
            type: 'Notify'
          }
          trigger: {
            timeBeforeExpiry: 'P10D'
          }
        }
        {
          action: {
            type: 'Rotate'
          }
          trigger: {
            timeAfterCreate: 'P${string(keyExpirationInDays - 7)}D'
          }
        }
      ]
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: uniqueString(replace(namingConvention.storageAccount, serviceToken, service), resourceGroup().id)
  location: location
  tags: tags[?'Microsoft.Storage/storageAccounts'] ?? {}
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowedCopyScope: 'PrivateLink'
    allowSharedKeyAccess: false
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: 'None'
    }
    defaultToOAuthAuthentication: false
    dnsEndpointType: 'Standard'
    encryption: {
      identity: {
        userAssignedIdentity: userAssignedIdentity.id
      }
      requireInfrastructureEncryption: true
      keyvaultproperties: {
        keyvaulturi: vault.properties.vaultUri
        keyname: key_storageAccount.name
      }
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        table: {
          keyType: 'Account'
          enabled: true
        }
        queue: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.KeyVault'
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Disabled'
    supportsHttpsTrafficOnly: true
  }
  dependsOn: [
    privateDnsZoneGroup_vault
    privateEndpoint_vault
    roleAssignment_Encryption
  ]
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: storageAccount
  name: 'default'
}

resource privateEndpoints_storage 'Microsoft.Network/privateEndpoints@2023-04-01' = [
  for resource in storageSubResources: {
    name: replace(
      namingConvention.storageAccountPrivateEndpoint,
      '${serviceToken}-${resourceAbbreviations.storageAccounts}',
      '${resource}-${resourceAbbreviations.storageAccounts}-scale'
    )
    location: location
    tags: tags[?'Microsoft.Network/privateEndpoints'] ?? {}
    properties: {
      customNetworkInterfaceName: replace(
        namingConvention.storageAccountNetworkInterface,
        '${serviceToken}-${resourceAbbreviations.storageAccounts}',
        '${resource}-${resourceAbbreviations.storageAccounts}-scale'
      )
      privateLinkServiceConnections: [
        {
          name: replace(
            namingConvention.storageAccountPrivateEndpoint,
            '${serviceToken}-${resourceAbbreviations.storageAccounts}',
            '${resource}-${resourceAbbreviations.storageAccounts}-scale'
          )
          properties: {
            privateLinkServiceId: storageAccount.id
            groupIds: [
              resource
            ]
          }
        }
      ]
      subnet: {
        id: subnetResourceId
      }
    }
  }
]

resource privateDnsZoneGroups_storage 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = [
  for (resource, i) in storageSubResources: {
    parent: privateEndpoints_storage[i]
    name: storageAccount.name
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'ipconfig1'
          properties: {
            #disable-next-line use-resource-id-functions
            privateDnsZoneId: storagePrivateDnsZoneResourceIds[i]
          }
        }
      ]
    }
  }
]

resource diagnosticSetting_storage_blob 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (enableApplicationInsights) {
  scope: blobService
  name: replace(
    namingConvention.storageAccountDiagnosticSetting,
    '${serviceToken}-${resourceAbbreviations.storageAccounts}',
    'blob-${resourceAbbreviations.storageAccounts}-scale'
  )
  properties: {
    logs: [
      {
        category: 'StorageWrite'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableApplicationInsights) {
  name: replace(namingConvention.applicationInsights, serviceToken, service)
  location: location
  tags: tags[?'Microsoft.Insights/components'] ?? {}
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
  }
  kind: 'web'
}

module privateLinkScope 'privateLinkScope.bicep' = if (enableApplicationInsights) {
  name: 'deploy-private-link-scope-appi-${deploymentNameSuffix}'
  scope: resourceGroup(split(privateLinkScopeResourceId, '/')[2], split(privateLinkScopeResourceId, '/')[4])
  params: {
    applicationInsightsResourceId: applicationInsights.id
    privateLinkScopeResourceId: privateLinkScopeResourceId
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: replace(namingConvention.appServicePlan, serviceToken, service)
  location: location
  tags: tags[?'Microsoft.Web/serverfarms'] ?? {}
  sku: {
    name: 'P0v3'
    tier: 'PremiumV3'
    size: 'P0v3'
    family: 'Pv3'
    capacity: 1
  }
  kind: 'functionapp'
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: uniqueString(replace(namingConvention.functionApp, serviceToken, service), resourceGroup().id)
  location: location
  tags: tags[?'Microsoft.Web/sites'] ?? {}
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    clientAffinityEnabled: false
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: true
      appSettings:union([
        {
          name: 'AzureWebJobsStorage__blobServiceUri'
          value: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__queueServiceUri'
          value: 'https://${storageAccount.name}.queue.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__tableServiceUri'
          value: 'https://${storageAccount.name}.table.${environment().suffixes.storage}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'WEBSITE_LOAD_USER_PROFILE'
          value: '1'
        }
        {
          name: 'BeginPeakTime'
          value: scalingBeginPeakTime
        }
        {
          name: 'EndPeakTime'
          value: scalingEndPeakTime
        }
        {
          name: 'EnvironmentName'
          value: environment().name
        }
        {
          name: 'FileShareName'
          value: 'profile-containers'
        }
        {
          name: 'HostPoolName'
          value: hostPoolName
        }
        {
          name: 'HostPoolResourceGroupName'
          value: resourceGroupControlPlane
        }
        {
          name: 'LimitSecondsToForceLogOffUser'
          value: scalingLimitSecondsToForceLogOffUser
        }
        {
          name: 'LogOffMessageBody'
          value: 'This session is about to be logged off. Please save your work.'
        }
        {
          name: 'LogOffMessageTitle'
          value: 'Session Log Off'
        }
        {
          name: 'MaintenanceTagName'
          value: 'Maintenance'
        }
        {
          name: 'MinimumNumberOfRDSH'
          value: scalingMinimumNumberOfRdsh
        }
        {
          name: 'ResourceGroupName'
          value: resourceGroupStorage
        }
        {
          name: 'ResourceManagerUrl'
          // This workaround is needed because the environment().resourceManager value is missing the trailing slash for some Azure environments
          value: endsWith(environment().resourceManager, '/')
            ? environment().resourceManager
            : '${environment().resourceManager}/'
        }
        {
          name: 'SessionThresholdPerCPU'
          value: scalingSessionThresholdPerCPU
        }
        {
          name: 'StorageSuffix'
          value: environment().suffixes.storage
        }
        {
          name: 'SubscriptionId'
          value: subscription().subscriptionId
        }
        {
          name: 'TenantId'
          value: subscription().tenantId
        }
        {
          name: 'TimeDifference'
          value: timeDifference
        }
      ], enableApplicationInsights ? [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
      ] : [])
      cors: {
        allowedOrigins: [ 
          '${environment().portal}'
          'https://functions-next.${cloudSuffix}'
          'https://functions-staging.${cloudSuffix}'
          'https://functions.${cloudSuffix}'
        ]
      }
      ftpsState: 'Disabled'
      netFrameworkVersion: 'v6.0'
      powerShellVersion: '7.2'
      publicNetworkAccess: 'Disabled'
      use32BitWorkerProcess: false
    }
    virtualNetworkSubnetId: delegatedSubnetResourceId
    vnetContentShareEnabled: false
    vnetRouteAllEnabled: true
  }
}

resource privateEndpoint_functionApp 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: replace(namingConvention.functionAppPrivateEndpoint, serviceToken, service)
  location: location
  properties: {
    customNetworkInterfaceName: replace(namingConvention.functionAppNetworkInterface, serviceToken, service)
    privateLinkServiceConnections: [
      {
        name: replace(namingConvention.functionAppPrivateEndpoint, serviceToken, service)
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup_functionApp 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint_functionApp
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          #disable-next-line use-resource-id-functions
          privateDnsZoneId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, functionAppKeyword))[0]}'
        }
      }
    ]
  }
}

module roleAssignments_resourceGroups '../common/roleAssignments/resourceGroup.bicep' = [
  for i in range(0, length(roleAssignments)): {
    name: 'set-role-assignment-${i}-${deploymentNameSuffix}'
    scope: resourceGroup(roleAssignments[i].scope)
    params: {
      principalId: functionApp.identity.principalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: roleAssignments[i].roleDefinitionId
    }
  }
]

module roleAssignment_storageAccount '../common/roleAssignments/storageAccount.bicep' = {
  name: 'set-role-assignment-storage-${deploymentNameSuffix}'
  params: {
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner
    storageAccountName: storageAccount.name
  }
}

// This module is used to deploy the A record for the SCM site which does not use a dedicated private endpoint
module scmARecord 'aRecord.bicep' = {
  name: 'deploy-scm-a-record-${deploymentNameSuffix}'
  scope: resourceGroup(split(functionAppScmPrivateDnsZoneResourceId, '/')[2], split(functionAppScmPrivateDnsZoneResourceId, '/')[4])
  params: {
    functionAppName: functionApp.name
    ipv4Address: filter(privateDnsZoneGroup_functionApp.properties.privateDnsZoneConfigs[0].properties.recordSets, record => record.recordSetName == functionApp.name)[0].ipAddresses[0]
    privateDnsZoneName: split(functionAppScmPrivateDnsZoneResourceId, '/')[8]
  }
}

output functionAppName string = functionApp.name
