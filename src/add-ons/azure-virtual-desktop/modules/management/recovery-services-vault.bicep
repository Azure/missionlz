param azureBlobsPrivateDnsZoneResourceId string
param azureQueueStoragePrivateDnsZoneResourceId string
param deployFslogix bool
param hostPoolResourceId string
param location string
param mlzTags object
param recoveryServicesPrivateDnsZoneResourceId string
param recoveryServicesVaultName string
param recoveryServicesVaultNetworkInterfaceName string
param recoveryServicesVaultPrivateEndpointName string
param storageService string
param subnetId string
param tags object
param timeZone string

resource vault 'Microsoft.RecoveryServices/vaults@2022-03-01' = {
  name: recoveryServicesVaultName
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.RecoveryServices/vaults'] ?? {}, mlzTags)
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource backupPolicy_Storage 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-03-01' = if (deployFslogix && storageService == 'AzureFiles') {
  parent: vault
  name: 'AvdPolicyStorage'
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.RecoveryServices/vaults'] ?? {}, mlzTags)
  properties: {
    backupManagementType: 'AzureStorage'
    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '23:00'
      ]
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '23:00'
        ]
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
    }
    timeZone: timeZone
    workLoadType: 'AzureFileShare'
  }
}

resource backupPolicy_Vm 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-03-01' = if (!deployFslogix) {
  parent: vault
  name: 'AvdPolicyVm'
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.RecoveryServices/vaults'] ?? {}, mlzTags)
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 2
    policyType: 'V2'
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '23:00'
        ]
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
    }
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Daily'
      dailySchedule: {
        scheduleRunTimes: [
          '23:00'
        ]
      }
    }
    timeZone: timeZone
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: recoveryServicesVaultPrivateEndpointName
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
  properties: {
    customNetworkInterfaceName: recoveryServicesVaultNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: recoveryServicesVaultPrivateEndpointName
        properties: {
          privateLinkServiceId: vault.id
          groupIds: [
            'AzureBackup'
          ]
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: recoveryServicesVaultName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: replace(recoveryServicesPrivateDnsZoneResourceId, '.', '-')
        properties: {
          privateDnsZoneId: recoveryServicesPrivateDnsZoneResourceId
        }
      }
      {
        name: replace(azureQueueStoragePrivateDnsZoneResourceId, '.', '-')
        properties: {
          privateDnsZoneId: azureQueueStoragePrivateDnsZoneResourceId
        }
      }
      {
        name: replace(azureBlobsPrivateDnsZoneResourceId, '.', '-')
        properties: {
          privateDnsZoneId: azureBlobsPrivateDnsZoneResourceId
        }
      }
    ]
  }
  dependsOn: [
    vault
  ]
}

output name string = vault.name
