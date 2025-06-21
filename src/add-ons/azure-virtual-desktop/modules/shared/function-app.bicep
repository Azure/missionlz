param delegatedSubnetResourceId string
param delimiter string
param deploymentNameSuffix string
param enableApplicationInsights bool
param environmentAbbreviation string
param hostPoolResourceId string
param keyExpirationInDays int = 30
param location string = resourceGroup().location
param logAnalyticsWorkspaceResourceId string
param mlzTags object
param names object
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string
param resourceGroupFslogix string
param subnetResourceId string
param tags object

var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var functionAppKeyword = environment().name == 'AzureCloud' || environment().name == 'AzureUSGovernment' ? 'azurewebsites' : 'appservice'
var functionAppScmPrivateDnsZoneResourceId = '${privateDnsZoneResourceIdPrefix}scm.${filter(privateDnsZones, name => contains(name, functionAppKeyword))[0]}'
var resourceSuffix = 'aipfsq' // Auto Increase Premium File Share Quota
var storageSubResources = [
  {
    name: 'blob'
    id: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
    nic: '${names.storageAccountBlobNetworkInterface}${delimiter}${resourceSuffix}'
    pe: '${names.storageAccountBlobPrivateEndpoint}${delimiter}${resourceSuffix}'
  }
  {
    name: 'file'
    id: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'file'))[0]}'
    nic: '${names.storageAccountFileNetworkInterface}${delimiter}${resourceSuffix}'
    pe: '${names.storageAccountFilePrivateEndpoint}${delimiter}${resourceSuffix}'
  }
  {
    name: 'queue'
    id: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'queue'))[0]}'
    nic: '${names.storageAccountQueueNetworkInterface}${delimiter}${resourceSuffix}'
    pe: '${names.storageAccountQueuePrivateEndpoint}${delimiter}${resourceSuffix}'
  }
  {
    name: 'table'
    id: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'table'))[0]}'
    nic: '${names.storageAccountTableNetworkInterface}${delimiter}${resourceSuffix}'
    pe: '${names.storageAccountTablePrivateEndpoint}${delimiter}${resourceSuffix}'
  }
]

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${names.userAssignedIdentity}${delimiter}${resourceSuffix}'
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}, mlzTags)
}

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: uniqueString('${names.keyVault}${delimiter}${resourceSuffix}', resourceGroup().id)
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.KeyVault/vaults'] ?? {}, mlzTags)
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
  name: '${names.keyVaultPrivateEndpoint}${delimiter}${resourceSuffix}'
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
  properties: {
    customNetworkInterfaceName: '${names.keyVaultNetworkInterface}${delimiter}${resourceSuffix}'
    privateLinkServiceConnections: [
      {
        name: '${names.keyVaultPrivateEndpoint}${delimiter}${resourceSuffix}'
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
  name: uniqueString('${names.storageAccount}${delimiter}${resourceSuffix}', resourceGroup().id)
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Storage/storageAccounts'] ?? {}, mlzTags)
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
    name: resource.pe
    location: location
    tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
    properties: {
      customNetworkInterfaceName: resource.nic
      privateLinkServiceConnections: [
        {
          name: resource.pe
          properties: {
            privateLinkServiceId: storageAccount.id
            groupIds: [
              resource.name
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
            privateDnsZoneId: resource.id
          }
        }
      ]
    }
  }
]

resource diagnosticSetting_storage_blob 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (enableApplicationInsights) {
  scope: blobService
  name: '${names.storageAccountBlobDiagnosticSetting}${delimiter}${resourceSuffix}'
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
  name: '${names.applicationInsights}${delimiter}${resourceSuffix}'
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Insights/components'] ?? {}, mlzTags)
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
  }
  kind: 'web'
}

module privateLinkScope '../common/private-link-scope.bicep' = if (enableApplicationInsights) {
  name: 'deploy-private-link-scope-appi-${deploymentNameSuffix}'
  scope: resourceGroup(split(privateLinkScopeResourceId, '/')[2], split(privateLinkScopeResourceId, '/')[4])
  params: {
    applicationInsightsResourceId: applicationInsights.id
    privateLinkScopeResourceId: privateLinkScopeResourceId
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${names.appServicePlan}${delimiter}${resourceSuffix}'
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Web/serverfarms'] ?? {}, mlzTags)
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
    size: 'P1v3'
    family: 'Pv3'
    capacity: 1
  }
  kind: 'functionapp'
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: uniqueString('${names.functionApp}${delimiter}${resourceSuffix}', resourceGroup().id)
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Web/sites'] ?? {}, mlzTags)
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
          name: 'FileShareName'
          value: 'profile-containers'
        }
        {
          name: 'ResourceGroupName'
          value: resourceGroupFslogix
        }
        {
          name: 'ResourceManagerUrl'
          // This workaround is needed because the environment().resourceManager value is missing the trailing slash for some Azure environments
          value: endsWith(environment().resourceManager, '/')
            ? environment().resourceManager
            : '${environment().resourceManager}/'
        }
        {
          name: 'StorageSuffix'
          value: environment().suffixes.storage
        }
        {
          name: 'SubscriptionId'
          value: subscription().subscriptionId
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
      powerShellVersion: '7.4'
      publicNetworkAccess: 'Disabled'
      use32BitWorkerProcess: false
    }
    virtualNetworkSubnetId: delegatedSubnetResourceId
    vnetContentShareEnabled: false
    vnetRouteAllEnabled: true
  }
}

resource privateEndpoint_functionApp 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: '${names.functionAppPrivateEndpoint}${delimiter}${resourceSuffix}'
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
  properties: {
    customNetworkInterfaceName: '${names.functionAppNetworkInterface}${delimiter}${resourceSuffix}'
    privateLinkServiceConnections: [
      {
        name: '${names.functionAppPrivateEndpoint}${delimiter}${resourceSuffix}'
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

// Required role assignment to support the zero trust deployment of a function app
module roleAssignment_storageAccount '../common/role-assignments/storage-account.bicep' = {
  name: 'set-role-assignment-storage-${deploymentNameSuffix}'
  params: {
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner
    storageAccountName: storageAccount.name
  }
}

// This module is used to deploy the A record for the SCM site which does not use a dedicated private endpoint
module scmARecord 'a-record.bicep' = {
  name: 'deploy-scm-a-record-${deploymentNameSuffix}'
  scope: resourceGroup(split(functionAppScmPrivateDnsZoneResourceId, '/')[2], split(functionAppScmPrivateDnsZoneResourceId, '/')[4])
  params: {
    functionAppName: functionApp.name
    ipv4Address: filter(privateDnsZoneGroup_functionApp.properties.privateDnsZoneConfigs[0].properties.recordSets, record => record.recordSetName == functionApp.name)[0].ipAddresses[0]
    privateDnsZoneName: split(functionAppScmPrivateDnsZoneResourceId, '/')[8]
  }
}

resource function 'Microsoft.Web/sites/functions@2020-12-01' = {
  parent: functionApp
  name: 'auto-increase-file-share-quota'
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'Timer'
          type: 'timerTrigger'
          direction: 'in'
          schedule: '0 */15 * * * *'
        }
      ]
    }
    files: {
      'requirements.psd1': loadTextContent('../../artifacts/auto-increase-file-share/requirements.psd1')
      'run.ps1': loadTextContent('../../artifacts/auto-increase-file-share/run.ps1')
      '../profile.ps1': loadTextContent('../../artifacts/auto-increase-file-share/profile.ps1')
    }
  }
}

output functionAppName string = functionApp.name
output functionAppPrincipalId string = functionApp.identity.principalId
