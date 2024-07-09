param beginPeakTime string = '08:00'
param delegatedSubnetResourceId string
param endPeakTime string = '17:00'
param environmentAbbreviation string
param hostPoolName string
param hostPoolResourceGroupName string
param keyExpirationInDays int = 30
param limitSecondsToForceLogOffUser string = '0'
param location string = resourceGroup().location
param logAnalyticsWorkspaceResourceId string = ''
param minimumNumberOfRdsh string = '0'
param namingConvention object
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string = ''
param resourceAbbreviations object
param serviceToken string
param sessionHostsResourceGroupName string
param sessionThresholdPerCPU string = '1'
param subnetResourceId string
param tags object
param timeDifference string
param timestamp string = utcNow('yyyyMMddhhmmss')

var fileShareName = 'function-app'
var functionAppKeyword = environment().name == 'AzureCloud' || environment().name == 'AzureUSGovernment' ? 'azurewebsites' : 'appservice'
var privateLinkScopeResourceGroupName = empty(logAnalyticsWorkspaceResourceId) ? resourceGroup().name : split(privateLinkScopeResourceId, '/')[4]
var privateLinkScopeSubscriptionId = empty(logAnalyticsWorkspaceResourceId) ? subscription().subscriptionId : split(privateLinkScopeResourceId, '/')[2]
var roleAssignments = [
  hostPoolResourceGroupName
  sessionHostsResourceGroupName
]
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
  name: replace(namingConvention.userAssignedIdentityName, serviceToken, 'scale')
  location: location
  tags: contains(tags, 'Microsoft.ManagedIdentity/userAssignedIdentities')
    ? tags['Microsoft.ManagedIdentity/userAssignedIdentities']
    : {}
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentity.id, 'e147488a-f6f5-4113-8e2d-b22465e65bf6', resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6') // Key Vault Crypto Service Encryption User
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: replace(namingConvention.keyVaultName, serviceToken, 'scale')
  location: location
  tags: contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {}
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

resource privateEndpoint_vault 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: replace(namingConvention.keyVaultPrivateEndpoint, serviceToken, 'scale')
  location: location
  tags: contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}
  properties: {
    customNetworkInterfaceName: replace(namingConvention.keyVaultNetworkInterface, serviceToken, 'scale')
    privateLinkServiceConnections: [
      {
        name: replace(namingConvention.keyVaultPrivateEndpoint, serviceToken, 'scale')
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
  name: replace(namingConvention.storageAccountName, serviceToken, 'scale')
  location: location
  tags: contains(tags, 'Microsoft.Storage/storageAccounts') ? tags['Microsoft.Storage/storageAccounts'] : {}
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
    allowSharedKeyAccess: true
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
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: storageAccount
  name: 'default'
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {
        versions: 'SMB3.1.1;'
        authenticationMethods: 'NTLMv2;'
        channelEncryption: 'AES-128-GCM;AES-256-GCM;'
      }
    }
    shareDeleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  parent: fileServices
  name: fileShareName
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 5120
    enabledProtocols: 'SMB'
  }
}

resource privateEndpoints_storage 'Microsoft.Network/privateEndpoints@2023-04-01' = [
  for resource in storageSubResources: {
    name: replace(namingConvention.storageAccountPrivateEndpoint, '${serviceToken}-${resourceAbbreviations.storageAccounts}', '${resource}-${resourceAbbreviations.storageAccounts}-scale')
    location: location
    tags: contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}
    properties: {
      customNetworkInterfaceName: replace(namingConvention.storageAccountNetworkInterface, '${serviceToken}-${resourceAbbreviations.storageAccounts}', '${resource}-${resourceAbbreviations.storageAccounts}-scale')
      privateLinkServiceConnections: [
        {
          name: replace(namingConvention.storageAccountPrivateEndpoint, '${serviceToken}-${resourceAbbreviations.storageAccounts}', '${resource}-${resourceAbbreviations.storageAccounts}-scale')
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

resource diagnosticSetting_storage_blob 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' =
  if (!empty(logAnalyticsWorkspaceResourceId)) {
    scope: blobService
    name: replace(namingConvention.storageAccountDiagnosticSetting, '${serviceToken}-${resourceAbbreviations.storageAccounts}', 'blob-${resourceAbbreviations.storageAccounts}-scale')
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

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: replace(namingConvention.applicationInsightsName, serviceToken, 'scale')
  location: location
  tags: contains(tags, 'Microsoft.Insights/components') ? tags['Microsoft.Insights/components'] : {}
  properties: {
    Application_Type: 'web'
  }
  kind: 'web'
}

module privateLinkScope '../management/privateLinkScope.bicep' = {
  name: 'PrivateLinkScope_${timestamp}'
  scope: resourceGroup(privateLinkScopeSubscriptionId, privateLinkScopeResourceGroupName)
  params: {
    applicationInsightsName: applicationInsights.name
    applicationInsightsResourceId: applicationInsights.id
    privateLinkScopeResourceId: privateLinkScopeResourceId
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: replace(namingConvention.appServicePlanName, serviceToken, 'scale')
  location: location
  tags: contains(tags, 'Microsoft.Web/serverfarms') ? tags['Microsoft.Web/serverfarms'] : {}
  sku: {
    tier: 'ElasticPremium'
    name: 'EP1'
  }
  kind: 'functionapp'
  properties: {
    targetWorkerSizeId: 3
    targetWorkerCount: 1
    maximumElasticWorkerCount: 20
    zoneRedundant: false
  }
  dependsOn: [
    privateEndpoints_storage
    privateDnsZoneGroups_storage
  ]
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: replace(namingConvention.functionAppName, serviceToken, 'scale')
  location: location
  tags: contains(tags, 'Microsoft.Web/sites') ? tags['Microsoft.Web/sites'] : {}
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
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id,'2019-06-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id,'2019-06-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: fileShareName
        }
        {
          name: 'BeginPeakTime'
          value: beginPeakTime
        }
        {
          name: 'EndPeakTime'
          value: endPeakTime
        }
        {
          name: 'EnvironmentName'
          value: environment().name
        }
        {
          name: 'HostPoolName'
          value: hostPoolName
        }
        {
          name: 'HostPoolResourceGroupName'
          value: hostPoolResourceGroupName
        }
        {
          name: 'LimitSecondsToForceLogOffUser'
          value: limitSecondsToForceLogOffUser
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
          value: minimumNumberOfRdsh
        }
        {
          name: 'ResourceManagerUrl'
          // This workaround is needed because the environment().resourceManager value is missing the trailing slash for some Azure environments
          value: endsWith(environment().resourceManager, '/') ? environment().resourceManager : '${environment().resourceManager}/'
        }
        {
          name: 'SessionThresholdPerCPU'
          value: sessionThresholdPerCPU
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
      ]
      cors: {
        allowedOrigins: [
          environment().portal
        ]
      }
      ftpsState: 'FtpsOnly'
      netFrameworkVersion: 'v6.0'
      powerShellVersion: '7.2'
      use32BitWorkerProcess: false
    }
    virtualNetworkSubnetId: delegatedSubnetResourceId
    vnetContentShareEnabled: true
    vnetRouteAllEnabled: true
  }
}

resource privateEndpoint_functionApp 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: replace(namingConvention.functionAppPrivateEndpoint, serviceToken, 'scale')
  location: location
  properties: {
    customNetworkInterfaceName: replace(namingConvention.functionAppNetworkInterface, serviceToken, 'scale')
    privateLinkServiceConnections: [
      {
        name: replace(namingConvention.functionAppPrivateEndpoint, serviceToken, 'scale')
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

resource function 'Microsoft.Web/sites/functions@2020-12-01' = {
  parent: functionApp
  name: 'avd-scaling-tool'
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
      'requirements.psd1': loadTextContent('../../artifacts/scaling-tool/requirements.psd1')
      'run.ps1': loadTextContent('../../artifacts/scaling-tool/run.ps1')
      '../profile.ps1': loadTextContent('../../artifacts/scaling-tool/profile.ps1')
    }
  }
  dependsOn: [
    privateEndpoint_functionApp
    privateDnsZoneGroup_functionApp
  ]
}

// Gives the function app the "Desktop Virtualization Power On Off Contributor" role on the resource groups containing the hosts and host pool
module roleAssignments_ResourceGroups '../common/roleAssignment.bicep' = [
  for i in range(0, length(roleAssignments)): {
    name: 'RoleAssignment_${roleAssignments[i]}_${timestamp}'
    scope: resourceGroup(roleAssignments[i])
    params: {
      principalId: functionApp.identity.principalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: '40c5ff49-9181-41f8-ae61-143b0e78555e' // Desktop Virtualization Power On Off Contributor
    }
  }
]
